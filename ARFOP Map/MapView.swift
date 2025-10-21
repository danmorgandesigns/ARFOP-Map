//
//  MapView.swift
//  afrop map
//
//  Created by Dan Morgan on 9/30/25.
//

import SwiftUI
import MapKit
import Combine
import Network

// MARK: - POI Data Models
/// Represents a Point of Interest in the arboretum
struct ArboretumPOI: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: POICategory
    let description: String
    let imageURL: String?
    
    // Make CLLocationCoordinate2D hashable for SwiftUI
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ArboretumPOI, rhs: ArboretumPOI) -> Bool {
        lhs.id == rhs.id
    }
}

/// Categories for different types of POIs
enum POICategory: String, CaseIterable {
    case animals = "Animals"
    case artInstallation = "Art Installation"
    case building = "Building"
    case garden = "Garden"
    case helpDesk = "Help Desk"
    case playground = "Playground"
    case poi = "POI"
    case restroom = "Restroom"
    case shop = "Shop"
    case seat = "Seat"
    case tree = "Tree"
    
    /// SF Symbol for each category
    var iconName: String {
        switch self {
        case .animals: return "pawprint"
        case .artInstallation: return "photo.artframe"
        case .building: return "house"
        case .garden: return "leaf"
        case .helpDesk: return "questionmark.circle"
        case .playground: return "figure.play"
        case .poi: return "info.circle"
        case .restroom: return "toilet"
        case .seat: return "chair.lounge"
        case .shop: return "storefront"
        case .tree: return "tree"


        }
    }
    
    /// Color for each category
    var color: Color {
        switch self {
        case .animals: return .black
        case .artInstallation: return .purple
        case .building: return .gray
        case .garden: return .mint
        case .helpDesk: return .blue
        case .playground: return .cyan
        case .poi: return .blue
        case .restroom: return .red
        case .seat: return .orange
        case .shop: return .indigo
        case .tree: return .green
            
        }
    }
}
// MARK: - Trail Models
struct TrailRoute: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let info: String?
    let imageURL: String?
    let coordinates: [CLLocationCoordinate2D]
    let color: Color
}

/// MapView wraps MapKit's Map component and handles map-specific UI logic
/// This separation allows us to keep map functionality isolated and easily extensible
struct MapView: View {
    // Optional initial region to focus the map when presented
    let initialRegion: MKCoordinateRegion?
    
    // MARK: - Properties

    @StateObject private var connectivityManager = ConnectivityManager()

    @StateObject private var tileManager = MapTileManager()
    @StateObject private var networkStatus = NetworkStatus.shared

    @State private var showCachingProgress = false
    @State private var showConnectivityBanner: Bool = false
    @State private var connectivityBannerKind: OfflineBannerView.Kind = .constrained
    @State private var lastConnectivityChange: Date = .distantPast

    // DEBUG: Toggle to show a small on-screen HUD of connectivity state.
    // Set to false to hide the HUD. Wrapped in #if DEBUG for safety.
    #if DEBUG
    @State private var showDebugConnectivityHUD: Bool = true
    #endif
    
    
    /// Location manager provides current location and handles permissions
    @StateObject private var locationManager = LocationManager()
    
    /// POI data manager handles loading and managing points of interest
    @StateObject private var poiManager = POIDataManager()
    
    /// Camera position for the map - this controls what area is visible
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    /// Current map style - cycles between satellite and standard views
    @State private var mapStyle: MapStyle = MapStyle.imagery(elevation: .realistic)
    
    /// Track current map style index for cycling through options
    @State private var currentStyleIndex: Int = 0
    
    /// Available map styles to cycle through
    private let mapStyles: [MapStyle] = [
        .imagery(elevation: .realistic),
        .standard(elevation: .realistic)
    ]
    
    /// Style names for accessibility and debugging
    private let styleNames = ["Satellite", "Standard"]

    @State private var trailRoutes: [TrailRoute] = []
    
