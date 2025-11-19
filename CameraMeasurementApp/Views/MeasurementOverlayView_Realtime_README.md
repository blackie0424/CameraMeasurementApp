# MeasurementOverlayView 即時測量功能說明

## 概述

MeasurementOverlayView 已更新以支援即時測量顯示功能，提供流暢的使用者體驗和清晰的視覺回饋。

## 新增功能

### 1. 即時測量數值顯示標籤

三個獨立的標籤顯示物體的長、寬、高：

- **長度標籤** (藍色背景): 顯示物體長度
- **寬度標籤** (綠色背景): 顯示物體寬度
- **高度標籤** (橘色背景): 顯示物體高度

標籤特性：

- 自動根據使用者偏好單位顯示（公分/英吋/公釐）
- 位於畫面左側，垂直排列
- 圓角設計，半透明背景
- 粗體字型，易於閱讀

### 2. 平滑的數值更新動畫

- 使用 `UIView.transition` 實現數值變化的交叉淡入淡出效果
- 動畫持續時間 0.3 秒，提供流暢的視覺過渡
- 標籤顯示/隱藏使用淡入淡出動畫（0.2-0.3 秒）

### 3. 測量指示器視覺元素

十字準星指示器：

- 黃色十字線設計
- 40x40 像素大小
- 持續脈衝動畫（0.8-1.2 倍縮放）
- 可定位到畫面任意位置

### 4. 測量失敗 UI 狀態處理

失敗狀態標籤：

- 紅色背景，白色文字
- 顯示「測量失敗 - 請調整角度或距離」
- 位於畫面中央
- 自動隱藏測量數值標籤

## API 使用方法

### 更新即時測量

```swift
let dimensions = ObjectDimensions(length: 10.5, width: 5.2, height: 3.8, accuracy: 0.95)
overlayView.updateRealtimeMeasurement(dimensions)
```

### 顯示測量指示器

```swift
let centerPoint = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
overlayView.showMeasurementIndicator(at: centerPoint)
```

### 清除即時測量

```swift
overlayView.clearRealtimeMeasurement()
```

### 顯示測量失敗狀態

```swift
overlayView.showMeasurementFailure()
```

## 技術實作細節

### 標籤管理

- 使用 lazy 初始化的 UILabel 屬性
- 初始 alpha 值為 0，需要時才顯示
- 自動根據 view bounds 調整位置

### 動畫系統

- **數值更新**: `transitionCrossDissolve` 選項
- **顯示/隱藏**: `curveEaseOut` 緩動曲線
- **指示器脈衝**: CABasicAnimation 無限循環

### 狀態管理

- `isRealtimeMeasurementActive`: 追蹤即時測量是否啟用
- `measurementFailureState`: 追蹤失敗狀態
- `realtimeDimensions`: 儲存當前測量數據
- `realtimeIndicatorPosition`: 儲存指示器位置

### 佈局處理

- 覆寫 `layoutSubviews()` 處理 view bounds 變化
- 自動重新定位標籤和失敗訊息
- 支援裝置旋轉和畫面尺寸變化

## 視覺設計

### 顏色配置

- 長度標籤: `systemBlue` (85% 不透明度)
- 寬度標籤: `systemGreen` (85% 不透明度)
- 高度標籤: `systemOrange` (85% 不透明度)
- 失敗標籤: `systemRed` (85% 不透明度)
- 指示器: `systemYellow`

### 尺寸規格

- 標籤寬度: 120pt
- 標籤高度: 36pt
- 標籤間距: 10pt
- 圓角半徑: 6pt
- 字型大小: 16pt (粗體)

## 整合建議

此 overlay view 應與 `RealtimeMeasurementManager` 配合使用：

```swift
realtimeMeasurementManager.startRealtimeMeasurement(arSession: arSession) { dimensions in
    DispatchQueue.main.async {
        self.overlayView.updateRealtimeMeasurement(dimensions)
    }
}
```

## 需求對應

- **需求 6.3**: 即時顯示測量數值（長、寬、高）
- **需求 6.5**: 平滑的數值更新和失敗狀態處理
