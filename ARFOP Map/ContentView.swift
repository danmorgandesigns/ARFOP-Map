//
//  ContentView.swift
//  afrop map
//
//  Created by Dan Morgan on 9/30/25.
//

import SwiftUI
import MapKit

/// ContentView serves as the main entry point for the app
/// Shows a landing screen with three options, then navigates to the map
struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var selectedRegion: MKCoordinateRegion? = nil
    @State private var navigateToMap: Bool = false
    @State private var showWelcome: Bool = true
    
    var body: some View {
        NavigationStack {
            Group {
                if !showWelcome {
                    ZStack {
                        LandingView { region in
                            selectedRegion = region
                            navigateToMap = true
                        }
                    }
                } else {
                    WelcomeView {
                        showWelcome = false
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToMap) {
                MapView(initialRegion: selectedRegion)
            }
        }
        .onAppear {
            showWelcome = !hasSeenWelcome
        }
    }
}

#Preview {
    ContentView()
}

