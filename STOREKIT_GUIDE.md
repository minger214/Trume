# StoreKit In-App Purchase 功能模块使用指南

## 概述

本项目已实现完整的 In-App Purchase 功能模块，支持以下三种产品类型：

1. **Consumable（消耗型产品）** - 积分充值
2. **Auto-renewable Subscription（自动续费订阅）** - 订阅计划
3. **Non-renewable Subscription（非自动续费订阅）** - 固定期限订阅

## 产品配置

### 消耗型产品（积分充值）

- `com.trume.credits.2000` - 2000 积分 - $19.99
- `com.trume.credits.5000` - 5000 积分 - $39.99
- `com.trume.credits.10000` - 10000 积分 - $59.99

### 自动续费订阅

- `com.trume.plan.weekly.basic` - Basic 计划（周付）- $4.99/周
  - 免费试用：无
  - 订阅周期：1 周

## 本地测试配置

### 1. 在 Xcode 中配置 StoreKit 配置文件

1. 打开 Xcode 项目
2. 在项目导航器中，找到 `TrumeProducts.storekit` 文件
3. 如果文件未显示，请确保文件已添加到项目中：
   - 右键点击项目根目录
   - 选择 "Add Files to..."
   - 选择 `TrumeProducts.storekit` 文件
   - 确保 "Copy items if needed" 未选中（文件已在项目中）

### 2. 启用 StoreKit 测试

1. 在 Xcode 中，选择 Product > Scheme > Edit Scheme...
2. 选择 "Run" 配置
3. 在 "Options" 标签页中，找到 "StoreKit Configuration"
4. 选择 "TrumeProducts.storekit"
5. 点击 "Close"

### 3. 运行应用进行测试

1. 在 Xcode 中运行应用（⌘R）
2. 应用将使用本地 StoreKit 配置文件进行测试
3. 所有购买操作将在本地环境中进行，不会产生实际费用

## 代码结构

### StoreKitManager

`StoreKitManager` 是核心管理类，位于 `Trume/ViewModels/StoreKitManager.swift`。

**主要功能：**
- 加载产品信息
- 处理购买流程
- 管理交易状态
- 监听交易更新
- 恢复购买

**关键方法：**

```swift
// 加载所有产品
await storeKitManager.loadProducts()

// 购买产品
let transaction = try await storeKitManager.purchase(product)

// 恢复购买
try await storeKitManager.restorePurchases()

// 检查产品类型
storeKitManager.isConsumable(productID: "com.trume.credits.2000")
storeKitManager.isAutoRenewableSubscription(productID: "com.trume.premium.monthly")
storeKitManager.isNonRenewableSubscription(productID: "com.trume.premium.3months")

// 获取订阅到期日期
let expirationDate = await storeKitManager.subscriptionExpirationDate(for: productID)
```

### 视图集成

#### SubscriptionView

订阅页面使用 `StoreKitManager` 处理自动续费订阅：

```swift
@State private var storeKitManager: StoreKitManager?

// 在 onAppear 中初始化
if #available(iOS 15.0, *) {
    if storeKitManager == nil {
        storeKitManager = StoreKitManager()
    }
    Task { await storeKitManager?.loadProducts() }
}

// 处理购买
let transaction = try await storeKitManager?.purchase(product)
```

#### CreditPurchaseView

积分购买页面使用 `StoreKitManager` 处理消耗型产品：

```swift
@State private var storeKitManager: StoreKitManager?

// 处理积分购买
let transaction = try await storeKitManager?.purchase(product)
if transaction != nil {
    // 购买成功，添加积分
    viewModel.addCredits(selectedPackage.credits, type: .purchase, ...)
}
```

#### SettingsView

设置页面提供恢复购买功能：

```swift
// 恢复购买
try await storeKitManager?.restorePurchases()
await storeKitManager?.updatePurchasedProducts()
```

## 测试流程

### 测试消耗型产品（积分充值）

1. 打开应用
2. 导航到积分购买页面
3. 选择一个积分包（2000/5000/10000）
4. 点击 "Add Credits"
5. 在 StoreKit 测试界面中确认购买
6. 验证积分是否正确添加

### 测试自动续费订阅

1. 打开应用
2. 导航到订阅页面
3. 选择一个订阅计划
4. 点击 "Continue"
5. 在 StoreKit 测试界面中确认购买
6. 验证订阅状态和积分是否正确添加

