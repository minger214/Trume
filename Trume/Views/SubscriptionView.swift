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
    @State private var isRestoringPurchases: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var currentImageIndex: Int = 0
    @State private var carouselTimer: Timer?
    
    var hasUsedFreeTrial: Bool {
        viewModel.userData.subscription.hasUsedFreeTrial
    }
    
    var selectedProductID: String {
        switch selectedPlan {
        case .basic:
            return "com.trume.plan.weekly.basic"
        case .premium:
            return "com.trume.plan.weekly.premium"
        }
    }
    
    var hasAvailablePlans: Bool {
        viewModel.featureConfig.subscriptionPage.showBasicPlan || viewModel.featureConfig.subscriptionPage.showPremiumPlan
    }

    private let backgroundColor = Color(red: 0.035, green: 0.039, blue: 0.039)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "",
                    leadingButtons: [
                        NavigationBarButton.close {
                            presentationMode.wrappedValue.dismiss()
                        }
                    ],
                    trailingButtons: buildTrailingButtons()
                )
                
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trume - AI Photo Generator")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Generate realistic portrait effects.")
                                .font(.system(size: 20))
                                .foregroundColor(Color.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 16)
                        
                        // Image Carousel
                        ImageCarouselView(currentIndex: $currentImageIndex)
                            .frame(height: 300)
                            .padding(.horizontal, 16)
                            .zIndex(1)
                            .padding(.bottom, 8)
                        
                        // Plans
                        VStack(spacing: 16) {
                            if viewModel.featureConfig.subscriptionPage.showBasicPlan {
                                PlanCard(
                                    plan: .basic,
                                    isSelected: selectedPlan == .basic,
                                    storeKitManager: storeKitManager
                                ) {
                                    selectedPlan = .basic
                                }
                            }
                            
                            if viewModel.featureConfig.subscriptionPage.showPremiumPlan {
                                PlanCard(
                                    plan: .premium,
                                    isSelected: selectedPlan == .premium,
                                    storeKitManager: storeKitManager
                                ) {
                                    selectedPlan = .premium
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Free Trial Toggle
                        if viewModel.featureConfig.subscriptionPage.showFreeTrial {
                            HStack(spacing: 12) {
                                Text(hasUsedFreeTrial ? "Free Trial Enabled" : "Free Trial Enabled")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(hasUsedFreeTrial ? Color.white.opacity(0.5) : .white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $showFreeTrial)
                                    .tint(Color.gray.opacity(0.2))
                                    .disabled(hasUsedFreeTrial)
                                    .labelsHidden()
                            }
                            .padding(16)
                            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        hasUsedFreeTrial ? Color.white.opacity(0.2) : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        Spacer()
                    }
                }
                .overlay(alignment: .bottom) {
                    // Bottom Layer: Continue Button, Notice, and Terms Links
                    VStack(spacing: 0) {
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
                                        .foregroundColor(.black)
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .disabled(isProcessingPayment || !hasAvailablePlans)
                        .opacity((isProcessingPayment || !hasAvailablePlans) ? 0.7 : 1.0)
                        .padding(.horizontal, 16)
                        
                        // Notice
                        Text("You can cancel your subscription anytime.")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 16)
                        
                        // Terms Links
                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "#")!)
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.5))
                            
                            Text("|")
                                .foregroundColor(.white.opacity(0.2))
                            
                            Link("Terms of Use", destination: URL(string: "#")!)
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                    .background(backgroundColor)
                }
            }
        }
        .onAppear {
            // 根据配置调整默认选中的计划
            let showBasic = viewModel.featureConfig.subscriptionPage.showBasicPlan
            let showPremium = viewModel.featureConfig.subscriptionPage.showPremiumPlan
            
            if !showBasic && showPremium {
                // 如果 basic 被隐藏，默认选中 premium
                selectedPlan = .premium
            } else if showBasic && !showPremium {
                // 如果 premium 被隐藏，默认选中 basic
                selectedPlan = .basic
            } else if !showBasic && !showPremium {
                // 如果两个都被隐藏，显示警告
                viewModel.showToast(message: "No subscription plans available", type: .warning)
            }
            // 如果两个都显示，保持默认的 premium
            
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
    
    private func buildTrailingButtons() -> [NavigationBarButton] {
        var buttons: [NavigationBarButton] = []
        
        // Restore Purchases Button
        if viewModel.featureConfig.subscriptionPage.showRestorePurchasesButton {
            if #available(iOS 15.0, *) {
                buttons.append(
                    NavigationBarButton(id: "restore", icon: "arrow.clockwise") {
                        restorePurchases()
                    }
                )
            }
        }
        
        return buttons
    }
    
    @available(iOS 15.0, *)
    private func restorePurchases() {
        Task {
            isRestoringPurchases = true
            viewModel.showToast(message: "Restoring purchases...", type: .info)
            
            if storeKitManager == nil {
                storeKitManager = StoreKitManager()
            }
            
            do {
                try await storeKitManager?.restorePurchases()
                await storeKitManager?.updatePurchasedProducts()
                
                // 检查恢复的订阅并更新用户数据
                await checkRestoredSubscriptions()
                
                isRestoringPurchases = false
                viewModel.showToast(message: "Purchases restored successfully", type: .success)
            } catch {
                isRestoringPurchases = false
                let errorMessage = (error as? StoreError)?.errorDescription ?? error.localizedDescription
                viewModel.showToast(message: "Restore failed: \(errorMessage)", type: .error)
            }
        }
    }
    
    @available(iOS 15.0, *)
    @MainActor
    private func checkRestoredSubscriptions() async {
        guard let storeKitManager = storeKitManager else { return }
        
        // 检查自动续费订阅
        let subscriptionProductIDs = [
            "com.trume.plan.weekly.basic"
            // "com.trume.plan.weekly.premium"
        ]
        
        for productID in subscriptionProductIDs {
            guard storeKitManager.isPurchased(productID: productID),
                  let expirationDate = await storeKitManager.subscriptionExpirationDate(for: productID) else {
                continue
            }
            
            // 确定订阅计划
            let plan: SubscriptionPlan = productID.contains("basic") ? .basic : .premium
            
            guard viewModel.shouldApplySubscriptionReward(plan: plan, newEndDate: expirationDate) else {
                continue
            }
            
            viewModel.addCredits(
                plan.credits,
                type: .subscription,
                description: "\(plan.title) Subscription Restore",
                subscriptionEndDate: expirationDate,
                subscriptionPlan: plan
            )
        }
    }
    
    private func handleSubscription() {
        // 检查是否有可用计划
        guard hasAvailablePlans else {
            viewModel.showToast(message: "No subscription plans available", type: .warning)
            return
        }
        
        // 如果选中了免费试用且用户未使用过
        if showFreeTrial && !hasUsedFreeTrial {
            if viewModel.activateFreeTrial() {
                viewModel.showToast(
                    message: "Free trial activated!",
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
        
        // 处理付费订阅 - 根据配置决定是否调用支付
        if #available(iOS 15.0, *) {
            Task { @MainActor in
                if viewModel.featureConfig.subscriptionPage.enablePaymentProcessing {
                    // 配置为有效，正常调用支付流程
                    await processPayment()
                } else {
                    // 配置为无效，直接调用成功处理（跳过支付）
                    isProcessingPayment = true
                    viewModel.showToast(message: "Processing subscription...", type: .info)
                    await handlePaymentSuccess()
                }
            }
        } else {
            viewModel.showToast(message: "In-app purchases require iOS 15+.", type: .warning)
        }
    }
    
    @available(iOS 15.0, *)
    private func processPayment() async {
        isProcessingPayment = true
        viewModel.showToast(message: "Loading payment options...", type: .info)
        
        // 确保 StoreKitManager 已初始化
        if storeKitManager == nil {
            storeKitManager = StoreKitManager()
        }
        
        guard let storeKitManager = storeKitManager else {
            isProcessingPayment = false
            viewModel.showToast(
                message: "Failed to initialize payment system. Please try again.",
                type: .error
            )
            return
        }
        
        // 确保产品已加载
        if storeKitManager.products.isEmpty {
            await storeKitManager.loadProducts()
        }
        
        // 检查产品是否已加载
        if storeKitManager.products.isEmpty {
            isProcessingPayment = false
            viewModel.showToast(
                message: "No products available. Please check your internet connection and try again.",
                type: .error
            )
            return
        }
        
        // 获取选中的产品
        guard let product = storeKitManager.product(for: selectedProductID) else {
            isProcessingPayment = false
            let availableIDs = storeKitManager.products.map { $0.id }.joined(separator: ", ")
            print("Selected product ID: \(selectedProductID)")
            print("Available product IDs: \(availableIDs)")
            viewModel.showToast(
                message: "Product '\(selectedProductID)' not found. Available: \(availableIDs.isEmpty ? "none" : availableIDs)",
                type: .error
            )
            return
        }
        
        // 调用支付
        do {
            viewModel.showToast(message: "Opening payment...", type: .info)
            let transaction = try await storeKitManager.purchase(product)
            
            if let transaction = transaction {
                // 支付成功 - 从交易中获取到期日期（如果是自动续费订阅）
                var subscriptionEndDate: Date?
                
                if storeKitManager.isAutoRenewableSubscription(productID: selectedProductID) == true {
                    // 对于自动续费订阅，从交易中获取到期日期
                    subscriptionEndDate = transaction.expirationDate
                }
                
                await handlePaymentSuccess(subscriptionEndDate: subscriptionEndDate)
            } else {
                // 用户取消或支付待处理
                isProcessingPayment = false
                viewModel.showToast(message: "Payment cancelled or pending", type: .warning)
            }
        } catch {
            isProcessingPayment = false
            let errorMessage = (error as? StoreError)?.errorDescription ?? error.localizedDescription
            viewModel.showToast(
                message: "Payment failed: \(errorMessage)",
                type: .error
            )
        }
    }
    
    private func handlePaymentSuccess(subscriptionEndDate: Date? = nil) async {
        let days = selectedPlan.periodDays
        
        // 计算订阅结束日期
        let finalEndDate: Date
        if let transactionEndDate = subscriptionEndDate {
            // 使用交易中的到期日期（自动续费订阅）
            finalEndDate = transactionEndDate
        } else if let currentEndDate = viewModel.userData.subscription.endDate,
                  currentEndDate > Date() {
            // 如果已有订阅，从当前结束日期延长
            finalEndDate = Calendar.current.date(byAdding: .day, value: days, to: currentEndDate) ?? Date()
        } else {
            // 新订阅，从今天开始
            finalEndDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        }
        
        viewModel.addCredits(
            selectedPlan.credits,
            type: .subscription,
            description: "\(selectedPlan.title) Subscription",
            subscriptionEndDate: finalEndDate,
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
    let storeKitManager: StoreKitManager?
    let action: () -> Void
    @State private var product: Product?
    
    private var productID: String {
        switch plan {
        case .basic: return "com.trume.plan.weekly.basic"
        case .premium: return "com.trume.plan.weekly.premium"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                        } else {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                        }
                    }
                    Text("\(plan.title)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                }
                
                Spacer()
                
                // 显示 StoreKit 产品价格，如果可用；否则显示默认价格
                Text("\(product?.displayPrice ?? "\(plan.price)")" + "/" + "\(plan.period)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .onAppear {
            if let storeKitManager = storeKitManager {
                product = storeKitManager.product(for: productID)
            }
        }
        .onChange(of: storeKitManager?.products) {
            if let storeKitManager = storeKitManager {
                product = storeKitManager.product(for: productID)
            }
        }
    }
}

// MARK: - Image Carousel View
struct ImageCarouselView: View {
    @Binding var currentIndex: Int
    @State private var timer: Timer?
    @State private var currentScrollIndex: Int = 1 // 初始位置是真实的第一张（索引1）
    
    private let images = [
        "project-1",
        "project-2",
        "project-3",
        "project-4"
    ]
    
    private let gradientColors: [[Color]] = [
        [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
        [Color(red: 0.83, green: 0.2, blue: 1.0), Color(red: 1.0, green: 0.45, blue: 0.4)],
        [Color(red: 1.0, green: 0.45, blue: 0.4), Color(red: 0.51, green: 0.28, blue: 0.9)],
        [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.2, green: 0.78, blue: 0.35)]
    ]
    
    // 为了无缝循环，我们需要在首尾添加重复的图片
    // 结构：[最后一张] + [真实图片] + [第一张]
    // 索引：  0         1-4           5
    private var extendedImages: [String] {
        [images.last!] + images + [images.first!]
    }
    
    // 获取真实图片索引（从扩展数组索引转换为真实图片索引）
    private func realImageIndex(from scrollIndex: Int) -> Int {
        if scrollIndex == 0 {
            return images.count - 1 // 第一张的副本对应真实的最后一张
        } else if scrollIndex == extendedImages.count - 1 {
            return 0 // 最后一张的副本对应真实的第一张
        } else {
            return scrollIndex - 1 // 真实图片位置，索引减1
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            let cardSpacing: CGFloat = 16
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cardSpacing) {
                        ForEach(Array(extendedImages.enumerated()), id: \.offset) { index, imageName in
                            GeometryReader { imageGeometry in
                                // 直接基于索引距离计算缩放，更可靠
                                let indexDistance = abs(index - currentScrollIndex)
                                
                                // 缩放：当前显示的图片1.0，相邻的0.925，其他的0.85
                                let scale: CGFloat = {
                                    if indexDistance == 0 {
                                        return 1.0
                                    } else if indexDistance == 1 {
                                        return 0.925
                                    } else {
                                        return 0.85
                                    }
                                }()
                                
                                ZStack {
                                    if UIImage(named: imageName) != nil {
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        let gradientIndex = (index - 1 + images.count) % images.count
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: gradientColors[gradientIndex % gradientColors.count],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                Image(systemName: "photo.artframe")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.white.opacity(0.5))
                                            )
                                    }
                                }
                                .frame(width: cardWidth, height: geometry.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .scaleEffect(scale)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scale)
                            }
                            .frame(width: cardWidth, height: geometry.size.height)
                            .id(index)
                        }
                    }
                    .padding(.horizontal, (geometry.size.width - cardWidth) / 2)
                }
                .scrollTargetBehavior(.paging)
                .onAppear {
                    // 初始位置：显示第一张真实图片（索引1，因为索引0是最后一张的副本）
                    currentScrollIndex = 1
                    currentIndex = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(1, anchor: .center)
                        }
                        // 延迟启动定时器，确保初始动画完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            startTimer(proxy: proxy)
                        }
                    }
                }
                .onDisappear {
                    stopTimer()
                }
                .onChange(of: currentIndex) { oldValue, newValue in
                    // 当currentIndex变化时，更新滚动位置（仅用于外部控制）
                    let targetIndex = newValue + 1 // +1 因为第一个是副本
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(targetIndex, anchor: .center)
                    }
                    currentScrollIndex = targetIndex
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func startTimer(proxy: ScrollViewProxy) {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            // 一直向左滚动：索引递增
            var nextScrollIndex = currentScrollIndex + 1
            
            // 如果滚动到了最后一张的副本（索引 extendedImages.count - 1），
            // 继续滚动到第一张的副本（索引0），然后无动画跳转到真实的第一张（索引1）
            if nextScrollIndex >= extendedImages.count {
                // 滚动到了最后一张的副本之后，无动画跳转到真实的第一张
                nextScrollIndex = 1
                withAnimation(.none) {
                    proxy.scrollTo(nextScrollIndex, anchor: .center)
                }
            } else {
                // 正常滚动
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(nextScrollIndex, anchor: .center)
                }
            }
            
            currentScrollIndex = nextScrollIndex
            currentIndex = realImageIndex(from: nextScrollIndex)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

