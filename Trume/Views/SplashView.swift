//
//  SplashView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @Binding var showSplash: Bool
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Image(systemName: "photo.artframe")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.51, green: 0.28, blue: 0.9), Color(red: 0.83, green: 0.2, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Spacer()
                
                Text("Trume - AI Photo Generator")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 100)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1.0
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

