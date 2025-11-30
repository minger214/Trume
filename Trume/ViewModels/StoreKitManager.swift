//
//  StoreKitManager.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import Foundation
import StoreKit
import SwiftUI
import Combine

@available(iOS 15.0, *)
@MainActor
class StoreKitManager: ObservableObject {
    static let processedSubscriptionIDsKey = "trume.storekit.processedSubscriptionIDs"
    @Published var products: [Product] = []
    @Published var consumableProducts: [Product] = []
    @Published var autoRenewableSubscriptions: [Product] = []
    @Published var nonRenewableSubscriptions: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // 产品ID配置
    // Consumable Products (积分充值)
    private let consumableProductIDs: [String] = [
        "com.trume.credits.2000",      // 2000 credits - $19.99
        "com.trume.credits.5000",      // 5000 credits - $39.99
        "com.trume.credits.10000"      // 10000 credits - $59.99
    ]
    
    // Auto-renewable Subscriptions (自动续费订阅)
    private let autoRenewableSubscriptionIDs: [String] = [
        "com.trume.plan.weekly.basic"     // Basic Weekly Plan: $4.99/week
        // "com.trume.plan.weekly.premium"    // Premium Weekly Plan: $19.99/week
    ]
    
    // Non-renewable Subscriptions (非自动续费订阅)
    private let nonRenewableSubscriptionIDs: [String] = [

    ]
    
    // 所有产品ID
    private var allProductIDs: [String] {
        consumableProductIDs + autoRenewableSubscriptionIDs + nonRenewableSubscriptionIDs
    }
    
    // 交易更新监听任务
    private var updateListenerTask: Task<Void, Error>?
    private var processedSubscriptionTransactionIDs: Set<UInt64> = []
    
