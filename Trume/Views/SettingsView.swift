//
//  SettingsView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var config: FeatureConfiguration
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        _config = State(initialValue: viewModel.featureConfig)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.039, blue: 0.039)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Settings",
                    showBackButton: true,
                    trailingButtons: [
                        NavigationBarButton(id: "save", icon: "checkmark") {
                            saveConfiguration()
                        }
                    ],
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Home Page Section
                        ConfigurationSection(
                            title: "Home Page",
                            icon: "house.fill"
                        ) {
                            VStack(spacing: 16) {
                                // Notification Button Toggle
                                ConfigurationToggleRow(
                                    title: "Notification Button",
                                    description: "Show/hide notification button in navigation bar",
                                    isOn: Binding(
                                        get: { config.homePage.showNotificationButton },
                                        set: { config.homePage.showNotificationButton = $0 }
                                    )
                                )
                                
                                // Settings Button Toggle
                                ConfigurationToggleRow(
                                    title: "Settings Button",
                                    description: "Show/hide settings button in navigation bar",
                                    isOn: Binding(
                                        get: { config.homePage.showSettingsButton },
                                        set: { config.homePage.showSettingsButton = $0 }
                                    )
                                )
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                // Photo Selection Limit
                                ConfigurationStepperRow(
                                    title: "Max Photo Selection",
                                    description: "Maximum number of photos that can be selected",
                                    value: Binding(
                                        get: { config.homePage.maxPhotoSelectionCount },
                                        set: { config.homePage.maxPhotoSelectionCount = $0 }
                                    ),
                                    range: 1...20
                                )
                            }
                        }
                        
                        // Portfolio Generation Section
                        ConfigurationSection(
                            title: "Portfolio Generation",
                            icon: "sparkles.rectangle.stack.fill"
                        ) {
                            VStack(spacing: 16) {
                                // Max Training Polling Attempts
                                ConfigurationStepperRow(
                                    title: "Max Training Polling Attempts",
                                    description: "Maximum number of attempts to poll training status",
                                    value: Binding(
                                        get: { config.portfolioGeneration.maxTrainingPollingAttempts },
                                        set: { config.portfolioGeneration.maxTrainingPollingAttempts = $0 }
                                    ),
                                    range: 1...100
                                )
                                
                                // Training Polling Interval
                                ConfigurationStepperRow(
                                    title: "Training Polling Interval (seconds)",
                                    description: "Time interval between training polling attempts",
                                    value: Binding(
                                        get: { Int(config.portfolioGeneration.trainingPollingInterval) },
                                        set: { config.portfolioGeneration.trainingPollingInterval = TimeInterval($0) }
                                    ),
                                    range: 1...60
                                )
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                // Max Polling Attempts
                                ConfigurationStepperRow(
                                    title: "Max Polling Attempts",
                                    description: "Maximum number of attempts to poll generation status",
                                    value: Binding(
                                        get: { config.portfolioGeneration.maxPollingAttempts },
                                        set: { config.portfolioGeneration.maxPollingAttempts = $0 }
                                    ),
                                    range: 1...100
                                )
                                
                                // Polling Interval
                                ConfigurationStepperRow(
                                    title: "Polling Interval (seconds)",
                                    description: "Time interval between generation polling attempts",
                                    value: Binding(
                                        get: { Int(config.portfolioGeneration.pollingInterval) },
                                        set: { config.portfolioGeneration.pollingInterval = TimeInterval($0) }
                                    ),
                                    range: 1...60
                                )
                            }
                        }
                        
                        // User Credits Page Section
                        ConfigurationSection(
                            title: "User Credits Page",
                            icon: "creditcard.fill"
                        ) {
                            VStack(spacing: 16) {
                                // Clear Data Button Toggle
                                ConfigurationToggleRow(
                                    title: "Clear Data Button",
                                    description: "Show/hide clear all data button",
                                    isOn: Binding(
                                        get: { config.userCreditsPage.showClearDataButton },
                                        set: { config.userCreditsPage.showClearDataButton = $0 }
                                    )
                                )
                                
                                // Manage Subscription Button Toggle
                                ConfigurationToggleRow(
                                    title: "Manage Subscription Button",
                                    description: "Show/hide manage subscription button",
                                    isOn: Binding(
                                        get: { config.userCreditsPage.showManageSubscriptionButton },
                                        set: { config.userCreditsPage.showManageSubscriptionButton = $0 }
                                    )
                                )
                                
                                // Transaction History Button Toggle
                                ConfigurationToggleRow(
                                    title: "Transaction History Button",
                                    description: "Show/hide transaction history button",
                                    isOn: Binding(
                                        get: { config.userCreditsPage.showTransactionHistoryButton },
                                        set: { config.userCreditsPage.showTransactionHistoryButton = $0 }
                                    )
                                )
                            }
                        }
                        
                        // Subscription Page Section
                        ConfigurationSection(
                            title: "Subscription Page",
                            icon: "star.fill"
                        ) {
                            VStack(spacing: 16) {
                                // Free Trial Toggle
                                ConfigurationToggleRow(
                                    title: "Free Trial Option",
                                    description: "Show/hide free trial option in subscription page",
                                    isOn: Binding(
                                        get: { config.subscriptionPage.showFreeTrial },
                                        set: { config.subscriptionPage.showFreeTrial = $0 }
                                    )
                                )
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                // Basic Plan Toggle
                                ConfigurationToggleRow(
                                    title: "Basic Plan",
                                    description: "Show/hide Basic subscription plan",
                                    isOn: Binding(
                                        get: { config.subscriptionPage.showBasicPlan },
                                        set: { config.subscriptionPage.showBasicPlan = $0 }
                                    )
                                )
                                
                                // Premium Plan Toggle
                                ConfigurationToggleRow(
                                    title: "Premium Plan",
                                    description: "Show/hide Premium subscription plan",
                                    isOn: Binding(
                                        get: { config.subscriptionPage.showPremiumPlan },
                                        set: { config.subscriptionPage.showPremiumPlan = $0 }
                                    )
                                )
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                // Payment Processing Toggle
                                ConfigurationToggleRow(
                                    title: "Enable Payment Processing",
                                    description: "If enabled, calls real payment. If disabled, skips payment and directly processes subscription.",
                                    isOn: Binding(
                                        get: { config.subscriptionPage.enablePaymentProcessing },
                                        set: { config.subscriptionPage.enablePaymentProcessing = $0 }
                                    )
                                )
                            }
                        }
                        
                        // Reset Button
                        Button(action: {
                            resetToDefaults()
                        }) {
                            Text("Reset to Defaults")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
        }
    }
    
    private func saveConfiguration() {
        viewModel.featureConfig = config
        viewModel.saveFeatureConfiguration()
        viewModel.showToast(message: "Settings saved successfully", type: .success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func resetToDefaults() {
        config = .default
        viewModel.showToast(message: "Settings reset to defaults", type: .info)
    }
}

// MARK: - Configuration Section Component
struct ConfigurationSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.83, green: 0.2, blue: 1.0))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            VStack(spacing: 0) {
                content
                    .padding(16)
            }
            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Configuration Toggle Row
struct ConfigurationToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.83, green: 0.2, blue: 1.0))
        }
    }
}

// MARK: - Configuration Stepper Row
struct ConfigurationStepperRow: View {
    let title: String
    let description: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                Spacer()
                HStack(spacing: 12) {
                    Button(action: {
                        if value > range.lowerBound {
                            value -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(value > range.lowerBound ? Color(red: 0.83, green: 0.2, blue: 1.0) : Color.gray)
                    }
                    .disabled(value <= range.lowerBound)
                    
                    Text("\(value)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 50)
                    
                    Button(action: {
                        if value < range.upperBound {
                            value += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(value < range.upperBound ? Color(red: 0.83, green: 0.2, blue: 1.0) : Color.gray)
                    }
                    .disabled(value >= range.upperBound)
                }
            }
        }
    }
}