    /// Controls whether to show trail routes on the map
    @State private var showTrailRoutes = true
    
    /// Controls whether to show the user's location on the map
    @State private var showUserLocation = false
    
    /// Controls whether the category filter modal is shown
    @State private var showCategoryFilter = false

    // MARK: - Body
    var body: some View {
        ZStack {
            mapView
            errorOverlay
            locationPermissionOverlay
            
            #if DEBUG
            if showDebugConnectivityHUD {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: debugConnectivityIcon(for: networkStatus.state))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(debugConnectivityColor(for: networkStatus.state))
                            .frame(width: 28, height: 28)
                            .background(.regularMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .accessibilityHidden(true)
                    }
                    .padding([.bottom, .trailing], 10)
                }
                .transition(.opacity)
            }
            #endif
            
            // Connectivity banner
            if showConnectivityBanner {
                VStack {
                    HStack {
                        Spacer()
                        OfflineBannerView(kind: connectivityBannerKind)
                            .padding(.top, 8)
                        Spacer()
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
            
            // Add the caching progress overlay here
            if tileManager.isCaching {
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Caching map tiles...")
                                .font(.caption)
                            Spacer()
                        }
                        
                        ProgressView(value: tileManager.cachingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(8)
                    .padding()
                }
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarItems
        }
        .sheet(isPresented: $showCategoryFilter) {
            CategoryFilterView(poiManager: poiManager, showTrailRoutes: $showTrailRoutes, trailCount: trailRoutes.count)
        }
        .onChange(of: showTrailRoutes) { _, _ in
            saveTrailVisibilityPreference()
        }
        .onReceive(networkStatus.$state.removeDuplicates()) { newState in
            handleConnectivityChange(newState)
        }
    }
    
    // MARK: - Map View Components
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Show user location only if toggle is enabled
            if showUserLocation, let location = locationManager.currentLocation {
                Annotation("Your Location", coordinate: location.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            // Show all POIs
            ForEach(poiManager.filteredPOIs) { poi in
                Annotation("", coordinate: poi.coordinate) {
                    POIAnnotationView(poi: poi)
                }
            }
            
            // Show trail routes with customizable colors (only if enabled)
            if showTrailRoutes {
                ForEach(trailRoutes) { trail in
                    MapPolyline(coordinates: trail.coordinates)
                        .stroke(trail.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }

                // Show trail name labels at multiple points (skip segments)
                ForEach(trailRoutes.filter { !$0.name.contains("Segment") }) { trail in
                    ForEach(getTrailLabelPositions(trail), id: \.latitude) { coordinate in
                        Annotation("", coordinate: coordinate) {
                            TrailLabelView(trail: trail)
                        }
                    }
                }
            }
        }
        .mapStyle(mapStyle)
        .onAppear {
            setupMapData()
            if let region = initialRegion {
                withAnimation(.easeInOut(duration: 1.0)) {
                    cameraPosition = .region(region)
                }
            }
        }
    }
    
    @ViewBuilder
    private var errorOverlay: some View {
        if let errorMessage = locationManager.errorMessage {
            VStack {
                Spacer()
                errorMessageView(errorMessage)
            }
        }
    }
    
    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
        .padding()
    }
    
    @ViewBuilder
    private var locationPermissionOverlay: some View {
        if locationManager.authorizationStatus == .notDetermined {
            VStack {
                Spacer()
                locationPermissionView
                Spacer()
            }
        }
    }
    
    private var locationPermissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Location Access")
                .font(.headline)
            
            Text("This app needs location access to show your position on the map.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Enable Location") {
                locationManager.requestLocationPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding()
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                toggleMapStyle()
            } label: {
                Image(systemName: getMapStyleIcon())
            }
            .accessibilityLabel("Switch to \(getNextStyleName()) map")
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showCategoryFilter = true
            } label: {
                Image(systemName: "square.3.layers.3d")
            }
            .accessibilityLabel("Filter POI categories")
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                toggleUserLocation()
            } label: {
                Image(systemName: showUserLocation ? "location.fill" : "location")
            }
            .disabled(locationManager.currentLocation == nil)
            .accessibilityLabel(showUserLocation ? "Hide user location" : "Show user location")
        }
    }
    
    private func setupMapData() {
        // Load trail visibility preference
        loadTrailVisibilityPreference()
        // Request location permission when map appears
        locationManager.requestLocationPermission()
        // Load POI data
        poiManager.loadPOIsFromBundle() // Load from JSON/JS file
 
        // Start intelligent caching when we have good connectivity
        if connectivityManager.hasStrongConnection {
            startOpportunisticCaching()
        }
        
        
        // Load trails with a small delay to prevent simultaneous operations
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            await MainActor.run {
                loadTrailRoutes()
            }
        }
    }
    
    // MARK: - Helper Methods
    /// Centers the map camera on the specified location with appropriate zoom level
    private func centerMapOnLocation(_ location: CLLocation) {
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 1000, // 1km zoom level
                    longitudinalMeters: 1000
                )
            )
        }
    }

    private func startOpportunisticCaching() {
        // Cache tiles for your key regions when connectivity is good
        let keyRegions = [
            MKCoordinateRegion(center: MapConstants.arboretumCenter, latitudinalMeters: 1000, longitudinalMeters: 1000),
            MKCoordinateRegion(center: MapConstants.farmCenter, latitudinalMeters: 800, longitudinalMeters: 800),
            MKCoordinateRegion(center: MapConstants.artsCenter, latitudinalMeters: 2000, longitudinalMeters: 2000)
        ]
        
        tileManager.prefetchTilesForRegions(keyRegions)
    }
    
    
    /// Centers the map camera on the specified coordinate with appropriate zoom level
    private func centerMapOnCoordinate(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
            )
        }
    }
    
    /// Cycles between satellite and standard map styles
    private func toggleMapStyle() {
        // Check connectivity before switching to satellite
        if currentStyleIndex == 0 && !connectivityManager.hasStrongConnection {
            // Show alert about satellite requiring internet
            showConnectivityAlert()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStyleIndex = (currentStyleIndex + 1) % mapStyles.count
            mapStyle = mapStyles[currentStyleIndex]
        }
    }
    
    // Add connectivity alert method
    private func showConnectivityAlert() {
        // You can implement this as an alert or banner
        print("⚠️ Satellite imagery requires internet connection")
    }
    
    
    /// Toggles user location visibility and optionally centers the map
    private func toggleUserLocation() {
        showUserLocation.toggle()
        
        // If turning on user location, center the map on the user's location
        if showUserLocation, let location = locationManager.currentLocation {
            centerMapOnLocation(location)
        }
    }
    
    /// Returns the appropriate SF Symbol for the current map style
    private func getMapStyleIcon() -> String {
        switch currentStyleIndex {
        case 0: return "globe"        // Satellite imagery
        case 1: return "map"          // Standard map
        default: return "globe"
        }
    }
    
    /// Returns the name of the next map style for accessibility
    private func getNextStyleName() -> String {
        let nextIndex = (currentStyleIndex + 1) % styleNames.count
        return styleNames[nextIndex]
    }
    
    /// Load trail routes from GeoJSON files
    private func loadTrailRoutes() {
        print("🗺️ Starting trail route loading process...")
        
        // Clear existing trails
        trailRoutes.removeAll()
        
        // List of trail files to load
        let trailFiles = ["Rocky Ridge", "Whitetail Pass", "Karens Path", "Bluff Loop", "West Trail", "Cottonwood Trail", "Sculpture Garden Loop", "Prairie Loop", "Enchanted Forest Loop", "Lower Meadow", "Legacy Garden Path", "Marder Garden Path", "Ancillary Paths" ]
        
        for trailFile in trailFiles {
            let trails = parseGeoJSON(filename: trailFile)
            trailRoutes.append(contentsOf: trails)
            print("🗺️ Added \(trails.count) segment(s) from: \(trailFile)")
        }
        
        if trailRoutes.isEmpty {
            print("⚠️ No trails were loaded successfully")
        } else {
            print("✅ Successfully loaded \(trailRoutes.count) total trail segment(s)")
            MitigationLogger.log(.overlaysLoaded)
        }
    }

    /// Returns the first non-empty string value for any of the given keys
    private func firstNonEmptyString(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return nil
    }

    /// Attempts to parse a color from common property keys and hex values
    private func parseColorStringFlexible(_ dict: [String: Any]) -> Color? {
        // Try common color keys
        let possibleKeys = ["color", "stroke", "strokeColor", "lineColor", "styleColor", "style"]
        if let colorString = firstNonEmptyString(in: dict, keys: possibleKeys) {
            return parseTrailColor(colorString)
        }
        return nil
    }

    /// Parse GeoJSON file into TrailRoute(s) - now returns array
    private func parseGeoJSON(filename: String) -> [TrailRoute] {
        print("🗺️ Attempting to parse GeoJSON for: \(filename)")

        // Try both .geojson and .js extensions
        var url: URL?
        if let geojsonURL = Bundle.main.url(forResource: filename, withExtension: "geojson") {
            url = geojsonURL
            print("🗺️ Found .geojson file")
        } else if let jsURL = Bundle.main.url(forResource: filename, withExtension: "js") {
            url = jsURL
            print("🗺️ Found .js file")
        }

        guard let fileURL = url else {
            print("❌ Could not find \(filename).geojson or \(filename).js")
            return []
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            print("❌ Could not read data from file")
            return []
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Could not parse JSON")
            return []
        }

        guard let features = json["features"] as? [[String: Any]], !features.isEmpty else {
            print("❌ Invalid GeoJSON structure: missing or empty features")
            return []
        }

        var allTrails: [TrailRoute] = []

        for (featureIndex, feature) in features.enumerated() {
            guard let geometry = feature["geometry"] as? [String: Any],
                  let geometryType = geometry["type"] as? String else {
                print("⚠️ Feature #\(featureIndex) missing geometry/type; skipping")
                continue
            }

            let properties = feature["properties"] as? [String: Any] ?? [:]

            // Flexible metadata extraction
            let derivedName = firstNonEmptyString(in: properties, keys: ["name", "Name", "title", "Title", "id"]) ?? filename
            let derivedDesc = firstNonEmptyString(in: properties, keys: ["desc", "description", "Description", "notes", "summary"]) ?? "Trail route"
            let derivedColor: Color = parseColorStringFlexible(properties) ?? .orange

            print("🗺️ Processing feature #\(featureIndex) geometry type: \(geometryType) — name: \(derivedName)")

            switch geometryType {
            case "LineString":
                if let coords = geometry["coordinates"] as? [[Double]] {
                    var segmentCoordinates: [CLLocationCoordinate2D] = []
                    for point in coords {
                        if point.count >= 2 {
                            let coordinate = CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
                            segmentCoordinates.append(coordinate)
                        }
                    }
                    if !segmentCoordinates.isEmpty {
                        allTrails.append(TrailRoute(
                            name: derivedName,
                            description: derivedDesc,
                            info: firstNonEmptyString(in: properties, keys: ["info", "Info", "details"]),
                            imageURL: firstNonEmptyString(in: properties, keys: ["imageURL", "imageUrl", "image", "thumbnail"]),
                            coordinates: segmentCoordinates,
                            color: derivedColor
                        ))
                    }
                }

            case "MultiLineString":
                if let multiCoords = geometry["coordinates"] as? [[[Double]]] {
                    print("🗺️ Processing MultiLineString with \(multiCoords.count) segments")
                    for lineString in multiCoords {
                        var segmentCoordinates: [CLLocationCoordinate2D] = []
                        for point in lineString {
                            if point.count >= 2 {
                                let coordinate = CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
                                segmentCoordinates.append(coordinate)
                            }
                        }
                        if !segmentCoordinates.isEmpty {
                            allTrails.append(TrailRoute(
                                name: derivedName,
                                description: derivedDesc,
                                info: firstNonEmptyString(in: properties, keys: ["info", "Info", "details"]),
                                imageURL: firstNonEmptyString(in: properties, keys: ["imageURL", "imageUrl", "image", "thumbnail"]),
                                coordinates: segmentCoordinates,
                                color: derivedColor
                            ))
                        }
                    }
                }

            default:
                print("❌ Unsupported geometry type: \(geometryType) — skipping feature #\(featureIndex)")
            }
        }

        if allTrails.isEmpty {
            print("⚠️ No trails were loaded successfully from \(filename)")
        } else {
            print("✅ Successfully loaded \(allTrails.count) trail segment(s) from \(filename)")
        }

        return allTrails
    }
    
    /// Convert color string (named or hex) to SwiftUI Color
    private func parseTrailColor(_ colorString: String) -> Color {
        let lower = colorString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Hex support: #RRGGBB or #RRGGBBAA
        if lower.hasPrefix("#") {
            let hex = String(lower.dropFirst())
            func colorFromHex(_ hex: String) -> Color? {
                var hexValue = hex
                if hexValue.count == 6 || hexValue.count == 8 {
                    var int: UInt64 = 0
                    guard Scanner(string: hexValue).scanHexInt64(&int) else { return nil }
                    let r, g, b, a: Double
                    if hexValue.count == 6 {
                        r = Double((int >> 16) & 0xFF) / 255.0
                        g = Double((int >> 8) & 0xFF) / 255.0
                        b = Double(int & 0xFF) / 255.0
                        a = 1.0
                    } else { // 8
                        r = Double((int >> 24) & 0xFF) / 255.0
                        g = Double((int >> 16) & 0xFF) / 255.0
                        b = Double((int >> 8) & 0xFF) / 255.0
                        a = Double(int & 0xFF) / 255.0
                    }
                    return Color(red: r, green: g, blue: b, opacity: a)
                }
                return nil
            }
            if let c = colorFromHex(hex) { return c }
            print("⚠️ Unknown hex color '\(colorString)', defaulting to orange")
            return .orange
        }

        switch lower {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "yellow": return .yellow
        case "pink": return .pink
        case "cyan": return .cyan
        case "mint": return .mint
        case "indigo": return .indigo
        case "teal": return .teal
        case "brown": return .brown
        case "gray", "grey": return .gray
        case "black": return .black
        case "white": return .white
        default:
            print("⚠️ Unknown color '\(colorString)', defaulting to orange")
            return .orange
        }
    }
    
    /// Get multiple label positions along a trail (at 12.5% 50% and 75% of trail length)
    private func getTrailLabelPositions(_ trail: TrailRoute) -> [CLLocationCoordinate2D] {
        guard !trail.coordinates.isEmpty else { return [] }
        
        let coordinates = trail.coordinates
        let count = coordinates.count
        
        // For very short trails, no labels
        if count < 30 {
            return []
        }
        
        // For short trails, just use one label at the middle
        if count < 150 {
            let midIndex = count / 2
            return [coordinates[midIndex]]
        }
        
        // Calculate positions at 12.5%, 50%, and 75% of trail length
        let firstIndex = count / 8           // 12.5%
        let secondIndex = count / 2          // 50%
        let thirdIndex = (count * 3) / 4     // 75%
        
        return [coordinates[firstIndex], coordinates[secondIndex], coordinates[thirdIndex]]
    }
    
    /// Load trail visibility preference from UserDefaults
    private func loadTrailVisibilityPreference() {
        showTrailRoutes = UserDefaults.standard.object(forKey: "show_trail_routes") as? Bool ?? true
    }
    
    /// Save trail visibility preference to UserDefaults
    private func saveTrailVisibilityPreference() {
        UserDefaults.standard.set(showTrailRoutes, forKey: "show_trail_routes")
    }
    
    private func handleConnectivityChange(_ state: NetworkStatus.State) {
        let now = Date()
        // Debounce rapid changes
        if now.timeIntervalSince(lastConnectivityChange) < 1.0 { return }
        lastConnectivityChange = now

        switch state {
        case .online:
            // Hide banner when back online
            withAnimation { showConnectivityBanner = false }
        case .constrained:
            // Switch to lighter style if currently satellite
            if currentStyleIndex == 0 { // satellite index
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStyleIndex = 1
                    mapStyle = mapStyles[currentStyleIndex]
                }
                MitigationLogger.log(.switchedToLightStyle)
            }
            connectivityBannerKind = .constrained
            withAnimation { showConnectivityBanner = true }
            MitigationLogger.log(.constrainedBannerShown)
        case .offline:
            // Switch to lighter style if currently satellite
            if currentStyleIndex == 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStyleIndex = 1
                    mapStyle = mapStyles[currentStyleIndex]
                }
                MitigationLogger.log(.switchedToLightStyle)
            }
            connectivityBannerKind = .offline
            withAnimation { showConnectivityBanner = true }
            MitigationLogger.log(.offlineBannerShown)
        }
    }

    #if DEBUG
    private func debugConnectivityText(for state: NetworkStatus.State) -> String {
        switch state {
        case .online: return "Connected"
        case .constrained: return "Limited"
        case .offline: return "Unavailable"
        }
    }
    
    private func debugConnectivityIcon(for state: NetworkStatus.State) -> String {
        switch state {
        case .online: return "network"
        case .constrained: return "network"
        case .offline: return "network.slash"
        }
    }
    
    private func debugConnectivityColor(for state: NetworkStatus.State) -> Color {
        switch state {
        case .online: return .green
        case .constrained: return .orange
        case .offline: return .red
        }
    }
    #endif
}

