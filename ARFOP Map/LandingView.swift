//
//  LandingView.swift
//  afrop map
//
//  Created by Dan Morgan on 10/4/25.
//

import SwiftUI
import MapKit

struct LandingView: View {
    let onSelect: (MKCoordinateRegion) -> Void
    @State private var showAbout = false
    @State private var showIDCard = false
    @State private var showHelp = false
    
    // Predefined coordinates for each image tap
    private let arboretumCenter = CLLocationCoordinate2D(latitude: 38.79594, longitude: -94.69087)
    private let farmCenter = CLLocationCoordinate2D(latitude: 38.87695, longitude: -94.70326)
    private let artsCenter = CLLocationCoordinate2D(latitude: 38.94148, longitude: -94.66798)
    
    var body: some View {
        ZStack {
            // Background: frosted translucent material over a subtle gradient
            LinearGradient(colors: [.blue.opacity(0.2), .green.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .blur(radius: 10)
            
            VStack(spacing: 24) {
                Text("Arts & Rec Guide")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.primary)
                    .padding(.top, 16)

                GeometryReader { proxy in
                    let halfWidth = proxy.size.width * 0.5
                    VStack(spacing: 24) {
                        LandingButton(imageName: "arboretum", title: "Arboretum") {
                            onSelect(
                                MKCoordinateRegion(
                                    center: arboretumCenter,
                                    latitudinalMeters: 800,
                                    longitudinalMeters: 800
                                )
                            )
                        }
                        .frame(width: halfWidth)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        LandingButton(imageName: "farm", title: "Farm") {
                            onSelect(
                                MKCoordinateRegion(
                                    center: farmCenter,
                                    latitudinalMeters: 500,
                                    longitudinalMeters: 500
                                )
                            )
                        }
                        .frame(width: halfWidth)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        LandingButton(imageName: "arts", title: "Arts") {
                            onSelect(
                                MKCoordinateRegion(
                                    center: artsCenter,
                                    latitudinalMeters: 5000,
                                    longitudinalMeters: 5000
                                )
                            )
                        }
                        .frame(width: halfWidth)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer(minLength: 0)
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)

                // Bottom controls for About and Help
                HStack {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("About this app")
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Button {
                        showIDCard = true
                    } label: {
                        Image(systemName: "qrcode")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Show ID")
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Help")
                    .padding(.trailing, 16)
                }
                .sheet(isPresented: $showHelp) {
                    HelpView()
                }
                .sheet(isPresented: $showIDCard) {
                    IDCardView()
                }
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
            }
            .padding()
        }
    }
}

private struct LandingButton: View {
    let imageName: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

#Preview {
    LandingView { _ in }
}
