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
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // 产品ID - 这些需要与 App Store Connect 中配置的产品ID匹配
    private let productIDs: [String] = [
        "com.trume.basic.weekly",      // Basic Plan: $4.99/week
        "com.trume.premium.monthly"     // Premium Plan: $19.99/month
    ]
    
    init() {
        // Products will be loaded when needed
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Error loading products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction: StoreKit.Transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    func updatePurchasedProducts() async {
        var purchasedProductIDs: Set<String> = []
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction: StoreKit.Transaction = try checkVerified(result)
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                print("Error verifying transaction: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProductIDs
    }
    
    func product(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
}