// MARK: - POI Annotation View
/// Custom view for displaying POI annotations on the map
struct POIAnnotationView: View {
    let poi: ArboretumPOI
    @State private var showDetails = false
    
    var body: some View {
        Button(action: {
            showDetails = true
        }) {
            VStack(spacing: 2) {
                // Icon
                ZStack {
                    Circle()
                        .fill(poi.category.color)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: poi.category.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .bold))
                }
                
                // Label
                Text(poi.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
            }
        }
        .sheet(isPresented: $showDetails) {
            POIDetailView(poi: poi)
        }
    }
}

// MARK: - POI Detail View
/// Detailed view shown when a POI is tapped
struct POIDetailView: View {
    let poi: ArboretumPOI
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(poi.category.color)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: poi.category.iconName)
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold))
                            }
                            
                            VStack(alignment: .leading) {
                                Text(poi.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(poi.category.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        if let urlString = poi.imageURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.1))
                                        ProgressView()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(maxHeight: proxy.size.height * 0.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit() // show entire image (no cropping)
                                        .frame(maxWidth: .infinity)
                                        .frame(maxHeight: proxy.size.height * 0.5)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                case .failure:
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo")
                                        Text("Unable to load image")
                                    }
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(maxHeight: proxy.size.height * 0.5)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        
                        // Description
                        Text("Description")
                            .font(.headline)
                        
                        Text(poi.description)
                            .font(.body)
                        
                        // Coordinates (for reference)
                        Text("Location")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Lat: \(poi.coordinate.latitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Lon: \(poi.coordinate.longitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer(minLength: 0)
                    }
                    .padding()
                }
                .navigationTitle("POI Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
        }
    }
}

