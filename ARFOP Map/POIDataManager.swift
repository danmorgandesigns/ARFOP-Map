//
//  POIDataManager.swift
//  arfop map
//
//  Created by Dan Morgan on 10/1/25.
//

import Foundation
import MapKit
import Combine
import SwiftUI

/// Manages loading and saving POI data from various sources
class POIDataManager: ObservableObject {
    @Published var pois: [ArboretumPOI] = []
    @Published var visibleCategories: Set<POICategory> = Set(POICategory.allCases)
    
    /// Returns POIs filtered by visible categories
    var filteredPOIs: [ArboretumPOI] {
        return pois.filter { visibleCategories.contains($0.category) }
    }
    
    /// Returns count of POIs in each category
    var categoryCounts: [POICategory: Int] {
        var counts: [POICategory: Int] = [:]
        for category in POICategory.allCases {
            counts[category] = pois.filter { $0.category == category }.count
        }
        return counts
    }
    
    /// Load POIs from a JSON file in the app bundle
    func loadPOIsFromBundle(filename: String = "arfop_pois") {
        // Load user preferences for visible categories
        loadVisibleCategories()
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Could not find \(filename).json in app bundle")
            loadSampleData()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let loadedPOIs = try decoder.decode([ArboretumPOIData].self, from: data)
            
            self.pois = loadedPOIs.map { poiData in
                ArboretumPOI(
                    name: poiData.name,
                    coordinate: CLLocationCoordinate2D(latitude: poiData.latitude, longitude: poiData.longitude),
                    category: POICategory(rawValue: poiData.category) ?? .restroom,
                    description: poiData.description,
                    imageURL: poiData.imageURL
                )
            }
        } catch {
            print("Error loading POIs from JSON: \(error)")
            loadSampleData()
        }
    }
    
    /// Load POIs from a CSV file
    func loadPOIsFromCSV(filename: String = "arfop_pois") {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "csv"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("Could not find \(filename).csv in app bundle")
            loadSampleData()
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        var loadedPOIs: [ArboretumPOI] = []
        
        // Skip header row
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            if columns.count >= 5 {
                let name = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let latitude = Double(columns[1].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                let longitude = Double(columns[2].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                let categoryString = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                let description = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                
                let poi = ArboretumPOI(
                    name: name,
                    coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    category: POICategory(rawValue: categoryString) ?? .restroom,
                    description: description,
                    imageURL: nil
                )
                
                loadedPOIs.append(poi)
            }
        }
        
        self.pois = loadedPOIs
    }
    
    /// Save POIs to UserDefaults (for user-added POIs)
    func savePOIsToUserDefaults() {
        let encoder = JSONEncoder()
        let poiData = pois.map { poi in
            ArboretumPOIData(
                name: poi.name,
                latitude: poi.coordinate.latitude,
                longitude: poi.coordinate.longitude,
                category: poi.category.rawValue,
                description: poi.description,
                imageURL: poi.imageURL
            )
        }
        
        if let encoded = try? encoder.encode(poiData) {
            UserDefaults.standard.set(encoded, forKey: "arfop_pois")
        }
    }
    
    /// Load POIs from UserDefaults
    func loadPOIsFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "arfop_pois") else {
            loadSampleData()
            return
        }
        
        let decoder = JSONDecoder()
        if let poiData = try? decoder.decode([ArboretumPOIData].self, from: data) {
            self.pois = poiData.map { data in
                ArboretumPOI(
                    name: data.name,
                    coordinate: CLLocationCoordinate2D(latitude: data.latitude, longitude: data.longitude),
                    category: POICategory(rawValue: data.category) ?? .restroom,
                    description: data.description,
                    imageURL: data.imageURL
                )
            }
        } else {
            loadSampleData()
        }
    }
    
    /// Add a new POI
    func addPOI(_ poi: ArboretumPOI) {
        pois.append(poi)
        savePOIsToUserDefaults()
    }
    
    /// Remove a POI
    func removePOI(withID id: UUID) {
        pois.removeAll { $0.id == id }
        savePOIsToUserDefaults()
    }
    
    /// Load sample data as fallback
    private func loadSampleData() {
        self.pois = [
            ArboretumPOI(
                name: "Giant Sequoia Grove",
                coordinate: CLLocationCoordinate2D(latitude: 38.8768757, longitude: -94.6729403),
                category: .tree,
                description: "Collection of magnificent giant sequoias, some over 100 years old.",
                imageURL: nil
            ),
            ArboretumPOI(
                name: "Rose Garden",
                coordinate: CLLocationCoordinate2D(latitude: 38.8778757, longitude: -94.6699403),
                category: .garden,
                description: "Beautiful rose garden with over 50 varieties in bloom from spring through fall.",
                imageURL: nil
            ),

            ArboretumPOI(
                name: "Visitor Center",
                coordinate: CLLocationCoordinate2D(latitude: 38.8758757, longitude: -94.6719403),
                category: .helpDesk,
                description: "Main visitor center with maps, gift shop, and restrooms.",
                imageURL: nil
            ),
            ArboretumPOI(
                name: "Greenhouse Complex",
                coordinate: CLLocationCoordinate2D(latitude: 38.8768757, longitude: -94.6699403),
                category: .building,
                description: "Research greenhouses featuring tropical plants and rare species.",
                imageURL: nil
            ),
            ArboretumPOI(
                name: "Abstract Garden Sculpture",
                coordinate: CLLocationCoordinate2D(latitude: 38.8748757, longitude: -94.6729403),
                category: .artInstallation,
                description: "Modern abstract sculpture surrounded by native plants.",
                imageURL: nil
            ),
            ArboretumPOI(
                name: "North Restroom Facility",
                coordinate: CLLocationCoordinate2D(latitude: 38.8788757, longitude: -94.6709403),
                category: .restroom,
                description: "Clean, accessible restroom facility with baby changing station.",
                imageURL: nil
            )
        ]
    }
    
    // MARK: - Category Filtering Methods
    
    /// Toggle visibility of a specific category
    func toggleCategory(_ category: POICategory) {
        if visibleCategories.contains(category) {
            visibleCategories.remove(category)
        } else {
            visibleCategories.insert(category)
        }
        saveVisibleCategories()
    }
    
    /// Show all categories
    func showAllCategories() {
        visibleCategories = Set(POICategory.allCases)
        saveVisibleCategories()
    }
    
    /// Hide all categories
    func hideAllCategories() {
        visibleCategories.removeAll()
        saveVisibleCategories()
    }
    
    /// Check if a category is visible
    func isCategoryVisible(_ category: POICategory) -> Bool {
        return visibleCategories.contains(category)
    }
    
    /// Save visible categories to UserDefaults
    private func saveVisibleCategories() {
        let categoryNames = visibleCategories.map { $0.rawValue }
        UserDefaults.standard.set(categoryNames, forKey: "visible_poi_categories")
    }
    
    /// Load visible categories from UserDefaults
    private func loadVisibleCategories() {
        guard let savedCategories = UserDefaults.standard.array(forKey: "visible_poi_categories") as? [String] else {
            // If no saved preferences, show all categories by default
            visibleCategories = Set(POICategory.allCases)
            return
        }
        
        visibleCategories = Set(savedCategories.compactMap { POICategory(rawValue: $0) })
        
        // Ensure we have at least some categories visible
        if visibleCategories.isEmpty {
            visibleCategories = Set(POICategory.allCases)
        }
    }
}

/// Codable version of POI for JSON serialization
struct ArboretumPOIData: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let category: String
    let description: String
    let imageURL: String?
}
