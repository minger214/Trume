//
//  AppViewModel.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import Foundation
import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var userData: UserData = UserData()
    @Published var projects: [Project] = []
    @Published var selectedPhotos: [SelectedPhoto] = []
    @Published var currentSessionProjects: [Project] = []
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastType: ToastType = .info
    @Published var shouldShowPortfolio: Bool = false
    @Published var presetTemplates: [TemplateItem] = []
    @Published var customTemplates: [TemplateItem] = []
    @Published var pendingGenerationCredits: Int?
    @Published var generationTemplates: [TemplateItem] = []
    @Published private(set) var isGenerationInProgress: Bool = false
    @Published var generationProgress: Double = 0.0
    
    enum ToastType {
        case success
        case error
        case info
        case warning
    }
    
    private let userDefaults = UserDefaults.standard
    let faceChainService = FaceChainAPIService()
    
    private let presetTemplatesKey = "trume.preset.templates"
    private let customTemplatesKey = "trume.custom.templates"
    
    // 照片文件系统存储目录
    static var photosDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("SelectedPhotos", isDirectory: true)
    }
    
    init() {
        loadUserData()
        loadProjects()
        loadSelectedPhotos()
        loadCurrentSessionProjects()
        loadTemplateLibrary()
    }
    
    // MARK: - User Data
    func loadUserData() {
        if let data = userDefaults.data(forKey: "userData"),
           let decoded = try? JSONDecoder().decode(UserData.self, from: data) {
            userData = decoded
            // Check subscription expiration
            checkSubscriptionExpiration()
        } else {
            // Set default mock data - 非订阅用户
            userData = UserData()
            saveUserData()
        }
    }
    
    // MARK: - Templates
    private func loadTemplateLibrary() {
        if let data = userDefaults.data(forKey: presetTemplatesKey),
           let decoded = try? JSONDecoder().decode([TemplateItem].self, from: data),
           !decoded.isEmpty {
            presetTemplates = decoded
        } else {
            presetTemplates = AppViewModel.defaultPresetTemplates()
            saveTemplates(for: .preset)
        }
        ensurePresetDefault()
        
        if let data = userDefaults.data(forKey: customTemplatesKey),
           let decoded = try? JSONDecoder().decode([TemplateItem].self, from: data) {
            customTemplates = decoded
        } else {
            customTemplates = []
        }
    }
    
    var defaultPresetTemplate: TemplateItem? {
        presetTemplates.first(where: { $0.isDefault }) ?? presetTemplates.first
    }
    
    func templates(for category: TemplateCategory) -> [TemplateItem] {
        switch category {
        case .preset:
            return presetTemplates
        case .custom:
            return customTemplates
        }
    }
    
    func setDefaultPresetTemplate(id: String) {
        guard presetTemplates.contains(where: { $0.id == id }) else { return }
        presetTemplates = presetTemplates.map { template in
            var updated = template
            updated.isDefault = (template.id == id)
            return updated
        }
        ensurePresetDefault()
        saveTemplates(for: .preset)
    }
    
    func prepareGenerationSession(using templates: [TemplateItem]) {
        generationTemplates = templates
        isGenerationInProgress = true
        generationProgress = 0.0
    }
    
    private func ensurePresetDefault() {
        guard !presetTemplates.isEmpty else { return }
        
        var foundDefault = false
        for index in presetTemplates.indices {
            if presetTemplates[index].isDefault {
                if !foundDefault {
                    foundDefault = true
                } else {
                    presetTemplates[index].isDefault = false
                }
            }
        }
        
        if !foundDefault {
            presetTemplates[0].isDefault = true
            foundDefault = true
        }
        
        if let currentDefaultIndex = presetTemplates.firstIndex(where: { $0.isDefault }),
           currentDefaultIndex != 0 {
            var templates = presetTemplates
            let defaultTemplate = templates.remove(at: currentDefaultIndex)
            templates.insert(defaultTemplate, at: 0)
            presetTemplates = templates
        }
    }
    
    func addTemplate(_ template: TemplateItem) {
        switch template.category {
        case .preset:
            presetTemplates.insert(template, at: 0)
            ensurePresetDefault()
        case .custom:
            customTemplates.insert(template, at: 0)
        }
        saveTemplates(for: template.category)
    }
    
    func updateTemplate(_ template: TemplateItem) {
        switch template.category {
        case .preset:
            if let index = presetTemplates.firstIndex(where: { $0.id == template.id }) {
                presetTemplates[index] = template
                ensurePresetDefault()
                saveTemplates(for: .preset)
            }
        case .custom:
            if let index = customTemplates.firstIndex(where: { $0.id == template.id }) {
                customTemplates[index] = template
                saveTemplates(for: .custom)
            }
        }
    }
    
    func deleteTemplate(_ template: TemplateItem) {
        switch template.category {
        case .preset:
            presetTemplates.removeAll { $0.id == template.id }
            ensurePresetDefault()
            saveTemplates(for: .preset)
        case .custom:
            customTemplates.removeAll { $0.id == template.id }
            saveTemplates(for: .custom)
        }
    }
    
    func styleCode(from name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let transformed = name
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
        return transformed.isEmpty ? "style_\(UUID().uuidString.prefix(6))" : transformed
    }
    
    private func saveTemplates(for category: TemplateCategory) {
        let encoder = JSONEncoder()
        switch category {
        case .preset:
            if let data = try? encoder.encode(presetTemplates) {
                userDefaults.set(data, forKey: presetTemplatesKey)
            }
        case .custom:
            if let data = try? encoder.encode(customTemplates) {
                userDefaults.set(data, forKey: customTemplatesKey)
            }
        }
    }
    
    static func defaultPresetTemplates() -> [TemplateItem] {
        [
            TemplateItem(
                name: "ID Photo (Male)",
                detail: "Professional ID photo style",
                category: .preset,
                styleCode: "f_idcard_male",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=201")!),
                isSystemTemplate: true,
                isDefault: false
            ),
            TemplateItem(
                name: "Business Attire (Male)",
                detail: "Formal business portrait",
                category: .preset,
                styleCode: "f_business_male",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=202")!),
                isSystemTemplate: true,
                isDefault: false
            ),
            TemplateItem(
                name: "ID Photo (Female)",
                detail: "Professional ID photo style",
                category: .preset,
                styleCode: "f_idcard_female",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=201")!),
                isSystemTemplate: true,
                isDefault: false
            ),
            TemplateItem(
                name: "Business Attire (Female)",
                detail: "Formal business portrait",
                category: .preset,
                styleCode: "f_business_female",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=202")!),
                isSystemTemplate: true,
                isDefault: false
            ),
            TemplateItem(
                name: "Spring Outfit (Male)",
                detail: "Fresh spring styling",
                category: .preset,
                styleCode: "m_springflower_female",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=203")!),
                isSystemTemplate: true,
                isDefault: false
            ),
            TemplateItem(
                name: "Summer Outfit (Male)",
                detail: "Breezy summer styling",
                category: .preset,
                styleCode: "f_summersport_female",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=204")!),
                isSystemTemplate: true,
                isDefault: false
            ),
            TemplateItem(
                name: "Autumn Outfit (Male)",
                detail: "Warm autumn styling",
                category: .preset,
                styleCode: "f_autumnleaf_female",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=205")!),
                isSystemTemplate: true,
                isDefault: false
            ),
            TemplateItem(
                name: "Winter Outfit (Male)",
                detail: "Cozy winter styling",
                category: .preset,
                styleCode: "m_winterchinese_female",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=206")!),
                isSystemTemplate: true,
                isDefault: false
            ),
            TemplateItem(
                name: "Light Portray (Male)",
                detail: "Light portray style",
                category: .preset,
                styleCode: "f_lightportray_female",
                imageSource: .remote(url: URL(string: "https://picsum.photos/900/1200?random=201")!),
                isSystemTemplate: true,
                isDefault: true
            )
        ]
    }
    
    func saveUserData() {
        if let encoded = try? JSONEncoder().encode(userData) {
            userDefaults.set(encoded, forKey: "userData")
        }
    }
    
    func checkSubscriptionExpiration() {
        guard userData.isActiveMember,
              let endDate = userData.subscription.endDate else { return }
        
        if Date() > endDate {
            // 订阅过期，恢复为非订阅用户
            userData.userType = .nonSubscriber
            userData.subscription.plan = nil
            userData.subscription.endDate = nil
            // 清空订阅积分，保留充值积分
            userData.credits.subscriptionCredits = 0
            saveUserData()
            showToast(message: "Your subscription has expired", type: .warning)
        }
    }
    
    // MARK: - Credits Management
    func deductCredits(_ amount: Int) -> Bool {
        guard userData.credits.totalCredits >= amount else { return false }
        
        var remaining = amount
        
        // Deduct from subscription credits first
        if userData.credits.subscriptionCredits > 0 {
            let deduction = min(userData.credits.subscriptionCredits, remaining)
            userData.credits.subscriptionCredits -= deduction
            remaining -= deduction
        }
        
        // Deduct from recharge credits if needed
        if remaining > 0 && userData.credits.rechargeCredits > 0 {
            userData.credits.rechargeCredits -= remaining
        }
        
        userData.credits.usedCredits += amount
        
        // Add transaction
        let transaction = Transaction(
            id: UUID().uuidString,
            type: .usage,
            description: "Project Generation",
            amount: amount,
            date: Date(),
            creditsChange: -amount
        )
        userData.transactionHistory.insert(transaction, at: 0)
        
        saveUserData()
        return true
    }
    
    func reserveGenerationCredits(_ amount: Int) -> Bool {
        guard userData.credits.totalCredits >= amount else { return false }
        pendingGenerationCredits = amount
        return true
    }
    
    func consumePendingGenerationCredits() -> Int? {
        guard let amount = pendingGenerationCredits else { return nil }
        guard deductCredits(amount) else { return nil }
        pendingGenerationCredits = nil
        isGenerationInProgress = false
        generationProgress = 1.0
        return amount
    }
    
    func cancelPendingGenerationCredits() {
        pendingGenerationCredits = nil
        isGenerationInProgress = false
        generationProgress = 0.0
    }
    
    func addCredits(_ amount: Int, type: Transaction.TransactionType, description: String, subscriptionEndDate: Date? = nil, subscriptionPlan: SubscriptionPlan? = nil) {
        if type == .subscription {
            userData.credits.subscriptionCredits += amount
            // 设置为订阅用户
            userData.userType = .subscriber
            // 设置订阅计划
            if let plan = subscriptionPlan {
                userData.subscription.plan = plan
            }
            // 只有在没有提供日期时才设置默认30天
            if let endDate = subscriptionEndDate {
                userData.subscription.endDate = endDate
            } else if userData.subscription.endDate == nil {
                userData.subscription.endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
            }
        } else {
            userData.credits.rechargeCredits += amount
        }
        
        let transaction = Transaction(
            id: UUID().uuidString,
            type: type,
            description: description,
            amount: amount,
            date: Date(),
            creditsChange: amount
        )
        userData.transactionHistory.insert(transaction, at: 0)
        
        saveUserData()
    }
    
    func activateFreeTrial() -> Bool {
        guard !userData.subscription.hasUsedFreeTrial else {
            return false
        }
        
        // 赠送1天试用时间和200试用积分
        let trialCredits = 200
        userData.credits.subscriptionCredits += trialCredits
        userData.subscription.endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        userData.subscription.hasUsedFreeTrial = true
        // 设置为试用用户
        userData.userType = .trialUser
        userData.subscription.plan = nil  // 试用用户没有订阅计划
        
        // 添加交易记录
        let transaction = Transaction(
            id: UUID().uuidString,
            type: .subscription,
            description: "Free Trial",
            amount: trialCredits,
            date: Date(),
            creditsChange: trialCredits
        )
        userData.transactionHistory.insert(transaction, at: 0)
        
        saveUserData()
        return true
    }
    
    // MARK: - Projects
    func loadProjects() {
        if let data = userDefaults.data(forKey: "projects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }
    
    func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            userDefaults.set(encoded, forKey: "projects")
        }
    }
    
    func addProject(_ project: Project) {
        projects.insert(project, at: 0)
        saveProjects()
    }
    
    func deleteProject(_ id: String) {
        projects.removeAll { $0.id == id }
        saveProjects()
    }
    
    // MARK: - Selected Photos
    func loadSelectedPhotos() {
        // 确保照片目录存在
        try? FileManager.default.createDirectory(at: AppViewModel.photosDirectory, withIntermediateDirectories: true, attributes: nil)
        
        // 只加载元数据（文件路径），不加载实际图片数据
        if let data = userDefaults.data(forKey: "selectedPhotos"),
           let decoded = try? JSONDecoder().decode([SelectedPhoto].self, from: data) {
            // 验证文件是否仍然存在
            selectedPhotos = decoded.filter { photo in
                guard let filePath = photo.filePath else { return false }
                let url = AppViewModel.photosDirectory.appendingPathComponent(filePath)
                return FileManager.default.fileExists(atPath: url.path)
            }
            // 如果文件被删除，更新 UserDefaults
            if selectedPhotos.count != decoded.count {
                saveSelectedPhotos()
            }
        }
    }
    
    func saveSelectedPhotos() {
        // 只保存元数据（文件路径），不保存实际图片数据
        // 创建一个轻量级的副本用于序列化
        let photosMetadata = selectedPhotos.map { photo in
            SelectedPhoto(id: photo.id, filePath: photo.filePath, imageUrl: photo.imageUrl, alt: photo.alt)
        }
        if let encoded = try? JSONEncoder().encode(photosMetadata) {
            // 检查数据大小，如果仍然过大，可能还有其他数据问题
            if encoded.count < 4 * 1024 * 1024 { // 4MB limit
                userDefaults.set(encoded, forKey: "selectedPhotos")
            } else {
                print("Warning: Selected photos metadata is still too large: \(encoded.count) bytes")
                // 尝试清理一些数据或提示用户
            }
        }
    }
    
    func addSelectedPhoto(_ photo: SelectedPhoto) {
        // 如果 photo 已经有 filePath，直接添加
        if photo.filePath != nil {
            selectedPhotos.append(photo)
            saveSelectedPhotos()
        } else {
            // 如果没有 filePath，说明这是一个新照片，需要通过 addSelectedPhoto(imageData:) 方法添加
            print("Warning: SelectedPhoto without filePath. Use addSelectedPhoto(imageData:) instead.")
        }
    }
    
    // 添加新照片（从图片数据）
    func addSelectedPhoto(imageData: Data, id: String? = nil) {
        let photoId = id ?? UUID().uuidString
        let fileName = "\(photoId).jpg"
        let url = AppViewModel.photosDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.createDirectory(at: AppViewModel.photosDirectory, withIntermediateDirectories: true, attributes: nil)
            try imageData.write(to: url)
            // 创建新的 photo 对象，包含文件路径
            let photo = SelectedPhoto(id: photoId, filePath: fileName)
            selectedPhotos.append(photo)
            saveSelectedPhotos()
        } catch {
            print("Failed to save image to file system: \(error)")
            showToast(message: "Failed to save photo", type: .error)
        }
    }
    
    // 从文件路径加载图片数据
    func imageData(for photo: SelectedPhoto) -> Data? {
        guard let filePath = photo.filePath else { return nil }
        let url = AppViewModel.photosDirectory.appendingPathComponent(filePath)
        return try? Data(contentsOf: url)
    }
    
    func removeSelectedPhoto(_ id: String) {
        // 删除文件系统中的图片文件
        if let photo = selectedPhotos.first(where: { $0.id == id }),
           let filePath = photo.filePath {
            let url = AppViewModel.photosDirectory.appendingPathComponent(filePath)
            try? FileManager.default.removeItem(at: url)
        }
        selectedPhotos.removeAll { $0.id == id }
        saveSelectedPhotos()
    }
    
    func clearSelectedPhotos() {
        // 删除所有照片文件
        for photo in selectedPhotos {
            if let filePath = photo.filePath {
                let url = AppViewModel.photosDirectory.appendingPathComponent(filePath)
                try? FileManager.default.removeItem(at: url)
            }
        }
        selectedPhotos = []
        saveSelectedPhotos()
    }
    
    // MARK: - Current Session Projects
    func loadCurrentSessionProjects() {
        if let data = userDefaults.data(forKey: "currentSessionProjects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            currentSessionProjects = decoded
            if decoded.contains(where: { $0.status == .generating }) {
                isGenerationInProgress = true
                let progressValues = decoded.map(\.progress)
                if let maxProgress = progressValues.max(), maxProgress > 0 {
                    generationProgress = maxProgress
                } else {
                    let total = Double(decoded.count)
                    if total > 0 {
                        let completed = Double(decoded.filter { $0.status == .completed }.count)
                        generationProgress = completed / total
                    } else {
                        generationProgress = 0.0
                    }
                }
            } else {
                isGenerationInProgress = false
                generationProgress = 0.0
            }
        } else {
            currentSessionProjects = []
            isGenerationInProgress = false
            generationProgress = 0.0
        }
    }
    
    func saveCurrentSessionProjects() {
        if let encoded = try? JSONEncoder().encode(currentSessionProjects) {
            userDefaults.set(encoded, forKey: "currentSessionProjects")
        }
    }
    
    // MARK: - Clear All Data
    func clearAllUserData() {
        // Reset user data
        userData = UserData()
        saveUserData()
        
        // Clear projects
        projects = []
        saveProjects()
        
        // Clear selected photos (including files)
        clearSelectedPhotos()
        
        // 尝试删除整个照片目录
        try? FileManager.default.removeItem(at: AppViewModel.photosDirectory)
        
        // Clear current session projects
        currentSessionProjects = []
        saveCurrentSessionProjects()
        isGenerationInProgress = false
        generationProgress = 0.0
        pendingGenerationCredits = nil
        
        // Reset templates
        presetTemplates = AppViewModel.defaultPresetTemplates()
        customTemplates = []
        saveTemplates(for: .preset)
        saveTemplates(for: .custom)
        
        // Remove from UserDefaults
        userDefaults.removeObject(forKey: "userData")
        userDefaults.removeObject(forKey: "projects")
        userDefaults.removeObject(forKey: "selectedPhotos")
        userDefaults.removeObject(forKey: "currentSessionProjects")
        userDefaults.removeObject(forKey: presetTemplatesKey)
        userDefaults.removeObject(forKey: customTemplatesKey)
        
        showToast(message: "All user data cleared", type: .success)
    }
    
    // MARK: - Toast
    func showToast(message: String, type: ToastType = .info) {
        toastMessage = message
        toastType = type
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showToast = false
        }
    }
}

