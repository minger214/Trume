//
//  PortfolioView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct PortfolioView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var sortOrder: SortOrder = .newest
    @State private var selectedProject: Project?
    @Environment(\.presentationMode) var presentationMode
    
    enum SortOrder {
        case newest
        case oldest
    }
    
    var sortedProjects: [Project] {
        viewModel.projects.sorted { project1, project2 in
            switch sortOrder {
            case .newest:
                return project1.createdAt > project2.createdAt
            case .oldest:
                return project1.createdAt < project2.createdAt
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "All Projects",
                    showBackButton: true,
                    trailingButtons: [
                        NavigationBarButton(id: "sort", icon: "arrow.up.arrow.down") {
                            sortOrder = sortOrder == .newest ? .oldest : .newest
                            viewModel.showToast(
                                message: "Sorted by \(sortOrder == .newest ? "newest first" : "oldest first")",
                                type: .info
                            )
                        }
                    ],
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                
                if sortedProjects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(Color.white.opacity(0.3))
                        Text("No projects saved yet")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.6))
                        Text("Generate and save projects to see them here")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                            ForEach(sortedProjects) { project in
                                ProjectCard(
                                    project: project,
                                    onDelete: {
                                    viewModel.deleteProject(project.id)
                                    viewModel.showToast(message: "Project removed", type: .success)
                                    },
                                    onTap: {
                                        selectedProject = project
                                    }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedProject) { project in
            PictureWorksView(project: project, viewModel: viewModel)
        }
    }
}

struct ProjectCard: View {
    let project: Project
    let onDelete: () -> Void
    let onTap: () -> Void
    @State private var showDelete = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: project.imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .aspectRatio(3/4, contentMode: .fit)
                .clipped()
                .cornerRadius(16)
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(16)
                )
                .overlay(
                    Text(project.style.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                    ,
                    alignment: .bottom
                )
                
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
            
            Text(formatDate(project.createdAt))
                .font(.system(size: 10))
                .foregroundColor(project.status == .completed ? Color(red: 0.2, green: 0.78, blue: 0.35) : .white)
        }
        .onTapGesture {
            if showDelete {
                showDelete = false
            } else {
                onTap()
            }
        }
        .onLongPressGesture {
            showDelete.toggle()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        let days = Int(diff / 86400)
        
        if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else if days < 7 {
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

