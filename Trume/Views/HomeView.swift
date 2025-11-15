//
//  HomeView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI
import PhotosUI
import UIKit

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showPhotoSourceSheet = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCreditsView = false
    @State private var showSubscriptionView = false
    @State private var showCreditPurchaseView = false
    @State private var showPortfolioGeneratingView = false
    @State private var showPortfolioView = false
    @State private var showTemplateView = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.039, blue: 0.039)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Trume",
                    trailingButtons: [
                        NavigationBarButton(id: "notifications", icon: "bell") {
                            viewModel.showToast(message: "No new notifications", type: .info)
                        },
                        NavigationBarButton(id: "settings", icon: "gearshape") {
                            viewModel.showToast(message: "Settings coming soon", type: .info)
                        }
                    ],
                    onBack: nil
                )
                .overlay(
                    HStack {
                        Button(action: {
                            if viewModel.userData.isActiveMember {
                                // 活跃会员：打开积分页面
                                showCreditsView = true
                            } else {
                                // 非活跃会员：打开订阅页面
                                showSubscriptionView = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                Text(viewModel.userData.isActiveMember ? "\(viewModel.userData.credits.totalCredits)" : "PRO")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.leading, 16)
                        Spacer()
                    }
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Featured Section
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Show us what you look like")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Upload your selfies to help the AI generate realistic portrait photos of you!")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                            
                            HomeIntroduceImage()
                        }
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .onTapGesture {
                            showTemplateView = true
                        }
                        
                        // Selected Photos Display
                        if !viewModel.selectedPhotos.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your selfies")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                                    ForEach(viewModel.selectedPhotos) { photo in
                                        PhotoThumbnailView(photo: photo, onDelete: {
                                            viewModel.removeSelectedPhoto(photo.id)
                                            viewModel.showToast(message: "Photo removed", type: .success)
                                        })
                                    }
                                    
                                    // Add photo button
                                    Button(action: {
                                        showPhotoSourceSheet = true
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(red: 0.098, green: 0.098, blue: 0.098))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                )
                                            Image(systemName: "plus")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .aspectRatio(1, contentMode: .fit)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Upload Button
                        Button(action: {
                            if !viewModel.selectedPhotos.isEmpty {
                                // Continue with generation
                                handleContinue()
                            } else {
                                showPhotoSourceSheet = true
                            }
                        }) {
                            Text(viewModel.selectedPhotos.isEmpty ? "Upload photos" : "Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color(red: 0.51, green: 0.28, blue: 0.9).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showPhotoSourceSheet) {
            PhotoSourceSheet(
                onCamera: {
                    showPhotoSourceSheet = false
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        viewModel.showToast(message: "Camera not available on this device", type: .error)
                    }
                },
                onLibrary: {
                    showPhotoSourceSheet = false
                    showPhotoPicker = true
                }
            )
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(selection: $selectedItem) { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    viewModel.addSelectedPhoto(imageData: imageData)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    viewModel.addSelectedPhoto(imageData: imageData)
                }
            }
        }
        .sheet(isPresented: $showCreditsView) {
            NavigationView {
                UserCreditsView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
        .sheet(isPresented: $showSubscriptionView) {
            NavigationView {
                SubscriptionView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
        .sheet(isPresented: $showCreditPurchaseView) {
            NavigationView {
                CreditPurchaseView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
        .fullScreenCover(isPresented: $showPortfolioGeneratingView) {
            PortfolioGeneratingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showPortfolioView) {
            NavigationView {
                PortfolioView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
        .onChange(of: viewModel.shouldShowPortfolio) { oldValue, newValue in
            if newValue {
                showPortfolioView = true
                viewModel.shouldShowPortfolio = false
            }
        }
        .sheet(isPresented: $showTemplateView) {
            NavigationView {
                TemplateView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
    }
    
    private func handleContinue() {
        let requiredCredits = 150
        
        guard viewModel.userData.isActiveMember else {
            viewModel.showToast(message: "Please subscribe to continue", type: .warning)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSubscriptionView = true
            }
            return
        }
        
        guard viewModel.userData.credits.totalCredits >= requiredCredits else {
            viewModel.showToast(message: "Insufficient credits! You need 150 credits", type: .error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCreditPurchaseView = true
            }
            return
        }
        
        if viewModel.isGenerationInProgress {
            viewModel.showToast(message: "A generation task is already running", type: .info)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showPortfolioGeneratingView = true
            }
            return
        }
        
        guard let defaultTemplate = viewModel.defaultPresetTemplate else {
            viewModel.showToast(message: "Please set a default template first", type: .warning)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showTemplateView = true
            }
            return
        }
        
        guard viewModel.reserveGenerationCredits(requiredCredits) else {
            viewModel.showToast(message: "Unable to reserve credits", type: .error)
            return
        }
        
        viewModel.prepareGenerationSession(using: [defaultTemplate])
        viewModel.showToast(message: "Generation started. Credits will be charged on success.", type: .info)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showPortfolioGeneratingView = true
        }
    }
}

private struct HomeIntroduceImage: View {
    var body: some View {
        if UIImage(named: "home-introduce") != nil {
            Image("home-introduce")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .overlay(
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                )
        }
    }
}

struct PhotoThumbnailView: View {
    let photo: SelectedPhoto
    let onDelete: () -> Void
    @State private var showDelete = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let imageData = photo.imageData,
               let uiImage = UIImage(data: imageData) {
                GeometryReader { geometry in
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                        .cornerRadius(12)
                }
                .aspectRatio(1, contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
            }
            
            if showDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(4)
            }
        }
        .onTapGesture {
            showDelete.toggle()
        }
    }
}

struct PhotoSourceSheet: View {
    let onCamera: () -> Void
    let onLibrary: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Take photo from")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            VStack(spacing: 12) {
                Button(action: onCamera) {
                    HStack {
                        Image(systemName: "camera")
                            .font(.system(size: 18))
                        Text("Camera")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                    .cornerRadius(12)
                }
                
                Button(action: onLibrary) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                        Text("Photo library")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.black)
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selection: PhotosPickerItem?
    let onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 10
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, presentationMode: presentationMode)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        let presentationMode: Binding<PresentationMode>
        
        init(onImageSelected: @escaping (UIImage) -> Void, presentationMode: Binding<PresentationMode>) {
            self.onImageSelected = onImageSelected
            self.presentationMode = presentationMode
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            presentationMode.wrappedValue.dismiss()
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.onImageSelected(image)
                        }
                    }
                }
            }
        }
    }
}