    init() {
        loadProcessedSubscriptionTransactions()
        // 启动交易监听
        startTransactionListener()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// 加载所有产品
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 加载所有产品
            let allProducts = try await Product.products(for: allProductIDs)
            
            // 按类型分类
            await MainActor.run {
                self.products = allProducts
                self.consumableProducts = allProducts.filter { product in
                    consumableProductIDs.contains(product.id)
                }
                self.autoRenewableSubscriptions = allProducts.filter { product in
                    autoRenewableSubscriptionIDs.contains(product.id)
                }
                self.nonRenewableSubscriptions = allProducts.filter { product in
                    nonRenewableSubscriptionIDs.contains(product.id)
                }
            }
            
            // 更新已购买的产品
            await updatePurchasedProducts()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
            }
            print("Error loading products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    /// 购买产品
    /// - Parameter product: 要购买的产品
    /// - Returns: 交易对象，如果用户取消或待处理则返回 nil
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction: StoreKit.Transaction = try checkVerified(verification)
            
            // 根据产品类型处理交易
            if isConsumable(productID: product.id) {
                // 消耗型产品：立即完成交易
                await transaction.finish()
            } else if isAutoRenewableSubscription(productID: product.id) {
                processedSubscriptionTransactionIDs.insert(transaction.id)
                persistProcessedSubscriptionTransactions()
                // 自动续费订阅：不立即完成，让系统管理
                // 交易会在订阅结束时自动完成
            } else if isNonRenewableSubscription(productID: product.id) {
                // 非自动续费订阅：立即完成交易
                await transaction.finish()
            }
            
            await updatePurchasedProducts()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            // 交易待处理（需要家长批准等）
            return nil
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Transaction Management
    
    /// 启动交易更新监听
    private func startTransactionListener() {
        updateListenerTask = Task {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction: StoreKit.Transaction = try checkVerified(result)
                    
                    // 根据产品类型处理
                    if isConsumable(productID: transaction.productID) {
                        // 消耗型产品：立即完成
                        await transaction.finish()
                    } else if isAutoRenewableSubscription(productID: transaction.productID) {
                        handleSubscriptionRenewalIfNeeded(transaction)
                        // 自动续费订阅：检查订阅状态
                        await handleSubscriptionUpdate(transaction)
                    } else if isNonRenewableSubscription(productID: transaction.productID) {
                        // 非自动续费订阅：立即完成
                        await transaction.finish()
                    }
                    
                    await updatePurchasedProducts()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// 处理订阅更新
    private func handleSubscriptionUpdate(_ transaction: StoreKit.Transaction) async {
        // 对于自动续费订阅，我们需要检查订阅状态
        // 如果订阅已过期，完成交易
        if let expirationDate = transaction.expirationDate,
           expirationDate < Date() {
            await transaction.finish()
        }
        // 否则保持交易活跃，等待下次续费
    }
    
    private func handleSubscriptionRenewalIfNeeded(_ transaction: StoreKit.Transaction) {
        guard !processedSubscriptionTransactionIDs.contains(transaction.id) else { return }
        processedSubscriptionTransactionIDs.insert(transaction.id)
        persistProcessedSubscriptionTransactions()
        let expirationDate = transaction.expirationDate
        NotificationCenter.default.post(
            name: .subscriptionRenewed,
            object: nil,
            userInfo: [
                "productID": transaction.productID,
                "expirationDate": expirationDate as Any
            ]
        )
    }
    
    /// 更新已购买的产品列表
    func updatePurchasedProducts() async {
        var purchasedProductIDs: Set<String> = []
        
        // 检查当前有效的交易
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction: StoreKit.Transaction = try checkVerified(result)
                
                // 对于自动续费订阅，检查是否仍然有效
                if isAutoRenewableSubscription(productID: transaction.productID) {
                    if let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        purchasedProductIDs.insert(transaction.productID)
                    }
                } else {
                    // 非订阅产品或非自动续费订阅
                    purchasedProductIDs.insert(transaction.productID)
                }
            } catch {
                print("Error verifying transaction: \(error)")
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = purchasedProductIDs
        }
    }
    
    /// 恢复购买
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    // MARK: - Product Helpers
    
    /// 根据产品ID获取产品
    func product(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }
    
    /// 检查产品是否为消耗型
    func isConsumable(productID: String) -> Bool {
        return consumableProductIDs.contains(productID)
    }
    
    /// 检查产品是否为自动续费订阅
    func isAutoRenewableSubscription(productID: String) -> Bool {
        return autoRenewableSubscriptionIDs.contains(productID)
    }
    
    /// 检查产品是否为非自动续费订阅
    func isNonRenewableSubscription(productID: String) -> Bool {
        return nonRenewableSubscriptionIDs.contains(productID)
    }
    
    /// 获取产品类型
    func productType(for productID: String) -> ProductType {
        if isConsumable(productID: productID) {
            return .consumable
        } else if isAutoRenewableSubscription(productID: productID) {
            return .autoRenewableSubscription
        } else if isNonRenewableSubscription(productID: productID) {
            return .nonRenewableSubscription
        }
        return .unknown
    }
    
    /// 检查产品是否已购买
    func isPurchased(productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    /// 获取订阅的到期日期
    func subscriptionExpirationDate(for productID: String) async -> Date? {
        guard isAutoRenewableSubscription(productID: productID) else {
            return nil
        }
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction: StoreKit.Transaction = try checkVerified(result)
                if transaction.productID == productID {
                    return transaction.expirationDate
                }
            } catch {
                continue
            }
        }
        return nil
    }
    
    // MARK: - Verification
    
    /// 验证交易
    func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Product Type Enum

enum ProductType {
    case consumable
    case autoRenewableSubscription
    case nonRenewableSubscription
    case unknown
}

// MARK: - Store Error

enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed(String)
    case restoreFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        }
    }
}

extension Notification.Name {
    static let subscriptionRenewed = Notification.Name("StoreKitSubscriptionRenewedNotification")
}

// MARK: - Persistence Helpers
extension StoreKitManager {
    private func loadProcessedSubscriptionTransactions() {
        let storedIDs = UserDefaults.standard.array(forKey: Self.processedSubscriptionIDsKey) as? [String] ?? []
        let ids = storedIDs.compactMap { UInt64($0) }
        processedSubscriptionTransactionIDs = Set(ids)
    }
    
    private func persistProcessedSubscriptionTransactions() {
        let values = processedSubscriptionTransactionIDs.map { String($0) }
        UserDefaults.standard.set(values, forKey: Self.processedSubscriptionIDsKey)
    }
}
