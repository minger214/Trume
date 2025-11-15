//
//  PictureWorksView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI
import UIKit
import Photos

struct PictureWorksView: View {
    // MARK: - Properties
    
    let project: Project
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showShareSheet = false
    @State private var imageToShare: UIImage? = nil
    
    // MARK: - Constants
    
    private let backgroundColor = Color(red: 0.035, green: 0.039, blue: 0.039)
    private let gradientColors = [
        Color(red: 0.51, green: 0.28, blue: 0.9),
        Color(red: 0.83, green: 0.2, blue: 1.0)
    ]
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    navigationBar
                        .frame(width: geometry.size.width, height: 68)
                    
                    imageContentView
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height - 68 - 88
                        )
                    
                    actionButtons
                        .frame(width: geometry.size.width, height: 88)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = imageToShare {
                ShareSheet(activityItems: [image])
            }
        }
        .toast(viewModel: viewModel)
    }
    
    // MARK: - View Components
    
    private var navigationBar: some View {
        NavigationBar(
            title: "Project",
            showBackButton: true,
            onBack: {
                presentationMode.wrappedValue.dismiss()
            }
        )
        .background(
            Color.black.opacity(0.9)
                .ignoresSafeArea(edges: .top)
        )
        .zIndex(1000)
    }
    
    private var imageContentView: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: project.imageUrl)) { phase in
                switch phase {
                case .empty:
                    imagePlaceholder(showProgress: true)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .clipped()
                case .failure:
                    imagePlaceholder(showProgress: false)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom gradient overlay for better button visibility
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .allowsHitTesting(false)
        }
        .clipped()
        .frame(maxWidth: .infinity)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                actionButton(
                    icon: "square.and.arrow.down",
                    title: "Save",
                    action: saveImage
                )
                
                actionButton(
                    icon: "square.and.arrow.up",
                    title: "Share",
                    action: shareImage
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(backgroundColor)
        .zIndex(100)
    }
    
    // MARK: - Helper Views
    
    private func imagePlaceholder(showProgress: Bool) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Group {
                    if showProgress {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            )
    }
    
    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: gradientColors[0].opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    
    private func saveImage() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            performSave()
        case .notDetermined:
            requestPhotoLibraryPermission()
        case .denied, .restricted:
            viewModel.showToast(
                message: "Please allow photo library access in Settings",
                type: .warning
            )
        @unknown default:
            viewModel.showToast(
                message: "Photo library access unavailable",
                type: .error
            )
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
            DispatchQueue.main.async {
                if newStatus == .authorized || newStatus == .limited {
                    performSave()
                } else {
                    viewModel.showToast(
                        message: "Photo library access denied",
                        type: .error
                    )
                }
            }
        }
    }
    
    private func performSave() {
        downloadImage { result in
            switch result {
            case .success(let image):
                saveToPhotoLibrary(image: image)
            case .failure(let error):
                viewModel.showToast(
                    message: error.localizedDescription,
                    type: .error
                )
            }
        }
    }
    
    private func shareImage() {
        downloadImage { result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    imageToShare = image
                    showShareSheet = true
                }
            case .failure(let error):
                viewModel.showToast(
                    message: error.localizedDescription,
                    type: .error
                )
            }
        }
    }
    
    // MARK: - Image Operations
    
    private func downloadImage(completion: @escaping (Result<UIImage, ImageError>) -> Void) {
        guard let url = URL(string: project.imageUrl) else {
            completion(.failure(.invalidURL))
            return
        }
        
        viewModel.showToast(message: "Loading image...", type: .info)
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.downloadFailed(error.localizedDescription)))
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidImageData))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(image))
            }
        }.resume()
    }
    
    private func saveToPhotoLibrary(image: UIImage) {
        viewModel.showToast(message: "Saving to photo library...", type: .info)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    viewModel.showToast(message: "Save successfully.", type: .success)
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    viewModel.showToast(
                        message: "Failed to save: \(errorMessage)",
                        type: .error
                    )
                }
            }
        })
    }
}

// MARK: - Image Error

enum ImageError: LocalizedError {
    case invalidURL
    case downloadFailed(String)
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Failed to load image"
        case .downloadFailed(let message):
            return "Failed to download image: \(message)"
        case .invalidImageData:
            return "Failed to process image"
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {
        // No updates needed
    }
}