// MARK: - Trail Detail View
/// Detailed view shown when a trail label is tapped
struct TrailDetailView: View {
    let trail: TrailRoute
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.brown)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "figure.hiking")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold))
                            }
                            
                            VStack(alignment: .leading) {
                                Text(trail.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Trail Route")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Image (mirrors POI sizing)
                        if let urlString = trail.imageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.1))
                                        ProgressView()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(maxHeight: proxy.size.height * 0.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(maxHeight: proxy.size.height * 0.5)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                case .failure:
                                    EmptyView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        
                        // Description
                        Text("Description")
                            .font(.headline)
                        
                        Text(trail.description)
                            .font(.body)
                        
                        // Trail Information
                        Text("Trail Information")
                            .font(.headline)
                        
                        if let info = trail.info, !info.isEmpty {
                            Text(info)
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Points: \(trail.coordinates.count)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Text("Color: \(trail.color.description)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding()
                }
            }
            .navigationTitle("Trail Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

// MARK: - Trail Label View
/// Custom view for displaying trail names as text overlays on the map
struct TrailLabelView: View {
    let trail: TrailRoute
    @State private var showDetails = false
    
    var body: some View {
        Button(action: {
            showDetails = true
        }) {
            VStack(spacing: 2) {
                // Trail icon
                ZStack {
                    Circle()
                        .fill(Color.brown)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "figure.hiking")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .bold))
                }
                
                // Trail name label
                Text(trail.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
            }
        }
        .buttonStyle(.plain) // Remove default button styling
        .sheet(isPresented: $showDetails) {
            TrailDetailView(trail: trail)
        }
    }
}

