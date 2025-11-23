# MeasurementFilter 使用說明

## 概述

`MeasurementFilter` 是一個用於平滑測量數值並減少抖動的濾波器類別。它實作了多種濾波演算法，包括移動平均、卡爾曼濾波器和指數移動平均，並提供異常值檢測和無效測量處理功能。

## 功能特點

### 1. 多種濾波演算法

- **移動平均 (Moving Average)**: 簡單且有效，適合大多數情況
- **卡爾曼濾波器 (Kalman Filter)**: 更精確的預測和平滑，適合需要高精度的場景
- **指數移動平均 (Exponential Moving Average)**: 給予最近的測量更高權重，反應更快

### 2. 異常值檢測

- 使用統計方法（Z-score）檢測異常測量值
- 自動過濾掉偏離正常範圍的測量
- 可配置的檢測閾值

### 3. 無效測量處理

- 檢測 NaN、無限值和負值
- 檢測不合理的尺寸（如超過 10 米）
- 當檢測到無效測量時，使用最後一個有效值

### 4. 統計追蹤

- 追蹤處理的測量數量
- 記錄檢測到的異常值數量
- 計算平均值和標準差

## 使用方法

### 基本使用

```swift
// 創建預設配置的濾波器（移動平均，窗口大小 5）
let filter = MeasurementFilter()

// 處理測量值
let rawMeasurement = ObjectDimensions(length: 10.5, width: 5.2, height: 3.1, accuracy: 0.9)
let smoothedMeasurement = filter.filter(rawMeasurement)

print("平滑後的測量: \(smoothedMeasurement.formattedDimensions())")
```

### 自訂配置

```swift
// 創建自訂配置
var config = MeasurementFilterConfiguration()
config.filterType = .kalman
config.windowSize = 10
config.enableOutlierDetection = true
config.outlierThreshold = 3.0

let filter = MeasurementFilter(configuration: config)
```

### 使用卡爾曼濾波器

```swift
var config = MeasurementFilterConfiguration()
config.filterType = .kalman
config.kalmanProcessNoise = 0.01  // 過程噪聲（較小 = 更信任模型）
config.kalmanMeasurementNoise = 0.1  // 測量噪聲（較小 = 更信任測量）

let filter = MeasurementFilter(configuration: config)
```

### 使用指數移動平均

```swift
var config = MeasurementFilterConfiguration()
config.filterType = .exponentialMovingAverage
config.emaAlpha = 0.3  // 0.0-1.0，越高越重視最近的測量

let filter = MeasurementFilter(configuration: config)
```

### 整合到即時測量系統

```swift
class RealtimeMeasurementManager {
    private let measurementFilter: MeasurementFilter

    init() {
        var config = MeasurementFilterConfiguration()
        config.filterType = .movingAverage
        config.windowSize = 5
        config.enableOutlierDetection = true

        self.measurementFilter = MeasurementFilter(configuration: config)
    }

    func processFrame(_ frame: ARFrame) {
        // ... 物體檢測和測量計算 ...

        let rawDimensions = measurementCalculator.calculateDimensions(
            object: detectedObject,
            arFrame: frame
        )

        // 應用濾波器
        let smoothedDimensions = measurementFilter.filter(rawDimensions)

        // 更新 UI
        updateUI(with: smoothedDimensions)
    }
}
```

## 配置參數說明

### FilterType

- `.movingAverage`: 移動平均（預設）
- `.kalman`: 卡爾曼濾波器
- `.exponentialMovingAverage`: 指數移動平均

### 移動平均參數

- `windowSize`: 窗口大小（樣本數量），預設 5
  - 較大的值 = 更平滑但反應較慢
  - 較小的值 = 反應較快但可能有抖動

### 卡爾曼濾波器參數

- `kalmanProcessNoise`: 過程噪聲，預設 0.01
  - 較小 = 更信任模型預測
  - 較大 = 更信任新測量
- `kalmanMeasurementNoise`: 測量噪聲，預設 0.1
  - 較小 = 認為測量很準確
  - 較大 = 認為測量有較多噪聲

### 指數移動平均參數

- `emaAlpha`: 平滑係數，預設 0.3（範圍 0.0-1.0）
  - 接近 1.0 = 快速反應，較少平滑
  - 接近 0.0 = 慢速反應，更多平滑

### 異常值檢測參數

