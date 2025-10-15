//
//  IDCardView.swift
//  AFROP Map
//
//  Created by Dan Morgan on 10/5/25.
//

import SwiftUI
import PhotosUI

struct IDCardView: View {
    @AppStorage("membershipIDImageData") private var membershipIDImageData: Data?
    @State private var showSourceActionSheet = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedUIImage: UIImage?
    @State private var showFullScreen = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL

    private func handlePickedImage(_ image: UIImage) {
        // Resize to a reasonable max dimension (e.g., 1200px) maintaining aspect ratio
        let maxDimension: CGFloat = 1200
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let targetSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        // Store as PNG (lossless) to preserve QR code fidelity
        if let data = resized.pngData() {
            membershipIDImageData = data
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let data = membershipIDImageData, let uiImage = UIImage(data: data) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .background(Color.white) // improve contrast for scanning
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.quaternary, lineWidth: 1)
                                )
                                .accessibilityLabel("Membership ID image")

                            Button {
                                showFullScreen = true
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.headline)
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .padding(10)
                            .accessibilityLabel("View full screen")
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No ID image yet")
                                .foregroundStyle(.secondary)
                            Text("Add your ID Code using the button below.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Membership ID Code")
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
                VStack(spacing: 8) {
                    Button {
                        showSourceActionSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                            Text("Add your ID Code")
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        if let url = URL(string: "https://artsandrec-op.org/the-arts-recreation-foundation-of-overland-park/") {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "info.bubble")
                            Text("Not a Member?")

                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.leading, 16)
                .padding(.bottom, 16)
            }

        }
        .confirmationDialog("Add your ID Code", isPresented: $showSourceActionSheet, titleVisibility: .visible) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Library") { showPhotoPicker = true }
            if membershipIDImageData != nil {
                Button("Remove Current Image", role: .destructive) { membershipIDImageData = nil }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                if let image { handlePickedImage(image) }
            }
        }
        .task(id: selectedItem) {
            guard let selectedItem else { return }
            do {
                if let data = try await selectedItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                    handlePickedImage(uiImage)
                }
            } catch {
                // Ignore errors for now
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenImageView(imageData: membershipIDImageData) {
                showFullScreen = false
            }
        }
    }
}

struct CaptureRow: View {
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

import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    enum SourceType {
        case camera
        case photoLibrary
        
        var uiImagePickerSource: UIImagePickerController.SourceType {
            switch self {
            case .camera: return .camera
            case .photoLibrary: return .photoLibrary
            }
        }
    }
    
    var sourceType: SourceType
    var onImagePicked: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType.uiImagePickerSource
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            parent.onImagePicked(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

import AVKit

struct FullScreenImageView: View {
    let imageData: Data?
    var onDismiss: () -> Void
    @State private var keepAwakeToken: Any?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(Color.white)
            } else {
                Text("No image available")
                    .foregroundStyle(.secondary)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.7))
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            // Keep screen awake while presenting (optional but helpful for scanning)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

