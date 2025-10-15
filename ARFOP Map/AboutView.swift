//
//  AboutView.swift
//  AFROP Map
//
//  Created by Dan Morgan on 10/5/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showIconPicker = false
    @State private var model = Model()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Centered title section
                    VStack(spacing: 8) {
                        Text("Overland Park Arts & Rec Guide")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Arts and Recreation Foundation of Overland Park")
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 14)
                    
                    Divider()
                        .padding(.top, 6)

                    Text("This app helps you explore the arboretum, farmstead, and public arts installations supported by the Arts and Recreation Foundation of Overland Park.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Points of interest pins may vary slightly from their actual locations.")
                            .font(.body)
                            .italic()
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Connectivity issues may prevent you from seeing POI photos stored in the cloud.")
                            .font(.body)
                            .italic()
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 18)
                

                    Divider()
                        .padding(.bottom, 6)
                    
                    // Centered "Created by:" text
                    Text("Created by:")
                        .font(.headline)
                        .padding(.top, 6)
                    
                    // Logo centered
                    Link(destination: URL(string: "https://danmorgandesigns.com")!) {
                        Image("dmd-full-outlines")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 120)
                            .padding(.vertical, 6)
                    }
                    
                    // Contact info centered
                    VStack(alignment: .center) {
                        Text("Overland Park, KS")
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About This App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Button(action: { dismiss() }) {
                              Image(systemName: "xmark")
                          }
                    }
                }
            }   
            .safeAreaInset(edge: .bottom, alignment: .center) {
                Button {
                    showIconPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "app.badge")
                        Text("Change app icon")
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.bordered)
                .padding(.leading, 16)
                .padding(.bottom, 16)
            }
            .environment(model)
            .sheet(isPresented: $showIconPicker) {
                IconChooser()
                    .environment(model)
            }
        }
    }
}

struct AboutRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

