//
//  CreditPurchaseView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI
#if canImport(StoreKit)
import StoreKit
#endif

struct CreditPurchaseView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedPackage: CreditPackage = .package2000
    @State private var showPurchase: Bool = false
    @State private var storeKitManager: StoreKitManager?
    @State private var isProcessingPayment: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    enum CreditPackage: CaseIterable {
        case package2000
        case package5000
        case package10000
        
        var credits: Int {
            switch self {
            case .package2000: return 2000
            case .package5000: return 5000
            case .package10000: return 10000
            }
        }
        
        var productID: String {
            switch self {
            case .package2000: return "com.trume.credits.2000"
            case .package5000: return "com.trume.credits.5000"
            case .package10000: return "com.trume.credits.10000"
            }
        }
        
        var price: String {
            switch self {
            case .package2000: return "$19.99"
            case .package5000: return "$39.99"
            case .package10000: return "$59.99"
            }
        }
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
                    ]
                )
                .zIndex(2)
                
                ZStack(alignment: .top) {
                    // 内容层
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 24) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Need more credits?")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    
                                Text("Pick an option to keep enjoying our app.")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 32)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Spacer()
                    }
                    .zIndex(1)

                    // 背景层
                    VStack(spacing: 0) {
                        // 日食效果背景
                        EllipticalArcBackground()
                            .frame(height: 350)
                            .padding(.horizontal, 16)
                        
                        Spacer()
                    }
                    .zIndex(0)
                    
                    VStack(spacing: 0) {
                        // 落日余晖背景
                        SunsetGradientBackground()
                            .frame(height: 350)
                            .padding(.horizontal, 16)
                        
                        Spacer()
                    }
                    .zIndex(0)
                }
                .overlay(alignment: .bottom) {
                    // Bottom Layer: Credit Packages, Purchase Button, Notice, and Terms Link
                    VStack(spacing: 0) {
                        // Credit Packages
                        VStack(spacing: 12) {
                            ForEach(CreditPackage.allCases, id: \.self) { package in
                                CreditPackageCard(
                                    package: package,
                                    isSelected: selectedPackage == package,
                                    storeKitManager: storeKitManager
                                ) {
                                    selectedPackage = package
                                    viewModel.showToast(
                                        message: "Selected \(package.credits) credits",
                                        type: .info
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        
                        // Purchase Button
                        Button(action: {
                            handlePurchase()
                        }) {
                            HStack {
                                if isProcessingPayment {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                    Text("Processing...")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                } else {
                                    Text("Add Credits")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .disabled(isProcessingPayment)
                        .opacity(isProcessingPayment ? 0.7 : 1.0)
                        .padding(.horizontal, 16)
                        
                        // Notice
                        Text("Easy to cancel.")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 32)
                        
                        // Terms Link
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
            if #available(iOS 15.0, *) {
                if storeKitManager == nil {
                    storeKitManager = StoreKitManager()
                }
                Task { await storeKitManager?.loadProducts() }
            }
        }
    }
    
    private func handlePurchase() {
        Task { @MainActor in
            await processPayment()
        }
    }
    
    private func processPayment() async {
        isProcessingPayment = true
        viewModel.showToast(message: "Loading payment options...", type: .info)
        
        // 确保产品已加载
        if storeKitManager?.products.isEmpty ?? true {
            await storeKitManager?.loadProducts()
        }
        
        // 获取选中的产品
        guard let product = storeKitManager?.product(for: selectedPackage.productID) else {
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
    
    private func handlePaymentSuccess() async {
        viewModel.addCredits(
            selectedPackage.credits,
            type: .purchase,
            description: "Credit Purchase - \(selectedPackage.credits) credits"
        )
        
        isProcessingPayment = false
        viewModel.showToast(
            message: "\(selectedPackage.credits) credits added successfully!",
            type: .success
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CreditPackageCard: View {
    let package: CreditPurchaseView.CreditPackage
    let isSelected: Bool
    let storeKitManager: StoreKitManager?
    let action: () -> Void
    @State private var product: Product?
    
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
                    Text("\(package.credits) Credits")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // 显示 StoreKit 产品价格，如果可用；否则显示默认价格
                Text(product?.displayPrice ?? package.price)
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
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
                product = storeKitManager.product(for: package.productID)
            }
        }
        .onChange(of: storeKitManager?.products) {
            if let storeKitManager = storeKitManager {
                product = storeKitManager.product(for: package.productID)
            }
        }
    }
}

struct EllipticalArcBackground: View {
    private let gradientColors = [
        Color.white.opacity(0.18),
        Color.white.opacity(0.02)
    ]
    
    private let borderColor = Color.white.opacity(0.54) // #FFFFFF8A
    
    private let baseWidth: CGFloat = 430
    private let ellipseWidth: CGFloat = 212.99999664508604
    private let ellipseHeight: CGFloat = 333.99999473924294
    private let ellipseTop: CGFloat = 140    // shift downward
    private let ellipseLeft: CGFloat = 420   // shift further to right
    private let ellipseAngle: Double = -160.25
    
    var body: some View {
        GeometryReader { geo in
            let widthRatio = geo.size.width / baseWidth
            let ellipseSize = CGSize(
                width: ellipseWidth * widthRatio,
                height: ellipseHeight * widthRatio
            )
            let offsetX = (ellipseLeft - ellipseWidth / 2) * widthRatio
            let offsetY = (ellipseTop - ellipseHeight / 2) * widthRatio
            
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: ellipseSize.width, height: ellipseSize.height)
                .overlay(
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
                .rotationEffect(.degrees(ellipseAngle))
                .offset(x: offsetX, y: offsetY)
                .opacity(0.3)
        }
    }
}

struct SunsetGradientBackground: View {
    // 落日余晖渐变颜色：从温暖的橙色/红色到淡黄色
    private let gradientColors = [
        Color(red: 1.0, green: 0.4, blue: 0.2).opacity(0.5),  // 橙红色
        Color(red: 1.0, green: 0.6, blue: 0.3).opacity(0.35),  // 橙色
        Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.25),  // 黄色
        Color.white.opacity(0.05)                              // 淡白色
    ]
    
    var body: some View {
        GeometryReader { geo in
            // 创建一个从左下角往右上角方向的径向渐变
            RadialGradient(
                colors: gradientColors,
                center: UnitPoint(x: 0, y: 1), // 左下角
                startRadius: 0,
                endRadius: sqrt(geo.size.width * geo.size.width + geo.size.height * geo.size.height) * 0.8
            )
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(0.2)
        }
    }
}

