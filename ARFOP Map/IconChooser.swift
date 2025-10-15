import SwiftUI

struct IconChooser: View {
    @Environment(Model.self) var model: Model
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Icon.allCases) { icon in
                    Button {
                        model.setAlternateAppIcon(icon: icon)
                    } label: {
                        HStack(spacing: 16) {
                            // Show the actual icon preview
                            Image(uiImage: icon.previewImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                            
                            Text(icon.displayName)
                                .font(.headline)
                            
                            Spacer()
                            
                            // Checkmark if this is the current icon
                            if model.appIcon == icon {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Choose App Icon")
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
        }
    }
}

#Preview {
    IconChooser()
        .environment(Model())
}
