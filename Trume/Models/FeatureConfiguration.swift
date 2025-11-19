//
//  FeatureConfiguration.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import Foundation

struct FeatureConfiguration: Codable {
    // MARK: - Home Page Configuration
    struct HomePageConfig: Codable {
        var showNotificationButton: Bool = false
        var showSettingsButton: Bool = false
        var maxPhotoSelectionCount: Int = 10
    }
    
    // MARK: - Portfolio Generation Configuration
    struct PortfolioGenerationConfig: Codable {
        var maxTrainingPollingAttempts: Int = 60
        var trainingPollingInterval: TimeInterval = 10.0
        var maxPollingAttempts: Int = 30
        var pollingInterval: TimeInterval = 5.0
    }
    
    // MARK: - User Credits Page Configuration
    struct UserCreditsPageConfig: Codable {
        var showClearDataButton: Bool = false
        var showManageSubscriptionButton: Bool = false
        var showTransactionHistoryButton: Bool = false
    }
    
    // MARK: - Subscription Page Configuration
    struct SubscriptionPageConfig: Codable {
        var showFreeTrial: Bool = false
        var showBasicPlan: Bool = true
        var showPremiumPlan: Bool = false
        var enablePaymentProcessing: Bool = true
    }
    
    var homePage: HomePageConfig = HomePageConfig()
    var portfolioGeneration: PortfolioGenerationConfig = PortfolioGenerationConfig()
    var userCreditsPage: UserCreditsPageConfig = UserCreditsPageConfig()
    var subscriptionPage: SubscriptionPageConfig = SubscriptionPageConfig()
    
    // MARK: - Default Configuration
    static var `default`: FeatureConfiguration {
        FeatureConfiguration()
    }
}

