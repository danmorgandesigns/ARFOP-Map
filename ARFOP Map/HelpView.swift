//
//  HelpView.swift
//  ARFOP Map
//
//  Created by Dan Morgan on 10/5/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HelpRow(icon: "chevron.left", text: "Return to landing screen")
                    HelpRow(icon: "globe", text: "Switch to satellite base layer")
                    HelpRow(icon: "map", text: "Switch to map base layer")
                    HelpRow(icon: "square.3.layers.3d", text: "Select points of interest layers")
                    HelpRow(icon: "location", text: "Toggle My Location")
                    HelpRow(icon: "app.badge", text: "Change the app icon")
                    HelpRow(icon: "info.circle", text: "About this app")
                    HelpRow(icon: "qrcode", text: "Membership ID")
                    HelpRow(icon: "questionmark.circle", text: "This help screen")
                }
                .padding(.leading, 28)
                .padding(.top, 20)
                
                Divider()
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Use the controls above to change the base map, toggle your location, and select points of interest.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("You can also customize the app icon to one of the three Friends organizations within ARFOP as well as add your membership ID QR code for convenience.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 18)

                Divider()
                    .padding(.bottom, 8)

                VStack(alignment: .center, spacing: 8) {
                    AddressInfoRow(
                        title: "Overland Park Arboretum &\nBotanical Gardens",
                        url: URL(string: "https://www.opkansas.org/recreation-fun/arboretum-botanical-gardens/"),
                        addressLines: [
                            "8909 W. 179th Street",
                            "Overland Park, KS 66013"
                        ],
                        hoursLines: [
                            "Open Sunday–Saturday 9 a.m. to 5 p.m.",
                            "Open until 8 p.m. Tue & Thu April–August"
                        ],
                        mapsQuery: "8909 W. 179th Street, Overland Park, KS 66013"
                    )
                    
                    AddressInfoRow(
                        title: "Deanna Rose Children's Farmstead",
                        url: URL(string: "https://www.opkansas.org/recreation-fun/deanna-rose-childrens-farmstead/"),
                        addressLines: [
                            "13800 Switzer Rd.",
                            "Overland Park, KS 66221"
                        ],
                        hoursLines: [
                            "Open Sunday–Saturday 9 a.m. to 5 p.m.",
                            "April 1 to October 31."
                        ],
                        mapsQuery: "13800 Switzer Rd., Overland Park, KS 66221"
                    )
                    .padding(.vertical)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .navigationTitle("Help")
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
    
    struct HelpRow: View {
        let icon: String
        let text: String
        
        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)  // Makes the icon larger
                    .foregroundStyle(.blue)
                    .frame(width: 32)
                Text(text)
                    .font(.body)  // Adjust text size here
                Spacer()
            }
        }
    }
    
    struct AddressInfoRow: View {
        let title: String
        let url: URL?
        let addressLines: [String]
        let hoursLines: [String]
        let mapsQuery: String
        
        @Environment(\.openURL) private var openURL
        
        private func openInMaps() {
            let query = mapsQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mapsQuery
            if let url = URL(string: "http://maps.apple.com/?daddr=\(query)") {
                openURL(url)
            }
        }

        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 2) {
                        ForEach(addressLines, id: \.self) { line in
                            Button(action: openInMaps) {
                                Text(line)
                                    .font(.body)
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                VStack(spacing: 2) {
                    ForEach(hoursLines, id: \.self) { line in
                        Text(line)
                            .font(.body)
                    }
                }
                
                if let url {
                    Link(destination: url) {
                        Text("Website")
                            .font(.body)
                            .foregroundStyle(.blue)
                    }
                } else {
                    Text("Website")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .opacity(0.5)
                }
            }
        }
    }
}

