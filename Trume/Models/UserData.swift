//
//  UserData.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import Foundation

enum UserType: String, Codable {
    case nonSubscriber = "nonSubscriber"      // 非订阅用户（默认）
    case trialUser = "trialUser"              // 试用用户
    case subscriber = "subscriber"           // 订阅用户
}

enum SubscriptionPlan: String, Codable {
    case basic = "basic"                     // Basic Plan
    case premium = "premium"                  // Premium Plan
    
    // MARK: - Display Properties
    
    var title: String {
        switch self {
        case .basic: return "Basic"
        case .premium: return "Premium"
        }
    }
    
    var price: String {
        switch self {
        case .basic: return "$4.99/week"
        case .premium: return "$19.99/month"
        }
    }
    
    var credits: Int {
        switch self {
        case .basic: return 500
        case .premium: return 2000
        }
    }
    
    var period: String {
        switch self {
        case .basic: return "week"
        case .premium: return "month"
        }
    }
    
    // 订阅周期对应的天数
    var periodDays: Int {
        switch self {
        case .basic: return 7
        case .premium: return 30
        }
    }
}

// MARK: - Subscription Information
struct SubscriptionInfo: Codable {
    var plan: SubscriptionPlan?
    var endDate: Date?
    var hasUsedFreeTrial: Bool = false
    
    var isActive: Bool {
        guard let endDate = endDate else { return false }
        return Date() <= endDate
    }
    
    var daysRemaining: Int? {
        guard let endDate = endDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return components.day
    }
}

// MARK: - Credits Information
struct CreditsInfo: Codable {
    var subscriptionCredits: Int = 0  // 订阅获得的积分
    var rechargeCredits: Int = 0     // 充值购买的积分
    var usedCredits: Int = 0          // 已使用的积分
    
    // 计算属性：总可用积分
    var totalCredits: Int {
        return subscriptionCredits + rechargeCredits
    }
    
    // 计算属性：可用积分（与 totalCredits 相同，保持语义清晰）
    var availableCredits: Int {
        return totalCredits
    }
}

struct UserData: Codable {
    // 用户类型信息
    var userType: UserType = .nonSubscriber
    
    // 订阅信息
    var subscription: SubscriptionInfo = SubscriptionInfo()
    
    // 积分信息
    var credits: CreditsInfo = CreditsInfo()
    
    // 交易历史
    var transactionHistory: [Transaction] = []
    
    // MARK: - Computed Properties
    
    // 是否为活跃会员（订阅用户或试用用户）
    var isActiveMember: Bool {
        return userType == .subscriber || userType == .trialUser
    }
    
    // 是否为订阅用户（不包括试用用户）
    var isSubscriber: Bool {
        return userType == .subscriber
    }
    
    // 是否为试用用户
    var isTrialUser: Bool {
        return userType == .trialUser
    }
    
    // 订阅是否有效（检查日期）
    var hasActiveSubscription: Bool {
        return subscription.isActive && isActiveMember
    }
}

struct Transaction: Codable, Identifiable {
    let id: String
    let type: TransactionType
    let description: String
    let amount: Int
    let date: Date
    let creditsChange: Int
    
    enum TransactionType: String, Codable {
        case purchase
        case usage
        case subscription
    }
}

struct Project: Codable, Identifiable {
    let id: String
    let imageUrl: String
    let style: ProjectStyle
    let status: ProjectStatus
    let createdAt: Date
    let progress: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl
        case style
        case status
        case createdAt
        case progress
    }
    
    init(
        id: String = UUID().uuidString,
        imageUrl: String,
        style: ProjectStyle,
        status: ProjectStatus,
        createdAt: Date = Date(),
        progress: Double = 0.0
    ) {
        self.id = id
        self.imageUrl = imageUrl
        self.style = style
        self.status = status
        self.createdAt = createdAt
        self.progress = progress
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        style = try container.decode(ProjectStyle.self, forKey: .style)
        status = try container.decode(ProjectStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(style, forKey: .style)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(progress, forKey: .progress)
    }
    
    enum ProjectStatus: String, Codable {
        case generating
        case completed
    }
}

struct ProjectStyle: Codable {
    let name: String
    let filter: String
}

struct SelectedPhoto: Codable, Identifiable {
    let id: String
    let filePath: String?  // 文件系统路径，替代 imageData
    let imageUrl: String?
    let alt: String?
    
    // 不再直接存储 imageData，而是存储文件路径
    // imageData 作为计算属性从文件系统加载
    var imageData: Data? {
        guard let filePath = filePath else { return nil }
        let url = AppViewModel.photosDirectory.appendingPathComponent(filePath)
        return try? Data(contentsOf: url)
    }
    
    init(id: String = UUID().uuidString, imageData: Data? = nil, imageUrl: String? = nil, alt: String? = nil) {
        self.id = id
        self.imageUrl = imageUrl
        self.alt = alt
        self.filePath = nil  // 文件路径将由 AppViewModel 在保存时设置
        // imageData 参数用于临时存储，实际保存由 AppViewModel.addSelectedPhoto 处理
    }
    
    // 用于从已存在的文件路径创建（从 UserDefaults 加载时使用）
    init(id: String, filePath: String?, imageUrl: String? = nil, alt: String? = nil) {
        self.id = id
        self.filePath = filePath
        self.imageUrl = imageUrl
        self.alt = alt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case filePath
        case imageUrl
        case alt
    }
}

