import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var dontShowAgain = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.2),
                    Color.green.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .blur(radius: 10)
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome!")
                                .font(.largeTitle.bold())
                            Text("Overland Park Arts & Rec Guide")
                                .font(.title2.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            Image("arboretum")
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .shadow(radius: 3)
                                .frame(width: 96)
                                .accessibilityLabel("Arboretum")
                            Image("farm")
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .shadow(radius: 3)
                                .frame(width: 96)
                                .accessibilityLabel("Farm")
                            Image("arts")
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .shadow(radius: 3)
                                .frame(width: 96)
                                .accessibilityLabel("Arts")
                        }
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Text("This app helps you explore the arboretum, farmstead, and public arts installations supported by the Arts and Recreation Foundation of Overland Park.")
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            Text("You can hide or show different points of interest (POIs) categories and hiking trails by tapping the layers icon \(Image(systemName: "square.3.layers.3d")) on the map view.")
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            Text("Tapping a POI icon on the map view will display helpful information about it. Your location on the map can be toggled on or off using the location icon \(Image(systemName: "location")).")
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .padding(.horizontal)
                    .padding(.bottom, 120) // Space for fixed bottom content
                }
                .scrollBounceBehavior(.basedOnSize)
                
                // Fixed bottom section
                VStack(spacing: 20) {
                    Button("Continue") {
                        onContinue()
                        if dontShowAgain {
                            hasSeenWelcome = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: 200)
                    Toggle("Don't show this again", isOn: $dontShowAgain)
                        .frame(maxWidth: 250, alignment: .leading)
                }
                .padding()
                .padding(.horizontal)
            }
            .padding()
            .padding(.horizontal)
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}

