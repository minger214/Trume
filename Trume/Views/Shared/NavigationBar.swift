//
//  NavigationBar.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct NavigationBar: View {
    let title: String
    var showBackButton: Bool = false
    var trailingButtons: [NavigationBarButton] = []
    var onBack: (() -> Void)?
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: {
                    onBack?()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Placeholder to maintain layout when no back button
                Spacer()
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 12) {
                ForEach(trailingButtons, id: \.id) { button in
                    Button(action: button.action) {
                        Image(systemName: button.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .frame(width: trailingButtons.isEmpty ? 44 : nil, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.9)
        )
    }
}

struct NavigationBarButton {
    let id: String
    let icon: String
    let action: () -> Void
}

