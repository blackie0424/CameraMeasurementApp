# RealtimeMeasurementManager

## 概述

`RealtimeMeasurementManager` 是一個即時測量管理器，負責整合物體檢測和測量計算功能，提供每秒 5-10 次的即時測量更新。

## 主要功能

### 1. 即時測量處理

- 整合 `ObjectDetector` 和 `MeasurementCalculator`
- 使用 `FrameThrottler` 控制處理頻率（5-10 Hz）
- 非同步處理管線，避免阻塞 UI 線程

### 2. 測量結果快取

- 快取最近的成功測量結果
- 當檢測失敗時可使用快取結果
- 提供平滑的使用者體驗

### 3. 測量數值平滑

- 使用移動平均濾波器減少抖動
- 可配置的平滑窗口大小（預設 5 個測量值）
- 可選擇啟用或停用平滑功能

### 4. 效能監控

- 追蹤處理的幀數
- 記錄成功和失敗的測量次數
- 計算平均處理時間和成功率

## 使用方式

### 基本使用

```swift
// 1. 建立管理器實例
let manager = RealtimeMeasurementManager(targetFPS: 10.0)

// 2. 啟動即時測量
manager.startRealtimeMeasurement { result in
    // 處理測量結果
    print("測量結果: \(result.dimensions.formattedDimensions())")
    print("信心度: \(result.dimensions.accuracy)")
    print("處理時間: \(result.processingTime)秒")
}

// 3. 在 ARSession delegate 中處理幀
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    manager.processFrame(frame)
}

// 4. 停止測量
manager.stopRealtimeMeasurement()
```

### 自訂配置

```swift
// 建立自訂配置
var config = RealtimeMeasurementConfiguration()
config.useCachedResults = true          // 使用快取結果
config.enableSmoothing = true           // 啟用平滑
config.smoothingWindowSize = 5          // 平滑窗口大小
config.minimumConfidence = 0.6          // 最低信心度閾值
config.maxProcessingTime = 0.2          // 最大處理時間（秒）

// 使用自訂配置建立管理器
let manager = RealtimeMeasurementManager(
    targetFPS: 8.0,
    configuration: config
)
```

### 錯誤處理

```swift
manager.startRealtimeMeasurement(
    updateHandler: { result in
        // 處理成功的測量
        updateUI(with: result)
    },
    errorHandler: { error in
        // 處理錯誤
        showError(error)
    }
)
```

### 動態調整 FPS

```swift
// 根據效能動態調整處理頻率
let stats = manager.getStatistics()
if stats.averageProcessingTime > 0.15 {
    // 處理時間過長，降低 FPS
    manager.setTargetFPS(5.0)
} else {
    // 效能良好，提高 FPS
    manager.setTargetFPS(10.0)
}
```

## 架構設計

### 處理管線

```
ARFrame (60fps)
    ↓
FrameThrottler (降採樣到 5-10fps)
    ↓
ObjectDetector (物體檢測)
    ↓
MeasurementCalculator (尺寸計算)
    ↓
MeasurementSmoothingFilter (平滑處理)
    ↓
UI Update (主線程)
```

### 關鍵組件

1. **FrameThrottler**: 控制幀處理頻率
2. **ObjectDetector**: 識別畫面中的物體
3. **MeasurementCalculator**: 計算物體尺寸
4. **MeasurementSmoothingFilter**: 平滑測量數值
5. **測量佇列**: 高優先級背景佇列處理測量任務

## 效能考量

### 目標效能指標

- 處理頻率: 5-10 Hz
- 單次處理時間: < 200ms
- UI 更新延遲: < 100ms

### 優化策略

1. **幀率控制**: 從 60fps 降採樣到 5-10fps
2. **非同步處理**: 在背景佇列執行檢測和計算
3. **結果快取**: 減少無效幀的影響
4. **平滑濾波**: 提供穩定的視覺體驗

## 測試

### 執行測試

```swift
// 執行所有測試
RealtimeMeasurementManagerTests.runAllTests()

// 執行快速測試
RealtimeMeasurementManagerTests.runQuickTest()
```

### 測試覆蓋

- ✅ 初始化和配置
- ✅ 啟動和停止功能
- ✅ 配置更新
- ✅ 統計追蹤
- ✅ 結果快取
- ✅ 平滑濾波器
- ✅ 錯誤處理

## 整合範例

### 在 ViewController 中使用

```swift
class ViewController: UIViewController, ARSessionDelegate {
    private var realtimeManager: RealtimeMeasurementManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 建立即時測量管理器
        realtimeManager = RealtimeMeasurementManager(targetFPS: 10.0)

        // 設定 AR session delegate
        arSession.delegate = self
    }

    func startRealtimeMeasurement() {
        realtimeManager?.startRealtimeMeasurement { [weak self] result in
            // 更新 UI 顯示測量結果
            self?.updateMeasurementOverlay(with: result)
        }
    }

    func stopRealtimeMeasurement() {
        realtimeManager?.stopRealtimeMeasurement()
    }

    // ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        realtimeManager?.processFrame(frame)
    }

    private func updateMeasurementOverlay(with result: RealtimeMeasurementResult) {
        DispatchQueue.main.async {
            // 更新測量覆蓋層顯示
            self.measurementOverlay.updateDimensions(result.dimensions)
            self.measurementOverlay.updateConfidence(result.dimensions.accuracy)
        }
    }
}
```

## 需求對應

此實作滿足以下需求：

- **需求 6.1**: 持續偵測畫面中的物體
- **需求 6.2**: 即時計算物體的長、寬、高
- **需求 6.4**: 每秒至少更新 5 次測量數值

## 未來改進

1. **卡爾曼濾波器**: 替代移動平均，提供更好的平滑效果
2. **自適應 FPS**: 根據裝置效能自動調整處理頻率
3. **多物體追蹤**: 同時追蹤多個物體的測量
4. **預測性更新**: 使用物體運動預測減少延遲

## 相關文件

- [FrameThrottler_README.md](./FrameThrottler_README.md) - 幀率控制說明
- [ObjectDetector.swift](./ObjectDetector.swift) - 物體檢測實作
- [MeasurementCalculator.swift](./MeasurementCalculator.swift) - 測量計算實作
