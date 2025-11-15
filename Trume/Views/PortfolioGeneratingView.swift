//
//  PortfolioGeneratingView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI
import Combine

struct PortfolioGeneratingView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var progress: Double = 0.0
    @State private var estimatedTime: Int = 12
    @State private var templateItems: [TemplateItem] = []
    @Environment(\.presentationMode) var presentationMode
    
    @State private var simulatedProgress: Double = 0.0
    @State private var lastProgressUpdate: Date = Date()
    @State private var generationFailed: Bool = false
    @State private var failureMessage: String?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private static let logPrefix = "[PortfolioGeneratingView]"
    
    private var completedCount: Int {
        viewModel.currentSessionProjects.filter { $0.status == .completed }.count
    }
    
    private var canSave: Bool {
        let isEmpty = viewModel.currentSessionProjects.isEmpty
        let allCompleted = completedCount == viewModel.currentSessionProjects.count
        return !isEmpty && allCompleted
    }
    
    private func log(_ message: String) {
        print("\(Self.logPrefix) \(message)")
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Generating",
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Generated Projects")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                    // Grid of current session projects
                    ScrollView {
                        if generationFailed {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.4))
                                Text("Generation Failed")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(failureMessage ?? "An unexpected error occurred during generation.")
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 24)
                                
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Text("Go Back")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.51, green: 0.28, blue: 0.9))
                                        .cornerRadius(10)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            let projects = viewModel.currentSessionProjects
                            if projects.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("Waiting for portraits to generate...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                let columnCount = max(1, min(3, projects.count))
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount), spacing: 12) {
                                    ForEach(projects) { project in
                                        VStack(spacing: 4) {
                                            AsyncImage(url: URL(string: project.imageUrl)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Rectangle().fill(Color.gray.opacity(0.3))
                                            }
                                            .aspectRatio(3/4, contentMode: .fit)
                                            .clipped()
                                            .cornerRadius(12)
                                            .overlay(
                                                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                                                    .cornerRadius(12)
                                            )
                                            .overlay(
                                                Text(project.status == .completed ? project.style.name : "Processing...")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .padding(.bottom, 6)
                                                , alignment: .bottom
                                            )
                                            
                                            Text(project.status == .completed ? "Completed" : "Processing...")
                                                .font(.system(size: 10))
                                                .foregroundColor(project.status == .completed ? Color(red: 0.2, green: 0.78, blue: 0.35) : .white)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                        }
                    }
                    
                    // Progress Bar
                    VStack(spacing: 12) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(CustomProgressViewStyle())
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    
                    // Save Button
                    Button(action: {
                        saveSessionToLibrary()
                    }) {
                        HStack {
                            Spacer()
                            Text("Save Projects")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(height: 50)
                        .background(
                            Group {
                                if canSave {
                                    LinearGradient(
                                        colors: [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color(red: 0.098, green: 0.098, blue: 0.098)
                                }
                            }
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1.0 : 0.6)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            progress = viewModel.generationProgress
            simulatedProgress = viewModel.generationProgress
            startGeneration()
        }
        .onDisappear {
            if !viewModel.isGenerationInProgress {
                viewModel.generationTemplates = []
                viewModel.generationProgress = 0.0
            }
        }
        .onReceive(timer) { _ in
            updateProgress()
        }
    }
    
    private func startGeneration() {
        log("startGeneration triggered.")
        let initialProgress = viewModel.generationProgress
        progress = initialProgress
        estimatedTime = 60 // 增加预估时间，因为API调用需要更长时间
        simulatedProgress = initialProgress
        lastProgressUpdate = Date()
        viewModel.generationProgress = initialProgress
        generationFailed = false
        failureMessage = nil
        
        // 使用准备好的模板，默认使用Preset默认模板
        templateItems = viewModel.generationTemplates
        if templateItems.isEmpty, let fallbackTemplate = viewModel.defaultPresetTemplate {
            templateItems = [fallbackTemplate]
            log("Loaded fallback default template for generation.")
        }
        
        let hasExistingProjects = !viewModel.currentSessionProjects.isEmpty
        let hasGeneratingProjects = viewModel.currentSessionProjects.contains { $0.status == .generating }
        if hasExistingProjects {
            if viewModel.isGenerationInProgress || hasGeneratingProjects {
                log("Resuming existing generation session. progress=\(Int(progress * 100))%")
                return
            } else {
                progress = updateProgressSafely(to: 1.0, reason: "Existing session already completed")
                log("Existing generation session already completed.")
                return
            }
        }
        
        guard !templateItems.isEmpty else {
            log("No templates available. Presenting warning toast.")
            viewModel.showToast(message: "No templates available. Please add a template first.", type: .warning)
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        log("Loaded \(templateItems.count) templates for preset generation.")
        
        let templateNames = templateItems.map(\.name)
        let initialCount = max(4, templateNames.count)
        
        // 初始化项目，状态为generating，至少 4 个占位
        viewModel.currentSessionProjects = (0..<initialCount).map { index in
            let name: String
            if index < templateNames.count {
                name = templateNames[index]
            } else if let firstName = templateNames.first {
                name = "\(firstName) \(index + 1)"
            } else {
                name = "Portrait \(index + 1)"
            }
            
            return Project(
                id: UUID().uuidString,
                imageUrl: "",
                style: ProjectStyle(name: name, filter: ""),
                status: .generating,
                createdAt: Date(),
                progress: 0.0
            )
        }
        viewModel.saveCurrentSessionProjects()
        
        // 调用FaceChain API生成照片
        generateWithAPI()
        log("Generation pipeline started. projects=\(viewModel.currentSessionProjects.count)")
    }
    
    private func generateWithAPI() {
        // 检查是否有用户选择的照片
        guard !viewModel.selectedPhotos.isEmpty else {
            log("No selected photos. Aborting generation.")
            viewModel.showToast(message: "Please select photos first", type: .error)
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        log("Calling FaceChain API with \(templateItems.count) templates and \(viewModel.selectedPhotos.count) photos.")
        viewModel.showToast(message: "Generating portraits...", type: .info)
        
        // 调用API生成照片
        viewModel.faceChainService.generatePortraits(
            with: viewModel.selectedPhotos,
            templates: templateItems,
            progressHandler: { checkpoint in
                DispatchQueue.main.async {
                    switch checkpoint {
                    case .trainingArchiveUploaded:
                        progress = updateProgressSafely(to: 0.10, reason: "Training archive uploaded")
                        resetSimulatedProgress()
                    case .finetuneJobCreated:
                        progress = updateProgressSafely(to: 0.20, reason: "Finetune job created")
                        resetSimulatedProgress()
                    case .trainingResourceReady:
                        progress = updateProgressSafely(to: 0.90, reason: "Training resource ready")
                        resetSimulatedProgress()
                    }
                }
            }
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageUrls):
                    progress = updateProgressSafely(to: 1.0, reason: "Generation completed")
                    estimatedTime = 0
                    
                    if let deducted = self.viewModel.consumePendingGenerationCredits() {
                        self.viewModel.showToast(
                            message: "\(deducted) credits deducted. Remaining: \(self.viewModel.userData.credits.totalCredits)",
                            type: .success
                        )
                    }
                    
                    self.updateProjectsWithResults(imageUrls: imageUrls)
                    self.log("Generation succeeded with \(imageUrls.count) image URLs.")
                    
                case .failure(let error):
                    self.log("Generation failed. error=\(error.localizedDescription)")
                    self.viewModel.showToast(
                        message: "Generation failed: \(error.localizedDescription)",
                        type: .error
                    )
                    self.generationFailed = true
                    self.failureMessage = error.localizedDescription
                    self.estimatedTime = 0
                    self.resetSimulatedProgress()
                    progress = 0.0
                    self.simulatedProgress = 0.0
                    self.viewModel.generationProgress = 0.0
                    self.viewModel.currentSessionProjects = []
                    self.viewModel.saveCurrentSessionProjects()
                    self.viewModel.cancelPendingGenerationCredits()
                    // 可以选择重试或返回
                }
            }
        }
    }
    
    private func updateProjectsWithResults(imageUrls: [String]) {
        guard !generationFailed else { return }
        
        let nonEmptyUrls = imageUrls.filter { !$0.isEmpty }
        guard !nonEmptyUrls.isEmpty else {
            log("Received empty result set from generation.")
            viewModel.showToast(message: "Generation finished but returned no images", type: .warning)
            return
        }
        
        // 根据生成结果数量调整项目列表
        let urlCount = nonEmptyUrls.count
        var projects = viewModel.currentSessionProjects
        if projects.count > urlCount {
            projects = Array(projects.prefix(urlCount))
        } else if projects.count < urlCount {
            log("Extending project list to match generated results. urls=\(urlCount), projects=\(projects.count)")
            let templateCount = templateItems.count
            for index in projects.count..<urlCount {
                let styleSource: TemplateItem? = index < templateCount ? templateItems[index] : templateItems.last
                let styleName = styleSource?.name ?? "Portrait \(index + 1)"
                let newProject = Project(
                    id: UUID().uuidString,
                    imageUrl: "",
                    style: ProjectStyle(name: styleName, filter: ""),
                    status: .generating,
                    createdAt: Date(),
                    progress: 0.0
                )
                projects.append(newProject)
            }
        }
        viewModel.currentSessionProjects = projects
        viewModel.saveCurrentSessionProjects()
        
        // 逐个更新项目，模拟渐进式完成
        updateProjectAtIndex(0, imageUrls: nonEmptyUrls)
    }
    
    @discardableResult
    private func updateProgressSafely(to target: Double, reason: String) -> Double {
        let clamped = min(1.0, max(progress, target))
        if clamped > progress {
            log("Progress updated to \(Int(clamped * 100))% (\(reason))")
        }
        simulatedProgress = max(simulatedProgress, clamped)
        lastProgressUpdate = Date()
        viewModel.generationProgress = clamped
        
        if viewModel.isGenerationInProgress {
            var updated = viewModel.currentSessionProjects
            var hasChanges = false
            for index in updated.indices where updated[index].status == .generating && clamped > updated[index].progress {
                let project = updated[index]
                updated[index] = Project(
                    id: project.id,
                    imageUrl: project.imageUrl,
                    style: project.style,
                    status: project.status,
                    createdAt: project.createdAt,
                    progress: clamped
                )
                hasChanges = true
            }
            if hasChanges {
                viewModel.currentSessionProjects = updated
                viewModel.saveCurrentSessionProjects()
            }
        }
        return clamped
    }
    
    private func resetSimulatedProgress() {
        simulatedProgress = max(simulatedProgress, progress)
        lastProgressUpdate = Date()
    }
    
    private func updateProjectAtIndex(_ index: Int, imageUrls: [String]) {
        guard !generationFailed else { return }
        
        guard index < imageUrls.count && index < viewModel.currentSessionProjects.count else {
            // 所有项目都已完成
            viewModel.showToast(message: "All portraits generated successfully", type: .success)
            log("All projects marked completed.")
            estimatedTime = 0
            progress = updateProgressSafely(to: 1.0, reason: "Projects finalized")
            return
        }
        
        let imageUrl = imageUrls[index]
        var updatedProjects = viewModel.currentSessionProjects
        let project = updatedProjects[index]
        
        // 更新当前项目
        updatedProjects[index] = Project(
            id: project.id,
            imageUrl: imageUrl,
            style: project.style,
            status: .completed,
            createdAt: project.createdAt,
            progress: 1.0
        )
        log("Project updated at index=\(index). progress=\(index + 1)/\(imageUrls.count)")
        
        // 更新进度
        withAnimation {
            let target = Double(index + 1) / Double(imageUrls.count)
            progress = updateProgressSafely(to: target, reason: "Project \(index + 1) completed")
        }
        
        // 更新UI
        viewModel.currentSessionProjects = updatedProjects
        viewModel.saveCurrentSessionProjects()
        
        // 延迟更新下一个项目，模拟渐进式完成效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateProjectAtIndex(index + 1, imageUrls: imageUrls)
        }
    }
    
    private func updateProgress() {
        guard !generationFailed else { return }
        // 如果API调用已完成，不再更新进度
        guard progress < 1.0 else { return }
        
        // 如果所有项目都已完成，停止计时器
        let allCompleted = viewModel.currentSessionProjects.allSatisfy { $0.status == .completed }
        if allCompleted {
            progress = updateProgressSafely(to: 1.0, reason: "All projects completed")
            estimatedTime = 0
            return
        }
        
        // 模拟进度：每5秒 +1%，最高不超过 90%
        let now = Date()
        if now.timeIntervalSince(lastProgressUpdate) >= 5 {
            let baseline = max(progress, simulatedProgress)
            let target = min(0.90, baseline + 0.01)
            progress = updateProgressSafely(to: target, reason: "Simulated polling increment")
        }
        
        if estimatedTime > 0 {
            estimatedTime = max(0, estimatedTime - 1)
        }
    }
    
    private func saveSessionToLibrary() {
        log("saveSessionToLibrary triggered. canSave=\(canSave)")
        
        guard canSave else {
            viewModel.showToast(message: "Please wait for all projects to complete", type: .warning)
            return
        }
        
        log("Persisting \(viewModel.currentSessionProjects.count) generated projects.")
        // Save all projects
        viewModel.currentSessionProjects.forEach { project in
            viewModel.addProject(project)
        }
        viewModel.currentSessionProjects = []
        viewModel.saveCurrentSessionProjects()
        viewModel.generationProgress = 0.0
        
        // Show success message
        viewModel.showToast(message: "Projects saved successfully", type: .success)
        
        // Close generating view and navigate to portfolio
        presentationMode.wrappedValue.dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.log("Setting shouldShowPortfolio flag to true.")
            viewModel.shouldShowPortfolio = true
        }
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: 8)
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
    }
}

