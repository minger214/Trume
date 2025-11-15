# Trume - AI Photo Generator iOS App

基于原型设计实现的完整 iOS SwiftUI 应用程序。

## 项目结构

```
Trume/
├── Models/
│   └── UserData.swift          # 数据模型（用户数据、项目、交易等）
├── ViewModels/
│   └── AppViewModel.swift      # 应用状态管理和业务逻辑
├── Views/
│   ├── HomeView.swift          # 主页 - 照片上传界面
│   ├── SplashView.swift        # 启动屏幕
│   ├── TemplateView.swift      # 模板选择页面
│   ├── PortfolioView.swift     # 作品集页面
│   ├── PortfolioGeneratingView.swift  # 生成中页面
│   ├── SubscriptionView.swift  # 订阅页面
│   ├── CreditPurchaseView.swift # 积分购买页面
│   ├── UserCreditsView.swift   # 用户积分页面
│   ├── CameraView.swift        # 相机视图
│   └── Shared/
│       ├── NavigationBar.swift # 导航栏组件
│       └── ToastView.swift     # Toast 消息组件
├── ContentView.swift           # 主视图容器
└── TrumeApp.swift              # 应用入口
```

## 主要功能

### 1. 启动屏幕 (SplashView)
- 显示应用 Logo 和名称
- 2秒后自动跳转到主页

### 2. 主页 (HomeView)
- 照片上传界面
- 显示已选择的照片
- 积分显示
- 支持从相机或相册选择照片
- 继续生成作品集功能

### 3. 模板选择 (TemplateView)
- 多种模板风格选择
- 实时预览
- 保存和分享功能

### 4. 作品集 (PortfolioView)
- 显示所有生成的项目
- 支持排序（最新/最旧）
- 删除项目功能

### 5. 生成中 (PortfolioGeneratingView)
- 显示生成进度
- 预估完成时间
- 保存当前会话功能

### 6. 订阅管理 (SubscriptionView)
- Basic 和 Premium 计划选择
- 免费试用选项
- 积分奖励

### 7. 积分购买 (CreditPurchaseView)
- 多种积分套餐
- 价格显示
- 购买确认

### 8. 用户积分 (UserCreditsView)
- 显示可用积分
- 交易历史记录
- 筛选功能（全部/购买/使用）

### 9. 相机功能 (CameraView)
- 前置摄像头拍照
- 实时预览
- 照片捕获

## 数据管理

应用使用 `UserDefaults` 进行本地数据持久化：
- 用户数据（积分、订阅状态）
- 项目列表
- 选择的照片
- 交易历史

## 设计特点

- **深色主题**：与应用原型一致的深色 UI
- **渐变效果**：使用紫色渐变主题色 (#8247E5 到 #D434FE)
- **Toast 通知**：统一的用户反馈系统
- **流畅动画**：视图切换和交互动画

## 技术栈

- **SwiftUI**：现代声明式 UI 框架
- **Combine**：响应式编程
- **AVFoundation**：相机功能
- **PhotosUI**：照片选择器
- **UserDefaults**：本地数据存储

## 权限要求

在 Info.plist 中添加以下权限（如果使用 Xcode，在 Target > Info 中添加）：

- **相机权限**：
  - Key: `NSCameraUsageDescription`
  - Value: "We need camera access to take photos for AI generation"

- **照片库权限**：
  - Key: `NSPhotoLibraryUsageDescription`
  - Value: "We need photo library access to select photos for AI generation"

## 使用说明

1. 打开项目：在 Xcode 中打开 `Trume.xcodeproj`
2. 配置权限：在 Info.plist 中添加相机和照片库权限
3. 运行项目：选择目标设备或模拟器，点击运行
4. 测试功能：
   - 上传照片
   - 选择模板
   - 生成作品集
   - 购买积分和订阅

## 注意事项

- 相机功能需要在真实设备上测试（模拟器不支持）
- 照片选择器功能在 iOS 14+ 上可用
- 数据持久化使用 UserDefaults，适合演示用途
- 生产环境建议使用 Core Data 或其他数据库解决方案

## 未来改进

- 集成真实的 AI 图片生成 API
- 添加用户账户系统
- 云端数据同步
- 更多模板和风格选项
- 社交分享功能
- 应用内购买集成

