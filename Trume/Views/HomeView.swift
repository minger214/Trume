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
    @State private var showSettingsView = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss

    private let backgroundColor = Color(red: 0.035, green: 0.039, blue: 0.039)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Trume",
                    // leadingButtons: buildLeadingButtons(),
                    trailingButtons: buildTrailingButtons()
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
                            if viewModel.userData.isActiveMember {
                                // 活跃用户：显示图标和积分
                                HStack(spacing: 5) {
                                    Image(systemName: "circle.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                    Text("\(viewModel.userData.credits.totalCredits)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.gray)
                                )
                            } else {
                                // 非活跃用户：只显示斜体 PRO
                                Text("PRO")
                                    .font(.system(size: 12, weight: .semibold))
                                    .italic()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                        }
                        .padding(.leading, 20)
                        Spacer()
                    }
                )
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Featured Section
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Show us what you look like")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Upload your selfies to help the AI generate realistic portrait photos of you !")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color.black)
                            
                            HomeIntroduceImage()
                        }
                        .cornerRadius(16)
                        // .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Selected Photos Display
                        if !viewModel.selectedPhotos.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Your selfies")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                
                                // Border only around LazyVGrid
                                VStack {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                        ForEach(viewModel.selectedPhotos) { photo in
                                            PhotoThumbnailView(photo: photo, onDelete: {
                                                viewModel.removeSelectedPhoto(photo.id)
                                                viewModel.showToast(message: "Photo removed", type: .success)
                                            })
                                        }
                                        
                                        // Add photo button
                                        if viewModel.selectedPhotos.count < viewModel.featureConfig.homePage.maxPhotoSelectionCount {
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
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                .background(Color(red: 0.035, green: 0.039, blue: 0.039))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(16)
                                .padding(.horizontal, 16)
                            }
                            
                            // Tapping Continue Introduction
                            VStack(alignment: .leading, spacing: 0) {
                                Text("By tapping “Continue”,you declare that you have all necessary rights and permissions to share these images with us and that you will use the photos generated lawfully.")
                                     .font(.system(size: 15))
                                     .foregroundColor(.white)
                                     .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 100) // Add bottom padding so content can scroll under button
                        
                        } else {
                            // Add padding when no photos to maintain consistent spacing
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                }
                .overlay(
                    // Upload Button - Floating at bottom
                    VStack {
                        Spacer()
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            Button(action: {
                                if !viewModel.selectedPhotos.isEmpty {
                                    // Continue with generation
                                    handleContinue()
                                } else {
                                    showPhotoSourceSheet = true
                                }
                            }) {
                                Text(viewModel.selectedPhotos.isEmpty ? "Upload 4 photos" : "Continue")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                        .background(Color.clear)
                    }
                    .allowsHitTesting(true)
                )
            }
        }
        .overlay(
            Group {
                if showPhotoSourceSheet {
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
                        },
                        onDismiss: {
                            showPhotoSourceSheet = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.easeInOut(duration: 0.2), value: showPhotoSourceSheet)
                }
            }
        )
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(
                selection: $selectedItem,
                onImageSelected: { image in
                    if viewModel.selectedPhotos.count >= viewModel.featureConfig.homePage.maxPhotoSelectionCount {
                        viewModel.showToast(message: "Maximum \(viewModel.featureConfig.homePage.maxPhotoSelectionCount) photos allowed", type: .warning)
                        return
                    }
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        viewModel.addSelectedPhoto(imageData: imageData)
                    }
                },
                maxSelection: viewModel.featureConfig.homePage.maxPhotoSelectionCount
            )
            .presentationBackground(Color(red: 0.035, green: 0.039, blue: 0.039))
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                if viewModel.selectedPhotos.count >= viewModel.featureConfig.homePage.maxPhotoSelectionCount {
                    viewModel.showToast(message: "Maximum \(viewModel.featureConfig.homePage.maxPhotoSelectionCount) photos allowed", type: .warning)
                    return
                }
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
            .presentationBackground(Color(red: 0.035, green: 0.039, blue: 0.039))
        }
        .sheet(isPresented: $showSubscriptionView) {
            NavigationView {
                SubscriptionView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .presentationBackground(Color(red: 0.035, green: 0.039, blue: 0.039))
        }
        .sheet(isPresented: $showCreditPurchaseView) {
            NavigationView {
                CreditPurchaseView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .presentationBackground(Color(red: 0.035, green: 0.039, blue: 0.039))
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
            .presentationBackground(Color.black)
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
            .presentationBackground(Color(red: 0.035, green: 0.039, blue: 0.039))
        }
        .sheet(isPresented: $showSettingsView) {
            NavigationView {
                SettingsView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .presentationBackground(Color(red: 0.035, green: 0.039, blue: 0.039))
        }
    }
    
    private func buildLeadingButtons() -> [NavigationBarButton] {
        return [
            NavigationBarButton.customView(id: "credits") {
                Group {
                    if viewModel.userData.isActiveMember {
                        // 活跃用户：显示图标和积分
                        HStack(spacing: 5) {
                            Image(systemName: "circle.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                            Text("\(viewModel.userData.credits.totalCredits)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.gray)
                        )
                    } else {
                        // 非活跃用户：只显示斜体 PRO
                        Text("PRO")
                            .font(.system(size: 12, weight: .semibold))
                            .italic()
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                }
                .padding(.leading, 20)
            } action: {
                if viewModel.userData.isActiveMember {
                    // 活跃会员：打开积分页面
                    showCreditsView = true
                } else {
                    // 非活跃会员：打开订阅页面
                    showSubscriptionView = true
                }
            }
        ]
    }
    
    private func buildTrailingButtons() -> [NavigationBarButton] {
        var buttons: [NavigationBarButton] = []
        
        // 添加作品集图标按钮
        buttons.append(NavigationBarButton(id: "portfolio", icon: "square.grid.2x2") {
            showPortfolioView = true
        })
        
        if viewModel.featureConfig.homePage.showNotificationButton {
            buttons.append(NavigationBarButton(id: "notifications", icon: "bell") {
                viewModel.showToast(message: "No new notifications", type: .info)
            })
        }
        
        if viewModel.featureConfig.homePage.showSettingsButton {
            buttons.append(NavigationBarButton(id: "settings", icon: "gearshape") {
                showSettingsView = true
            })
        }
        
        return buttons
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
        
        // 如果生成已完成，清空之前的项目以开始新的生成
        if !viewModel.isGenerationInProgress && !viewModel.currentSessionProjects.isEmpty {
            let allCompleted = viewModel.currentSessionProjects.allSatisfy { $0.status == .completed }
            if allCompleted {
                viewModel.currentSessionProjects = []
                viewModel.saveCurrentSessionProjects()
            }
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
    @State private var isAnimated = false
    
    var body: some View {
        Group {
            if UIImage(named: "home-introduce") != nil {
                Image("home-introduce")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 450)
                    .scaleEffect(isAnimated ? 1.0 : 0.95)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8), value: isAnimated)
                    .onAppear {
                        isAnimated = true
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 450)
                    .overlay(
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                    )
                    .scaleEffect(isAnimated ? 1.0 : 0.95)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8), value: isAnimated)
                    .onAppear {
                        isAnimated = true
                    }
            }
        }
    }
}

struct PhotoThumbnailView: View {
    let photo: SelectedPhoto
    let onDelete: () -> Void
    
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
            
            // Delete button always visible
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color.gray.opacity(0.8))
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(4)
        }
    }
}

struct PhotoSourceSheet: View {
    let onCamera: () -> Void
    let onLibrary: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Content card with close button
            ZStack(alignment: .topTrailing) {
                // Content card
                VStack(spacing: 0) {
                    // Title - Centered
                    Text("Take photo from")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                        .padding(.bottom, 24)
                    
                    // Buttons - Side by side
                    HStack(spacing: 12) {
                        Button(action: onCamera) {
                            Text("Camera")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(action: onLibrary) {
                            Text("Photo library")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
                .frame(width: 320)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Close button - positioned at top right corner of the card
                Button(action: onDismiss) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 28, height: 28)
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(width:28, height: 28)
                }
                .offset(x: 12, y: -40)
            }
        }
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selection: PhotosPickerItem?
    let onImageSelected: (UIImage) -> Void
    var maxSelection: Int = 10
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelection
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
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

