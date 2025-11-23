# 設計文件

## 概述

本設計文件描述如何移除手動測量模式中的 ARKit 特徵點顯示，同時保留必要的測量視覺元素。問題根源在於 `ManualMeasurementViewController` 的 `setupARView()` 方法中啟用了 `debugOptions`，導致 ARKit 自動渲染特徵點。

**需求覆蓋：**

- 需求 1：移除特徵點顯示，保留必要視覺元素
- 需求 2：保留開發除錯能力

**核心設計決策：**

- 移除 `arView.debugOptions = [.showFeaturePoints]` 設定 _[需求 1.1, 1.5]_
- 保留所有自定義視覺元素（游標、標記、測量線）_[需求 1.2, 1.3, 1.4]_
- 不需要條件編譯，直接移除除錯選項 _[需求 2.2]_

## 架構

### 問題分析

當前程式碼在 `ManualMeasurementViewController.swift` 的 `setupARView()` 方法中包含：

```swift
#if DEBUG
arView.debugOptions = [.showFeaturePoints]
#endif
```

這導致：

- ARKit 自動渲染環境中偵測到的特徵點
- 特徵點顯示為動態的黃色小點
- 這些點會隨著相機移動和環境變化而更新
- 影響使用者體驗，造成視覺干擾

### 解決方案

**方案 1：完全移除除錯選項（推薦）**

直接移除 `debugOptions` 設定，因為：

- 手動測量功能已經成熟，不需要持續顯示特徵點
- 如需除錯，可以臨時添加回來
- 簡化程式碼

**方案 2：保留但預設關閉**

保留程式碼但註解掉，方便未來除錯：

```swift
// Debug options - uncomment if needed for troubleshooting
// #if DEBUG
// arView.debugOptions = [.showFeaturePoints]
// #endif
```

## 組件與介面

### 受影響的組件

**ManualMeasurementViewController**

修改 `setupARView()` 方法：

```swift
private func setupARView() {
    arView = ARSCNView(frame: view.bounds)
    arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    arView.delegate = self

    // Set session delegate to monitor AR session events
    arView.session.delegate = self

    // 移除除錯選項以改善使用者體驗
    // 特徵點顯示已移除，使用者只會看到：
    // - 中心白色游標
    // - 測量點標記（黃色圓點）
    // - 測量線和距離標籤

    view.addSubview(arView)
    print("✅ ViewController: ARView setup complete")
}
```

### 不受影響的組件

以下組件和功能保持不變：

- `MeasurementRenderer`：繼續渲染游標、標記、測量線
- `ManualARManager`：AR Session 配置和 hit test 功能
- `MeasurementStateManager`：狀態管理邏輯
- 所有測量功能和使用者互動

## 資料模型

無資料模型變更。

## 正確性屬性

_屬性是應該在系統所有有效執行中保持為真的特性或行為——本質上是關於系統應該做什麼的正式陳述。屬性作為人類可讀規範和機器可驗證正確性保證之間的橋樑。_

### 屬性 1：特徵點不可見

_對於任何_ 手動測量會話，ARKit 特徵點不應該在畫面中可見
**驗證：需求 1.1**

### 屬性 2：必要視覺元素保留

_對於任何_ 手動測量會話，中心游標、測量點標記、測量線和距離標籤應該正常顯示
**驗證：需求 1.2, 1.3, 1.4**

## 錯誤處理

無新增錯誤處理需求。現有的錯誤處理機制保持不變。

## 測試策略

### 單元測試

不需要新的單元測試，因為這是視覺配置變更。

### 手動測試

1. **視覺驗證測試**

   - 啟動應用程式並進入手動測量模式
   - 驗證畫面中沒有動態黃色特徵點
   - 驗證中心白色游標正常顯示
   - 移動裝置，確認沒有特徵點出現

2. **功能完整性測試**

   - 執行完整的測量流程（起點 → 即時預覽 → 終點）
   - 驗證測量點標記正常顯示
   - 驗證測量線正常繪製
   - 驗證距離標籤正常顯示
   - 確認所有測量功能正常運作

3. **不同環境測試**
   - 在特徵豐富的環境測試（確認即使有很多特徵點也不顯示）
   - 在特徵稀少的環境測試（確認測量功能仍正常）
   - 在不同光線條件下測試

## 實現注意事項

### 程式碼變更

**檔案：** `CameraMeasurementApp/ManualMeasurement/ViewControllers/ManualMeasurementViewController.swift`

**位置：** `setupARView()` 方法

**變更：** 移除以下程式碼區塊：

```swift
// Enable debug options in development
#if DEBUG
arView.debugOptions = [.showFeaturePoints]
#endif
```

### 向後相容性

此變更不影響任何 API 或資料結構，完全向後相容。

### 效能影響

移除特徵點顯示可能略微改善效能，因為：

- 減少渲染負擔（不需要繪製數百個特徵點）
- 降低 GPU 使用率

### 使用者體驗改善

- 畫面更清晰，減少視覺干擾
- 使用者可以更專注於測量任務
- 更接近 Apple 測距儀的簡潔體驗

## 未來擴展考量

如果未來需要除錯功能，可以考慮：

1. **開發者選單**

   - 添加隱藏的開發者選單（例如：連續點擊版本號 5 次）
   - 在選單中提供「顯示特徵點」選項

2. **編譯時標誌**

   - 使用自定義編譯標誌而非 `DEBUG`
   - 例如：`ENABLE_AR_DEBUG_VISUALIZATION`

3. **動態切換**
   - 添加設定選項允許進階使用者啟用除錯視覺化
   - 預設關閉，需要手動啟用