### 测试非自动续费订阅

非自动续费订阅的测试流程与自动续费订阅类似，但订阅不会自动续费。

### 测试恢复购买

1. 在设置页面
2. 点击 "Restore Purchases"
3. 验证之前的购买是否恢复

## StoreKit 测试界面

在本地测试环境中，StoreKit 会显示一个测试界面，允许你：

- **批准购买** - 模拟成功的购买
- **拒绝购买** - 模拟失败的购买
- **延迟购买** - 模拟待处理的购买（需要家长批准等）
- **查看交易历史** - 查看所有测试交易

### 访问 StoreKit 测试界面

1. 在模拟器或设备上运行应用
2. 进行购买操作
3. StoreKit 测试界面会自动弹出
4. 或者，在 Xcode 中：Window > StoreKit Transaction Manager

## 交易状态管理

### 消耗型产品

- 购买成功后立即完成交易
- 交易不会保留在交易历史中
- 每次购买都是独立的交易

### 自动续费订阅

- 交易在订阅期间保持活跃
- 系统自动处理续费
- 订阅到期后交易自动完成
- 可以通过 `Transaction.currentEntitlements` 查询当前有效的订阅

### 非自动续费订阅

- 购买成功后立即完成交易
- 需要手动管理订阅到期时间
- 不会自动续费

## 错误处理

所有 StoreKit 操作都包含错误处理：

```swift
do {
    let transaction = try await storeKitManager?.purchase(product)
    // 处理成功
} catch {
    // 处理错误
    let errorMessage = (error as? StoreError)?.errorDescription ?? error.localizedDescription
    viewModel.showToast(message: "Payment failed: \(errorMessage)", type: .error)
}
```

**常见错误类型：**
- `StoreError.failedVerification` - 交易验证失败
- `StoreError.productNotFound` - 产品未找到
- `StoreError.purchaseFailed` - 购买失败
- `StoreError.restoreFailed` - 恢复失败

## 生产环境配置

### 1. App Store Connect 配置

在将应用发布到 App Store 之前，需要在 App Store Connect 中配置产品：

1. 登录 App Store Connect
2. 选择你的应用
3. 进入 "App内购买项目"
4. 为每个产品ID创建对应的产品
5. 确保产品ID与代码中的ID完全匹配

### 2. 移除测试代码

在生产环境中，确保：
- 移除所有测试相关的代码
- 使用真实的 StoreKit 配置（移除 `TrumeProducts.storekit` 配置）
- 测试所有购买流程

### 3. 服务器验证（可选）

对于生产环境，建议实现服务器端验证：
- 验证交易收据
- 防止欺诈
- 管理订阅状态

## 注意事项

1. **产品ID 必须匹配** - 代码中的产品ID必须与 App Store Connect 和 `TrumeProducts.storekit` 中的ID完全一致

2. **订阅组** - 自动续费订阅必须属于同一个订阅组（`com.trume.subscriptions`）

3. **免费试用** - 免费试用配置在 `TrumeProducts.storekit` 中，生产环境需要在 App Store Connect 中配置

4. **交易验证** - 所有交易都经过验证，确保安全性

5. **iOS 版本要求** - StoreKit 2 需要 iOS 15.0+

## 故障排除

### 产品加载失败

- 检查产品ID是否正确
- 确保 `TrumeProducts.storekit` 文件已正确添加到项目
- 检查 StoreKit 配置是否在 Scheme 中启用

### 购买失败

- 检查网络连接
- 查看错误消息
- 在 StoreKit Transaction Manager 中查看交易状态

### 订阅状态不正确

- 调用 `updatePurchasedProducts()` 刷新状态
- 检查订阅到期日期
- 使用恢复购买功能

## 相关文件

- `Trume/ViewModels/StoreKitManager.swift` - StoreKit 管理类
- `Products.storekit` - StoreKit 本地测试配置
- `Trume/Views/SubscriptionView.swift` - 订阅页面
- `Trume/Views/CreditPurchaseView.swift` - 积分购买页面
- `Trume/Views/SettingsView.swift` - 设置页面（包含恢复购买）

## 支持

如有问题，请参考：
- [Apple StoreKit 2 文档](https://developer.apple.com/documentation/storekit)
- [StoreKit 测试指南](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)