// MARK: - Category Filter View
/// Modal view for filtering POI categories
struct CategoryFilterView: View {
    @ObservedObject var poiManager: POIDataManager
    @Binding var showTrailRoutes: Bool
    let trailCount: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: quickActionsHeader) { }
                
                Section("Categories") {
                    ForEach(POICategory.allCases, id: \.self) { category in
                        CategoryFilterRow(
                            category: category,
                            isVisible: poiManager.isCategoryVisible(category),
                            count: poiManager.categoryCounts[category] ?? 0
                        ) {
                            poiManager.toggleCategory(category)
                        }
                    }
                }
                
                // Trail routes section
                Section("Trail Routes") {
                    TrailFilterRow(
                        isVisible: showTrailRoutes,
                        count: trailCount
                    ) {
                        showTrailRoutes.toggle()
                    }
                }
                
                Section(footer: footerText) {
                    // Empty section for footer text only
                }
            }
            .navigationTitle("Choose Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
    
    private var footerText: some View {
        Text("Showing \(poiManager.filteredPOIs.count) of \(poiManager.pois.count) POIs")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var quickActionsHeader: some View {
        HStack {
            Button("Show All") {
                poiManager.showAllCategories()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Hide All") {
                poiManager.hideAllCategories()
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 0)
    }
}

// MARK: - Category Filter Row
/// Individual row in the category filter list
struct CategoryFilterRow: View {
    let category: POICategory
    let isVisible: Bool
    let count: Int
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Category icon
                ZStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: category.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
                
                // Category name and count
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text("\(count) \(count == 1 ? "item" : "items")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Toggle indicator
                Image(systemName: isVisible ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isVisible ? .blue : .gray)
                    .font(.title2)
            }
            .contentShape(Rectangle()) // Make entire row tappable
        }
        .buttonStyle(.plain) // Remove default button styling
    }
}

// MARK: - Trail Filter Row
/// Row for toggling trail route visibility
struct TrailFilterRow: View {
    let isVisible: Bool
    let count: Int
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Trail icon
                ZStack {
                    Circle()
                        .fill(Color.brown)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "figure.hiking")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
                
                // Trail name and count
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trail Routes")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text("\(count) \(count == 1 ? "trail" : "trails")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Toggle indicator
                Image(systemName: isVisible ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isVisible ? .blue : .gray)
                    .font(.title2)
            }
            .contentShape(Rectangle()) // Make entire row tappable
        }
        .buttonStyle(.plain) // Remove default button styling
    }
}

