//
//  CreditPurchaseView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct CreditPurchaseView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedPackage: CreditPackage = .package2000
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
        
        var price: String {
            switch self {
            case .package2000: return "$19.99"
            case .package5000: return "$39.99"
            case .package10000: return "$59.99"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.039, blue: 0.039)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Purchase Credits",
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Need more credits?")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Pick an option to keep enjoying our app.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 16)
                        
                        // Credit Packages
                        VStack(spacing: 12) {
                            ForEach(CreditPackage.allCases, id: \.self) { package in
                                CreditPackageCard(
                                    package: package,
                                    isSelected: selectedPackage == package
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
                        
                        // Notice
                        Text("Credits add to your balance and never expire.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        // Terms Link
                        Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.51, green: 0.28, blue: 0.9))
                            .padding(.top, 8)
                        
                        // Purchase Button
                        Button(action: {
                            handlePurchase()
                        }) {
                            Text("Add \(selectedPackage.credits) Credits")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
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
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }
    
    private func handlePurchase() {
        viewModel.showToast(message: "Processing purchase...", type: .info)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            viewModel.addCredits(
                selectedPackage.credits,
                type: .purchase,
                description: "Credit Purchase"
            )
            
            viewModel.showToast(
                message: "\(selectedPackage.credits) credits added successfully!",
                type: .success
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct CreditPackageCard: View {
    let package: CreditPurchaseView.CreditPackage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(package.credits) Credits")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(package.price)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(red: 0.51, green: 0.28, blue: 0.9) : Color.white.opacity(0.3))
            }
            .padding(16)
            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(red: 0.51, green: 0.28, blue: 0.9) : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
}

