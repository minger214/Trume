//
//  NavigationBar.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct NavigationBar: View {
    let title: String
    var leadingButtons: [NavigationBarButton] = []
    var trailingButtons: [NavigationBarButton] = []
    
    var body: some View {
        HStack {
            // 左侧按钮组
            HStack(spacing: 12) {
                ForEach(leadingButtons, id: \.id) { button in
                    Button(action: button.action) {
                        if let customContent = button.customContent {
                            customContent()
                        } else if let icon = button.icon {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(width: leadingButtons.isEmpty ? 44 : nil)
            .padding(.leading, leadingButtons.isEmpty ? 0 : 10)
            
            Spacer()
            
            // 标题
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // 右侧按钮组
            HStack(spacing: 12) {
                ForEach(trailingButtons, id: \.id) { button in
                    Button(action: button.action) {
                        if let customContent = button.customContent {
                            customContent()
                        } else if let icon = button.icon {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(width: trailingButtons.isEmpty ? 44 : nil, height: 44)
        }
        .background(
            Color.black.opacity(1.0)
        )
    }
}

struct NavigationBarButton {
    let id: String
    let icon: String?
    let customContent: (() -> AnyView)?
    let action: () -> Void
    
    /// 初始化方法：使用图标
    init(id: String, icon: String, action: @escaping () -> Void) {
        self.id = id
        self.icon = icon
        self.customContent = nil
        self.action = action
    }
    
    /// 初始化方法：使用自定义视图
    init<Content: View>(id: String, content: @escaping () -> Content, action: @escaping () -> Void) {
        self.id = id
        self.icon = nil
        self.customContent = { AnyView(content()) }
        self.action = action
    }
    
    /// 便捷初始化方法：创建返回按钮
    static func back(action: @escaping () -> Void) -> NavigationBarButton {
        NavigationBarButton(id: "back", icon: "chevron.left", action: action)
    }
    
    /// 便捷初始化方法：创建关闭按钮
    static func close(action: @escaping () -> Void) -> NavigationBarButton {
        NavigationBarButton(id: "close", content: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width:28, height: 28)
        }, action: action)
    }
    
    /// 便捷初始化方法：创建自定义图标按钮
    static func custom(id: String, icon: String, action: @escaping () -> Void) -> NavigationBarButton {
        NavigationBarButton(id: id, icon: icon, action: action)
    }
    
    /// 便捷初始化方法：创建自定义视图按钮
    static func customView<Content: View>(id: String, content: @escaping () -> Content, action: @escaping () -> Void) -> NavigationBarButton {
        NavigationBarButton(id: id, content: content, action: action)
    }
}

