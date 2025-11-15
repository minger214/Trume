//
//  TransactionHistoryView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct TransactionHistoryView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedFilter: TransactionFilter = .all
    @Environment(\.presentationMode) var presentationMode
    
    enum TransactionFilter {
        case all
        case purchases
        case usage
    }
    
    var filteredTransactions: [Transaction] {
        let transactions = viewModel.userData.transactionHistory
        
        switch selectedFilter {
        case .all:
            return transactions
        case .purchases:
            return transactions.filter { $0.type == .purchase || $0.type == .subscription }
        case .usage:
            return transactions.filter { $0.type == .usage }
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.039, blue: 0.039)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Transaction History",
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Filter Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterButton(title: "All", isSelected: selectedFilter == .all) {
                                    selectedFilter = .all
                                }
                                FilterButton(title: "Purchases", isSelected: selectedFilter == .purchases) {
                                    selectedFilter = .purchases
                                }
                                FilterButton(title: "Usage", isSelected: selectedFilter == .usage) {
                                    selectedFilter = .usage
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 16)
                        
                        // Transaction History
                        if filteredTransactions.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.white.opacity(0.3))
                                Text("No transactions yet")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(filteredTransactions) { transaction in
                                    TransactionRow(transaction: transaction)
                                    if transaction.id != filteredTransactions.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(colors: [Color(red: 0.098, green: 0.098, blue: 0.098)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(20)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(formatDate(transaction.date))
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            // Amount
            Text("\(transaction.creditsChange > 0 ? "+" : "")\(transaction.creditsChange)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(transaction.creditsChange > 0 ? Color(red: 0.2, green: 0.78, blue: 0.35) : .white)
        }
        .padding(16)
    }
    
    private var iconName: String {
        switch transaction.type {
        case .purchase:
            return "creditcard.fill"
        case .subscription:
            return "crown.fill"
        case .usage:
            return "photo.fill"
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .purchase, .subscription:
            return Color(red: 0.2, green: 0.78, blue: 0.35)
        case .usage:
            return Color(red: 1.0, green: 0.23, blue: 0.19)
        }
    }
    
    private var iconBackgroundColor: Color {
        return iconColor
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

