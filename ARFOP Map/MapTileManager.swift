//
//  MapTileManager.swift
//  ARFOP Map
//
//  Created by Dan Morgan on 10/17/25.
//

import Foundation
import MapKit
import Combine

@MainActor
class MapTileManager: ObservableObject {
    @Published var isCaching = false
    @Published var cachingProgress: Double = 0.0
    @Published var cachedRegions: Set<String> = []
    
    private let tileCache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Configuration
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let maxZoomLevel = 16
    private let minZoomLevel = 13
    
    init() {
        // Set up cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("MapTileCache")
        
        setupCache()
        loadCachedRegions()
    }
    
    private func setupCache() {
        // Configure in-memory cache
        tileCache.countLimit = 1000 // Limit number of tiles in memory
        tileCache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Public Methods
    
    func prefetchTilesForRegions(_ regions: [MKCoordinateRegion]) {
        guard !isCaching else {
            print("🗂️ Already caching tiles, skipping new request")
            return
        }
        
        Task {
            await prefetchTiles(for: regions)
        }
    }
    
    func prefetchTilesForPOIs(_ pois: [ArboretumPOI]) {
        let regions = pois.map { poi in
            MKCoordinateRegion(
                center: poi.coordinate,
                latitudinalMeters: 500, // 500m radius around each POI
                longitudinalMeters: 500
            )
        }
        prefetchTilesForRegions(regions)
    }
    
    func clearCache() {
        tileCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        cachedRegions.removeAll()
        saveCachedRegions()
        print("🗂️ Cache cleared")
    }
    
    func getCacheSize() -> String {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 MB"
        }
        
        let totalSize = contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
        
        return ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
    
    // MARK: - Private Methods
    
    private func prefetchTiles(for regions: [MKCoordinateRegion]) async {
        isCaching = true
        cachingProgress = 0.0
        
        var allTileCoords: [(x: Int, y: Int, z: Int)] = []
        
        // Calculate all tile coordinates for all regions and zoom levels
        for region in regions {
            for zoomLevel in minZoomLevel...maxZoomLevel {
                let tiles = calculateTileCoordinates(for: region, zoomLevel: zoomLevel)
                allTileCoords.append(contentsOf: tiles)
            }
        }
        
        print("🗂️ Starting to cache \(allTileCoords.count) tiles")
        
        // Download tiles with progress tracking
        for (index, tileCoord) in allTileCoords.enumerated() {
            await downloadAndCacheTile(x: tileCoord.x, y: tileCoord.y, z: tileCoord.z)
            
            // Update progress
            cachingProgress = Double(index + 1) / Double(allTileCoords.count)
            
            // Small delay to prevent overwhelming the server
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        }
        
        // Mark regions as cached
        for region in regions {
            let regionId = regionIdentifier(for: region)
            cachedRegions.insert(regionId)
        }
        saveCachedRegions()
        
        isCaching = false
        print("🗂️ Finished caching tiles")
    }
    
    private func calculateTileCoordinates(for region: MKCoordinateRegion, zoomLevel: Int) -> [(x: Int, y: Int, z: Int)] {
        let north = region.center.latitude + region.span.latitudeDelta / 2
        let south = region.center.latitude - region.span.latitudeDelta / 2
        let east = region.center.longitude + region.span.longitudeDelta / 2
        let west = region.center.longitude - region.span.longitudeDelta / 2
        
        let minX = Int(floor((west + 180.0) / 360.0 * pow(2.0, Double(zoomLevel))))
        let maxX = Int(floor((east + 180.0) / 360.0 * pow(2.0, Double(zoomLevel))))
        let minY = Int(floor((1.0 - log(tan(north * .pi / 180.0) + 1.0 / cos(north * .pi / 180.0)) / .pi) / 2.0 * pow(2.0, Double(zoomLevel))))
        let maxY = Int(floor((1.0 - log(tan(south * .pi / 180.0) + 1.0 / cos(south * .pi / 180.0)) / .pi) / 2.0 * pow(2.0, Double(zoomLevel))))
        
        var tiles: [(x: Int, y: Int, z: Int)] = []
        for x in minX...maxX {
            for y in minY...maxY {
                tiles.append((x: x, y: y, z: zoomLevel))
            }
        }
        
        return tiles
    }
    
    private func downloadAndCacheTile(x: Int, y: Int, z: Int) async {
        let tileKey = "\(z)_\(x)_\(y)"
        let cacheKey = NSString(string: tileKey)
        
        // Check if already in memory cache
        if tileCache.object(forKey: cacheKey) != nil {
            return
        }
        
        // Check if already in disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(tileKey).png")
        if fileManager.fileExists(atPath: fileURL.path) {
            // Load into memory cache
            if let data = try? Data(contentsOf: fileURL) {
                tileCache.setObject(NSData(data: data), forKey: cacheKey)
            }
            return
        }
        
        // Download tile (Note: This is a simplified example - you'd need to use actual tile server URLs)
        // For Apple Maps satellite tiles, you'd need to use MKTileOverlay or similar
        // This is a conceptual implementation
        guard let url = URL(string: "https://example-tile-server.com/\(z)/\(x)/\(y).png") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Cache in memory
            tileCache.setObject(NSData(data: data), forKey: cacheKey)
            
            // Cache on disk
            try data.write(to: fileURL)
            
        } catch {
            print("🗂️ Failed to download tile \(tileKey): \(error)")
        }
    }
    
    private func regionIdentifier(for region: MKCoordinateRegion) -> String {
        return "\(region.center.latitude)_\(region.center.longitude)_\(region.span.latitudeDelta)_\(region.span.longitudeDelta)"
    }
    
    private func loadCachedRegions() {
        if let data = UserDefaults.standard.data(forKey: "cachedMapRegions"),
           let regions = try? JSONDecoder().decode(Set<String>.self, from: data) {
            cachedRegions = regions
        }
    }
    
    private func saveCachedRegions() {
        if let data = try? JSONEncoder().encode(cachedRegions) {
            UserDefaults.standard.set(data, forKey: "cachedMapRegions")
        }
    }
}
