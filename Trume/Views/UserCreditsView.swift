//
//  UserCreditsView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct UserCreditsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showPurchase: Bool = false
    @State private var showSubscription: Bool = false
    @State private var showClearDataAlert: Bool = false
    @State private var showTransactionHistory: Bool = false
    
    var userTypeLabel: String {
        switch viewModel.userData.userType {
        case .trialUser:
            return "Trial User"
        case .subscriber:
            if let plan = viewModel.userData.subscription.plan {
                return plan == .premium ? "Premium Member" : "Basic Member"
            }
            return "Subscriber"
        case .nonSubscriber:
            return "Free Member"
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.039, blue: 0.039)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Plans & Credits",
                    showBackButton: true,
                    trailingButtons: [
                        NavigationBarButton(id: "purchase", icon: "plus.circle") {
                            showPurchase = true
                        }
                    ],
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Credits Balance Card
                        VStack(spacing: 16) {
                            Text("Available Credits")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                            
                            Text("\(viewModel.userData.credits.totalCredits)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            if viewModel.userData.isActiveMember {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                    Text(userTypeLabel)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.51, green: 0.28, blue: 0.9).opacity(0.2))
                                .cornerRadius(20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.51, green: 0.28, blue: 0.9).opacity(0.3), Color(red: 0.83, green: 0.2, blue: 1.0).opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Credit Breakdown
                        CreditBreakdownCard(
                            subscriptionCredits: viewModel.userData.credits.subscriptionCredits,
                            rechargeCredits: viewModel.userData.credits.rechargeCredits,
                            totalCredits: viewModel.userData.credits.totalCredits,
                            isActive: viewModel.userData.isActiveMember,
                            onAddCredits: {
                                if viewModel.userData.isActiveMember {
                                    showPurchase = true
                                } else {
                                    viewModel.showToast(message: "Please subscribe first to add credits", type: .warning)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        showSubscription = true
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 16)

                        // Subscription Status / Plans
                        SubscriptionStatusCard(
                            isActive: viewModel.userData.isActiveMember,
                            endDate: viewModel.userData.subscription.endDate,
                            subscriptionPlan: viewModel.userData.subscription.plan,
                            userType: viewModel.userData.userType,
                            onManageOrSubscribe: { showSubscription = true }
                        )
                        .padding(.horizontal, 16)
                        
                        // Transaction History Button
                        Button(action: {
                            showTransactionHistory = true
                        }) {
                            HStack {
                                Text("View Transaction History")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(16)
                            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 16)
                        
                        // Clear Data Button
                        Button(action: {
                            showClearDataAlert = true
                        }) {
                            Text("Clear All Data")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showPurchase) {
            NavigationView {
                CreditPurchaseView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
        .sheet(isPresented: $showSubscription) {
            NavigationView {
                SubscriptionView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
        .sheet(isPresented: $showTransactionHistory) {
            NavigationView {
                TransactionHistoryView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
        .alert("Clear All Data", isPresented: $showClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearAllUserData()
            }
        } message: {
            Text("This will permanently delete all your data including credits, projects, photos, and transaction history. This action cannot be undone.")
        }
    }
}

private struct CreditBreakdownCard: View {
    let subscriptionCredits: Int
    let rechargeCredits: Int
    let totalCredits: Int
    let isActive: Bool
    let onAddCredits: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Credits")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    HStack {
                        Circle().fill(Color(red: 0.51, green: 0.28, blue: 0.9)).frame(width: 6, height: 6)
                        Text("Subscription Credits")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    Spacer()
                    Text("\(subscriptionCredits)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                HStack {
                    HStack {
                        Circle().fill(Color(red: 0.83, green: 0.2, blue: 1.0)).frame(width: 6, height: 6)
                        Text("Recharge Credits")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    Spacer()
                    Text("\(rechargeCredits)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Text("Total Credits")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(totalCredits)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Button(action: onAddCredits) {
                Text("Purchase More Credits")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(red: 0.098, green: 0.098, blue: 0.098))
        .cornerRadius(16)
    }
}

private struct SubscriptionStatusCard: View {
    let isActive: Bool
    let endDate: Date?
    let subscriptionPlan: SubscriptionPlan?
    let userType: UserType
    let onManageOrSubscribe: () -> Void
    
    var statusText: String {
        switch userType {
        case .trialUser:
            return "Trial"
        case .subscriber:
            return "Active"
        case .nonSubscriber:
            return "Inactive"
        }
    }
    
    var statusColor: Color {
        switch userType {
        case .trialUser:
            return Color(red: 0.83, green: 0.2, blue: 1.0)  // 紫色表示试用
        case .subscriber:
            return Color(red: 0.2, green: 0.78, blue: 0.35)  // 绿色表示活跃订阅
        case .nonSubscriber:
            return .white.opacity(0.7)
        }
    }
    
    var planName: String {
        if let plan = subscriptionPlan {
            return plan == .premium ? "Premium Plan" : "Basic Plan"
        }
        if userType == .trialUser {
            return "Free Trial"
        }
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subscription")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(999)
            }
            
            if isActive, let endDate {
                VStack(spacing: 8) {
                    if !planName.isEmpty {
                        HStack {
                            Text("Plan")
                                .foregroundColor(Color.white.opacity(0.6))
                                .font(.system(size: 14))
                            Spacer()
                            Text(planName)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    HStack {
                        Text("End Date")
                            .foregroundColor(Color.white.opacity(0.6))
                            .font(.system(size: 14))
                        Spacer()
                        Text(formatDate(endDate))
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                    HStack {
                        Text("Days Remaining")
                            .foregroundColor(Color.white.opacity(0.6))
                            .font(.system(size: 14))
                        Spacer()
                        Text("\(daysRemaining(until: endDate))")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                }
            } else {
                Text("Subscribe to get monthly credits and premium features")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            Button(action: onManageOrSubscribe) {
                Text(isActive ? "Manage Subscription" : "Subscribe Now")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(red: 0.098, green: 0.098, blue: 0.098))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func daysRemaining(until date: Date) -> Int {
        let now = Date()
        let days = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
        return max(0, days)
    }
}

