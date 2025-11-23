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
    @State private var showPurchase: Bool = false
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
    
    private let backgroundColor = Color(red: 0.035, green: 0.039, blue: 0.039)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "",
                    showBackButton: false
                )
                .overlay(
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.black)
                                .background(Color.white.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 16)
                        Spacer()
                    }
                )
                
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Need more credits?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Pick an option to keep enjoying our app.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                    
                    // Purchase Button
                    Button(action: {
                        handlePurchase()
                    }) {
                        Text("Add Credits")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Notice
                    Text("Easy to cancel.")
                        .font(.system(size: 18))
                        .foregroundColor(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Terms Link
                    HStack(spacing: 16) {
                        Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.5))
                        
                        Text(" ")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.top, 16)
                    
                    Spacer()
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
                
                Text(package.price)
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
    }
}