- `enableOutlierDetection`: 是否啟用異常值檢測，預設 true
- `outlierThreshold`: 異常值閾值（標準差倍數），預設 2.5
  - 較大 = 較寬鬆，較少測量被視為異常值
  - 較小 = 較嚴格，較多測量被視為異常值

### 其他參數

- `minimumSamples`: 開始應用濾波器前的最小樣本數，預設 2

## 效能考量

### 移動平均

- **優點**: 簡單、快速、記憶體使用少
- **缺點**: 對突然變化反應較慢
- **適用**: 大多數一般用途

### 卡爾曼濾波器

- **優點**: 最精確、能預測趨勢、適應性強
- **缺點**: 計算較複雜、需要調整參數
- **適用**: 需要高精度的場景

### 指數移動平均

- **優點**: 反應快、記憶體使用極少
- **缺點**: 對噪聲較敏感
- **適用**: 需要快速反應的場景

## 統計資訊

```swift
// 獲取濾波器統計資訊
let stats = filter.getStatistics()
stats.printSummary()

// 輸出範例:
// 📊 Filter Statistics:
//    Measurements processed: 100
//    Outliers detected: 5
//    Outlier rate: 5.0%
//    Buffer size: 5
//    Average dimensions: 10.2cm × 5.1cm × 3.0cm
```

## 重置濾波器

```swift
// 重置濾波器狀態（清除所有歷史數據）
filter.reset()
```

## 動態更新配置

```swift
// 在運行時更新配置
var newConfig = MeasurementFilterConfiguration()
newConfig.filterType = .kalman
newConfig.windowSize = 10

filter.updateConfiguration(newConfig)
```

## 最佳實踐

1. **選擇合適的濾波器類型**

   - 一般用途: 移動平均
   - 高精度需求: 卡爾曼濾波器
   - 快速反應: 指數移動平均

2. **調整窗口大小**

   - 5-10 個樣本適合大多數情況
   - 較大的窗口提供更平滑的結果但反應較慢

3. **啟用異常值檢測**

   - 在即時測量中建議啟用
   - 可以過濾掉錯誤的檢測結果

4. **監控統計資訊**

   - 定期檢查異常值率
   - 如果異常值率過高，可能需要調整閾值或改善測量條件

5. **適時重置**
   - 當測量對象改變時重置濾波器
   - 避免不同對象的測量值混合

## 範例：完整整合

```swift
class MeasurementViewController: UIViewController {
    private var measurementFilter: MeasurementFilter!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFilter()
    }

    private func setupFilter() {
        var config = MeasurementFilterConfiguration()
        config.filterType = .movingAverage
        config.windowSize = 7
        config.enableOutlierDetection = true
        config.outlierThreshold = 2.5

        measurementFilter = MeasurementFilter(configuration: config)
    }

    func onNewMeasurement(_ rawMeasurement: ObjectDimensions) {
        // 應用濾波器
        let smoothed = measurementFilter.filter(rawMeasurement)

        // 更新 UI
        updateDimensionLabels(smoothed)

        // 定期檢查統計
        if measurementFilter.measurementCount % 50 == 0 {
            let stats = measurementFilter.getStatistics()
            print("📊 已處理 \(stats.measurementCount) 個測量")
            print("   異常值率: \(String(format: "%.1f%%", stats.outlierRate * 100))")
        }
    }

    func onObjectChanged() {
        // 當測量新物體時重置濾波器
        measurementFilter.reset()
        print("🔄 濾波器已重置")
    }
}
```

## 疑難排解

### 問題：測量值仍然抖動

**解決方案**:

- 增加窗口大小（例如從 5 增加到 10）
- 切換到卡爾曼濾波器
- 降低 EMA 的 alpha 值

### 問題：反應太慢

**解決方案**:

- 減少窗口大小
- 切換到指數移動平均
- 增加 EMA 的 alpha 值

### 問題：太多異常值被檢測

**解決方案**:

- 增加 outlierThreshold（例如從 2.5 增加到 3.0）
- 暫時禁用異常值檢測
- 改善測量條件（光線、距離等）

### 問題：異常值未被檢測

**解決方案**:

- 減少 outlierThreshold（例如從 2.5 減少到 2.0）
- 確保 enableOutlierDetection 為 true
- 增加 minimumSamples 以獲得更好的統計基礎
