//
//  PictureWorksView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI
import UIKit

struct PictureWorksView: View {
    let project: Project
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showShareSheet = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Share Activity View State
    @State private var showShareActivity = false
    
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.039, blue: 0.039)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Project",
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .zIndex(100)
                
                // Main Content Area - Full Screen Image
                ZStack(alignment: .bottom) {
                    // Image Display
                    AsyncImage(url: URL(string: project.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.5))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom Gradient Overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                    .allowsHitTesting(false)
                }
                
                // Action Buttons
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        // Save Button
                        Button(action: {
                            saveImage()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Save")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
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
                        
                        // Share Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showShareActivity = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Share")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            
            // Share Activity View (Bottom Sheet)
            if showShareActivity {
                ShareActivityView(
                    project: project,
                    isPresented: $showShareActivity,
                    onShare: { shareOption in
                        handleShare(option: shareOption)
                    }
                )
            }
        }
        //.toast(viewModel: <#AppViewModel#>, isPresented: $showToast, message: toastMessage)
    }
    
    // MARK: - Actions
    
    private func saveImage() {
        // Load image from URL and save to photo library
        guard let url = URL(string: project.imageUrl) else {
            showToastMessage("Failed to load image")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    showToastMessage("Failed to save image")
                }
                return
            }
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            DispatchQueue.main.async {
                showToastMessage("Save successfully.")
            }
        }.resume()
    }
    
    private func handleShare(option: ShareOption) {
        switch option {
        case .contact(let name):
            showToastMessage("Sending to \(name)...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showToastMessage("Sent successfully to \(name)")
                withAnimation {
                    showShareActivity = false
                }
            }
        case .app(let appName):
            showToastMessage("Sharing to \(appName)...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showToastMessage("Shared successfully via \(appName)")
                withAnimation {
                    showShareActivity = false
                }
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}

// MARK: - Share Activity View

struct ShareActivityView: View {
    let project: Project
    @Binding var isPresented: Bool
    let onShare: (ShareOption) -> Void
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Overlay Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Bottom Sheet
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 12) {
                        // Preview Image
                        AsyncImage(url: URL(string: project.imageUrl)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                        }
                        .frame(width: 48, height: 48)
                        .cornerRadius(12)
                        .clipped()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share Image")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.13))
                            
                            Text("Select where to share")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Close Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.13))
                                .frame(width: 40, height: 40)
                                .background(Color(red: 0.9, green: 0.9, blue: 0.92))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Suggested Contacts
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Suggested")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.13))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                
                                VStack(spacing: 16) {
                                    ContactRow(
                                        name: "Sandy Wilder Cheng",
                                        initials: "SW",
                                        onSend: {
                                            onShare(.contact("Sandy Wilder Cheng"))
                                        }
                                    )
                                    
                                    ContactRow(
                                        name: "Kevin Leong",
                                        initials: "KL",
                                        onSend: {
                                            onShare(.contact("Kevin Leong"))
                                        }
                                    )
                                    
                                    ContactRow(
                                        name: "Juliana Mejia",
                                        initials: "JM",
                                        onSend: {
                                            onShare(.contact("Juliana Mejia"))
                                        }
                                    )
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.vertical, 20)
                            
                            // Share Apps
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Share to")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.13))
                                    .padding(.horizontal, 20)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                                    ShareAppIcon(
                                        icon: "message.fill",
                                        iconColor: .blue,
                                        name: "Messages",
                                        onTap: {
                                            onShare(.app("Messages"))
                                        }
                                    )
                                    
                                    ShareAppIcon(
                                        icon: "envelope.fill",
                                        iconColor: .red,
                                        name: "Mail",
                                        onTap: {
                                            onShare(.app("Mail"))
                                        }
                                    )
                                    
                                    ShareAppIcon(
                                        icon: "note.text",
                                        iconColor: .yellow,
                                        name: "Notes",
                                        onTap: {
                                            onShare(.app("Notes"))
                                        }
                                    )
                                    
                                    ShareAppIcon(
                                        icon: "bell.fill",
                                        iconColor: .green,
                                        name: "Reminders",
                                        onTap: {
                                            onShare(.app("Reminders"))
                                        }
                                    )
                                    
                                    ShareAppIcon(
                                        icon: "message.fill",
                                        iconColor: Color(red: 0.18, green: 0.55, blue: 0.34),
                                        name: "WhatsApp",
                                        onTap: {
                                            onShare(.app("WhatsApp"))
                                        }
                                    )
                                    
                                    ShareAppIcon(
                                        icon: "f.circle.fill",
                                        iconColor: Color(red: 0.24, green: 0.35, blue: 0.67),
                                        name: "Facebook",
                                        onTap: {
                                            onShare(.app("Facebook"))
                                        }
                                    )
                                    
                                    ShareAppIcon(
                                        icon: "camera.fill",
                                        iconColor: Color(red: 0.84, green: 0.29, blue: 0.57),
                                        name: "Instagram",
                                        onTap: {
                                            onShare(.app("Instagram"))
                                        }
                                    )
                                    
                                    ShareAppIcon(
                                        icon: "ellipsis",
                                        iconColor: .gray,
                                        name: "More",
                                        onTap: {
                                            onShare(.app("More"))
                                        }
                                    )
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .padding(.bottom, 40)
                            }
                        }
                    }
                }
                .background(Color(red: 0.96, green: 0.96, blue: 0.97))
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .frame(maxHeight: 500)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isPresented = false
                                    dragOffset = 0
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let name: String
    let initials: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(red: 0.82, green: 0.82, blue: 0.84))
                    .frame(width: 40, height: 40)
                
                Text(initials)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.13))
            }
            
            Text(name)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.13))
            
            Spacer()
            
            // Send Button
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Share App Icon

struct ShareAppIcon: View {
    let icon: String
    let iconColor: Color
    let name: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.13))
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Share Option Enum

enum ShareOption {
    case contact(String)
    case app(String)
}

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

