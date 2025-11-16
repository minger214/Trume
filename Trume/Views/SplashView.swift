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
            
                Image("logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 260, height: 260)
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

