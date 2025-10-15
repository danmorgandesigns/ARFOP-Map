//
//  LocationManager.swift
//  arfop map
//
//  Created by Dan Morgan on 9/30/25.
//

import Foundation
import CoreLocation
import Combine

/// LocationManager handles all location-related functionality including permissions and location updates
/// This ObservableObject allows SwiftUI views to reactively update when location data changes
@MainActor
class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    /// Current location of the user - published so SwiftUI views can react to changes
    @Published var currentLocation: CLLocation?
    
    /// Location authorization status - published so UI can react to permission changes
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Error message for displaying location-related errors to the user
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    /// Core Location manager instance
    private let locationManager = CLLocationManager()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup Methods
    /// Configure the location manager with appropriate settings
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Only update when user moves 10+ meters
        
        // Set initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    /// Request location permissions from the user
    /// This should be called when the user first interacts with location features
    func requestLocationPermission() {
        print("🔍 LocationManager: Requesting permission. Current status: \(authorizationStatus.rawValue)")
        
        switch authorizationStatus {
        case .notDetermined:
            print("🔍 LocationManager: Requesting authorization...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("🔍 LocationManager: Permission denied or restricted")
            // Guide user to settings if previously denied
            errorMessage = "Location access denied. Please enable location services in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            print("🔍 LocationManager: Permission already granted, starting updates")
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    /// Start receiving location updates
    private func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    /// Stop receiving location updates (useful for battery optimization)
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    /// Called when location authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔍 LocationManager: Authorization changed to: \(status.rawValue)")
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("🔍 LocationManager: Permission granted, starting location updates")
            startLocationUpdates()
            errorMessage = nil
        case .denied, .restricted:
            print("🔍 LocationManager: Permission denied or restricted")
            errorMessage = "Location access is required to show your position on the map."
            currentLocation = nil
        case .notDetermined:
            print("🔍 LocationManager: Permission still not determined")
            break
        @unknown default:
            break
        }
    }
    
    /// Called when new location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        errorMessage = nil
    }
    
    /// Called when location manager encounters an error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
}
