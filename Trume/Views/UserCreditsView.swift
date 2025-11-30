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
    
    private let backgroundColor = Color(red: 0.035, green: 0.039, blue: 0.039)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                NavigationBar(
                    title: "Plans & Credits",
                    leadingButtons: [
                        NavigationBarButton.back {
                            presentationMode.wrappedValue.dismiss()
                        }
                    ]
                )
                
                VStack(alignment: .leading, spacing: 24) {
                    // Credits Balance Card
                    VStack(alignment: .leading, spacing: 20) {
                        // Total Credits
                        HStack(alignment: .center, spacing: 2) {
                            Text("\(viewModel.userData.credits.totalCredits) ")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundColor(.white)
                            Text("credits")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            // Subscription Credits - 左对齐
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Remaining subscription Credits:")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.white.opacity(0.7))
                                Text("\(viewModel.userData.credits.subscriptionCredits)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            
                            // Recharge Credits - 左对齐
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Other Credits:")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.white.opacity(0.7))
                                Text("\(viewModel.userData.credits.rechargeCredits)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Add More Credits 按钮 - 左对齐
                        Button(action: {
                            if viewModel.userData.isActiveMember {
                                showPurchase = true
                            } else {
                                viewModel.showToast(message: "Please subscribe first to add credits", type: .warning)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showSubscription = true
                                }
                            }
                        }) {
                            Text("Add more credits")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .frame(height: 45)
                                .background(Color.white)
                                .cornerRadius(45)
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.18, blue: 0.18),
                                Color(red: 0.098, green: 0.098, blue: 0.098)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    // Credits Introduction
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Credits are the \"currency\" you use within the app to access various features. Each feature has its own credit price.Once you have enough credits, you can use them for these features. When your credit balance runs low, you can upgrade to a subscription plan or purchase additional one-time credit packages.")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                    }
                    
                    Spacer()
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
            .presentationBackground(Color(red: 0.035, green: 0.039, blue: 0.039))
        }
        .sheet(isPresented: $showSubscription) {
            NavigationView {
                SubscriptionView(viewModel: viewModel)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .presentationBackground(Color(red: 0.035, green: 0.039, blue: 0.039))
        }

    }
    
}
