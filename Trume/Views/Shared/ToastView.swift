//
//  ToastView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: AppViewModel.ToastType
    @Binding var show: Bool
    
    var body: some View {
        if show {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                Text(message)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: show)
        }
    }
    
    private var iconName: String {
        switch type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .success:
            return Color(red: 0.2, green: 0.78, blue: 0.35)
        case .error:
            return Color(red: 1.0, green: 0.23, blue: 0.19)
        case .warning:
            return Color(red: 1.0, green: 0.58, blue: 0.0)
        case .info:
            return Color(white: 0.1)
        }
    }
}

struct ToastModifier: ViewModifier {
    @ObservedObject var viewModel: AppViewModel
    
    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                ToastView(
                    message: viewModel.toastMessage,
                    type: viewModel.toastType,
                    show: $viewModel.showToast
                )
                .padding(.top, 60)
                Spacer()
            }
        }
    }
}

extension View {
    func toast(viewModel: AppViewModel) -> some View {
        modifier(ToastModifier(viewModel: viewModel))
    }
}

