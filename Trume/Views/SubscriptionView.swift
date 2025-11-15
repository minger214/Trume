//
//  SubscriptionView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI
#if canImport(StoreKit)
import StoreKit
#endif

struct SubscriptionView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var storeKitManager: StoreKitManager?
    @State private var selectedPlan: SubscriptionPlan = .premium
    @State private var showFreeTrial: Bool = false
    @State private var isProcessingPayment: Bool = false
    @State private var showDiagnostics: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var hasUsedFreeTrial: Bool {
        viewModel.userData.subscription.hasUsedFreeTrial
    }
    
    var selectedProductID: String {
        switch selectedPlan {
        case .basic:
            return "com.trume.basic.weekly"
        case .premium:
            return "com.trume.premium.monthly"
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.039, blue: 0.039)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Subscription Plan",
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        VStack(spacing: 16) {
                            Text("Choose Your Plan")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Unlock unlimited AI photo generation")
                                .font(.system(size: 16))
                                .foregroundColor(Color.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 16)
                        
                        // Plans
                        VStack(spacing: 16) {
                            PlanCard(
                                plan: .basic,
                                isSelected: selectedPlan == .basic
                            ) {
                                selectedPlan = .basic
                            }
                            
                            PlanCard(
                                plan: .premium,
                                isSelected: selectedPlan == .premium
                            ) {
                                selectedPlan = .premium
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Free Trial Toggle
                        if viewModel.featureConfig.subscriptionPage.showFreeTrial {
                            HStack(spacing: 12) {
                                Text(hasUsedFreeTrial ? "Free trial already used" : "Free trial enabled")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(hasUsedFreeTrial ? Color.white.opacity(0.5) : .white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $showFreeTrial)
                                    .tint(Color(red: 0.51, green: 0.28, blue: 0.9))
                                    .disabled(hasUsedFreeTrial)
                                    .labelsHidden()
                            }
                            .padding(16)
                            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        hasUsedFreeTrial ? Color.white.opacity(0.2) : Color(red: 0.51, green: 0.28, blue: 0.9).opacity(0.5),
                                        lineWidth: 1.5
                                    )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        // Terms Links
                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.51, green: 0.28, blue: 0.9))
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                            
                            Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.51, green: 0.28, blue: 0.9))
                        }
                        .padding(.top, 16)

                        
                        
                        // Continue Button
                        Button(action: {
                            handleSubscription()
                        }) {
                            HStack {
                                if isProcessingPayment {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Processing...")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
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
                        }
                        .disabled(isProcessingPayment)
                        .opacity(isProcessingPayment ? 0.7 : 1.0)
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .onAppear {
            if #available(iOS 15.0, *) {
                if storeKitManager == nil {
                    storeKitManager = StoreKitManager()
                }
                Task { await storeKitManager?.loadProducts() }
            } else {
                viewModel.showToast(message: "In-app purchases require iOS 15+.", type: .warning)
            }
        }
        
    }
    
    private func handleSubscription() {
        // 如果选中了免费试用且用户未使用过
        if showFreeTrial && !hasUsedFreeTrial {
            if viewModel.activateFreeTrial() {
                viewModel.showToast(
                    message: "Free trial activated! 1 day trial + 200 credits added.",
                    type: .success
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                viewModel.showToast(message: "Free trial already used", type: .warning)
            }
            return
        }
        
        // 处理付费订阅 - 调用支付
        Task {
            await processPayment()
        }
    }
    
    private func processPayment() async {
#if targetEnvironment(simulator)
        // Simulator does not support real in-app purchases
        viewModel.showToast(message: "In-app purchases are not available on Simulator. Please test on a real device.", type: .warning)
        await handlePaymentSuccess();
        return
#else
        isProcessingPayment = true
        viewModel.showToast(message: "Loading payment options...", type: .info)
        
        // 确保产品已加载
        if storeKitManager?.products.isEmpty ?? true {
            await storeKitManager?.loadProducts()
        }
        
        // 获取选中的产品
        guard let product = storeKitManager?.product(for: selectedProductID) else {
            isProcessingPayment = false
            viewModel.showToast(
                message: "Product not found. Please try again later.",
                type: .error
            )
            return
        }
        
        // 调用支付
        do {
            viewModel.showToast(message: "Opening payment...", type: .info)
            let transaction = try await storeKitManager?.purchase(product)
            
            if transaction != nil {
                // 支付成功
                await handlePaymentSuccess()
            } else {
                // 用户取消或支付待处理
                isProcessingPayment = false
                viewModel.showToast(message: "Payment cancelled", type: .warning)
            }
        } catch {
            isProcessingPayment = false
            viewModel.showToast(
                message: "Payment failed: \(error.localizedDescription)",
                type: .error
            )
        }
#endif
    }
    
    private func handlePaymentSuccess() async {
        let days = selectedPlan.periodDays
        
        // 计算订阅结束日期
        let subscriptionEndDate: Date
        if let currentEndDate = viewModel.userData.subscription.endDate,
           currentEndDate > Date() {
            // 如果已有订阅，从当前结束日期延长
            subscriptionEndDate = Calendar.current.date(byAdding: .day, value: days, to: currentEndDate) ?? Date()
        } else {
            // 新订阅，从今天开始
            subscriptionEndDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        }
        
        viewModel.addCredits(
            selectedPlan.credits,
            type: .subscription,
            description: "\(selectedPlan.title) Subscription",
            subscriptionEndDate: subscriptionEndDate,
            subscriptionPlan: selectedPlan
        )
        
        isProcessingPayment = false
        viewModel.showToast(
            message: "\(selectedPlan.title) subscription activated! \(selectedPlan.credits) credits/\(selectedPlan.period) added.",
            type: .success
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        if plan == .premium {
                            Text("BEST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.5, blue: 0.77), Color(red: 1.0, green: 0.43, blue: 0.44)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.price)
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text("\(plan.credits) credits/\(plan.period)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(red: 0.51, green: 0.28, blue: 0.9) : Color.white.opacity(0.3))
            }
            .padding(20)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color(red: 0.51, green: 0.28, blue: 0.9).opacity(0.2), Color(red: 0.83, green: 0.2, blue: 1.0).opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(colors: [Color(red: 0.098, green: 0.098, blue: 0.098)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(red: 0.51, green: 0.28, blue: 0.9) : Color.clear, lineWidth: 2)
            )
            .cornerRadius(16)
        }
    }
}

