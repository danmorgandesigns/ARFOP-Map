//
//  ConnectivityManager.swift
//  ARFOP Map
//
//  Created by Dan Morgan on 10/17/25.
//

import Foundation
import Network
import Combine

@MainActor
class ConnectivityManager: ObservableObject {
    @Published var isConnected = false
    @Published var hasStrongConnection = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            nonisolated(unsafe) let weakSelf = self
            Task { @MainActor in
                weakSelf?.updateConnectionStatus(path)
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    nonisolated private func stopMonitoring() {
        networkMonitor.cancel()
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        
        // Determine connection strength
        if path.status == .satisfied {
            // Check for WiFi (strongest)
            if path.usesInterfaceType(.wifi) {
                hasStrongConnection = true
                connectionType = .wifi
            }
            // Check for cellular
            else if path.usesInterfaceType(.cellular) {
                hasStrongConnection = true // Assume cellular is good enough
                connectionType = .cellular
            }
            // Other connection types (ethernet, etc.)
            else {
                hasStrongConnection = true
                connectionType = path.availableInterfaces.first?.type
            }
        } else {
            hasStrongConnection = false
            connectionType = nil
        }
        
        print("🌐 Connection status: \(isConnected ? "Connected" : "Disconnected"), Strong: \(hasStrongConnection), Type: \(connectionType?.debugDescription ?? "Unknown")")
    }
}

extension NWInterface.InterfaceType {
    var debugDescription: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .wiredEthernet: return "Ethernet"
        case .loopback: return "Loopback"
        case .other: return "Other"
        @unknown default: return "Unknown"
        }
    }
}
