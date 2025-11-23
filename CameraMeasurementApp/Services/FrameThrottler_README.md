# FrameThrottler 實作說明

## 概述

`FrameThrottler` 類別用於控制 ARKit 幀處理頻率，將 60fps 的 ARFrame 降採樣到 5-10fps，以優化即時測量的效能。

## 主要功能

### 1. 幀率控制

- **目標 FPS**: 可配置的目標處理頻率（預設 10fps，範圍 1-30fps）
- **時間間隔計算**: 自動計算最小幀間隔時間
- **智能過濾**: 只處理符合時間間隔要求的幀

### 2. 幀緩衝管理

`FrameBufferManager` 類別提供進階的幀緩衝功能：

- **緩衝策略**:
  - `keepLatest`: 保留最新的幀
  - `keepOldest`: 保留最舊的幀
  - `keepBest`: 保留追蹤品質最好的幀
- **自動修剪**: 當緩衝區滿時自動移除幀
- **執行緒安全**: 使用 DispatchQueue 確保執行緒安全

### 3. 統計追蹤

- 總接收幀數
- 總處理幀數
- 實際處理 FPS
- 處理效率（處理幀數/接收幀數）
- 經過時間

## 使用方式

### 基本使用

```swift
// 初始化 FrameThrottler，目標 10fps
let throttler = FrameThrottler(targetFPS: 10.0)

// 啟動節流
throttler.start()

// 在 ARSessionDelegate 中處理幀
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    throttler.processFrame(frame) { processedFrame in
        // 這個閉包只會以 10fps 的頻率被調用
        performObjectDetection(processedFrame)
        calculateMeasurements(processedFrame)
    }
}

// 停止節流
throttler.stop()
```

### 同步處理

```swift
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    throttler.processFrameSync(frame) { processedFrame in
        // 同步處理幀
        let result = quickMeasurement(processedFrame)
        updateUI(result)
    }
}
```

### 檢查是否應該處理

```swift
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    if throttler.shouldProcessFrame(frame) {
        // 手動處理幀
        processFrame(frame)
    }
}
```

### 動態調整 FPS

```swift
// 根據效能動態調整
if deviceIsSlowingDown {
    throttler.setTargetFPS(5.0)  // 降低到 5fps
} else {
    throttler.setTargetFPS(10.0) // 恢復到 10fps
}
```

### 獲取統計資訊

```swift
let stats = throttler.getStatistics()
print("目標 FPS: \(stats["targetFPS"]!)")
print("實際 FPS: \(stats["actualFPS"]!)")
print("處理效率: \(stats["processingRatio"]!)")

// 或使用便捷方法
let actualFPS = throttler.getActualFPS()
let efficiency = throttler.getProcessingEfficiency()
```

## FrameBufferManager 使用

### 基本緩衝

```swift
// 初始化緩衝管理器，最多保留 3 幀
let bufferManager = FrameBufferManager(maxSize: 3, strategy: .keepLatest)

// 添加幀到緩衝區
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    bufferManager.addFrame(frame)
}

// 從緩衝區獲取幀進行處理
if let frame = bufferManager.getNextFrame() {
    processFrame(frame)
}
```

### 查看最新幀

```swift
// 查看但不移除最新幀
if let latestFrame = bufferManager.peekLatestFrame() {
    displayPreview(latestFrame)
}
```

### 緩衝區管理

```swift
// 檢查緩衝區狀態
if bufferManager.isEmpty() {
    print("緩衝區為空")
}

if bufferManager.isFull() {
    print("緩衝區已滿")
}

let size = bufferManager.getBufferSize()
print("當前緩衝區大小: \(size)")

// 清空緩衝區
bufferManager.clear()
```

## 整合範例

### 與 RealtimeMeasurementManager 整合

```swift
class RealtimeMeasurementManager {
    private let frameThrottler: FrameThrottler
    private let objectDetector: ObjectDetectorProtocol
    private let measurementCalculator: MeasurementCalculatorProtocol

    init() {
        self.frameThrottler = FrameThrottler(targetFPS: 10.0)
        self.objectDetector = ObjectDetector()
        self.measurementCalculator = MeasurementCalculator()
    }

    func startRealtimeMeasurement(arSession: ARSession,
                                  updateHandler: @escaping (ObjectDimensions) -> Void) {
        frameThrottler.start()

        // 在 ARSessionDelegate 中
        // func session(_ session: ARSession, didUpdate frame: ARFrame)
        // 會調用 processFrame
    }

    func processFrame(_ frame: ARFrame, updateHandler: @escaping (ObjectDimensions) -> Void) {
        frameThrottler.processFrame(frame) { [weak self] processedFrame in
            guard let self = self else { return }

            // 物體檢測
            let detectedObjects = self.objectDetector.detectObjects(in: processedFrame)

            guard let firstObject = detectedObjects.first else { return }

            // 計算測量值
            let dimensions = self.measurementCalculator.calculateDimensions(
                object: firstObject,
                arFrame: processedFrame
            )

            // 更新 UI（在主執行緒）
            DispatchQueue.main.async {
                updateHandler(dimensions)
            }
        }
    }

    func stopRealtimeMeasurement() {
        frameThrottler.stop()
    }
}
```

## 效能考量

### 記憶體管理

- FrameThrottler 不保留 ARFrame 引用，避免記憶體累積
- FrameBufferManager 限制緩衝區大小，防止記憶體溢出
- 使用 weak self 避免循環引用

### 執行緒安全

- 所有內部狀態修改都在專用的 DispatchQueue 中執行
- 統計資訊讀取使用 sync 確保資料一致性
- 幀處理使用 async 避免阻塞主執行緒

### 效能優化建議

1. **選擇合適的目標 FPS**:

   - 5fps: 低功耗模式，適合背景處理
   - 10fps: 平衡模式，推薦用於即時測量
   - 15-20fps: 高響應模式，需要更多運算資源

2. **使用緩衝策略**:

   - `keepLatest`: 適合即時預覽
   - `keepBest`: 適合需要高品質追蹤的測量

3. **監控效能**:
   ```swift
   let stats = throttler.getStatistics()
   if let actualFPS = stats["actualFPS"] as? Double, actualFPS < 5.0 {
       // 效能不足，降低處理頻率
       throttler.setTargetFPS(5.0)
   }
   ```

## 測試建議

### 單元測試

- 測試幀率控制準確性
- 驗證緩衝區管理邏輯
- 測試統計資訊計算

### 整合測試

- 測試與 ARSession 的整合
- 驗證多執行緒環境下的穩定性
- 測試長時間運行的記憶體穩定性

### 效能測試

- 測量實際處理 FPS
- 監控記憶體使用
- 驗證 CPU 使用率

## 注意事項

1. **ARFrame 生命週期**: ARFrame 只在 delegate 回調期間有效，不要長時間保留引用
2. **執行緒安全**: 確保 UI 更新在主執行緒執行
3. **效能監控**: 定期檢查統計資訊，根據實際效能調整參數
4. **錯誤處理**: 處理 ARSession 中斷和恢復的情況

## 相關需求

- **需求 6.1**: 即時物體偵測和測量
- **需求 6.4**: 效能優化（5-10 Hz 更新頻率）

## 下一步

此實作完成後，下一個任務將實作 `RealtimeMeasurementManager`，整合 FrameThrottler、ObjectDetector 和 MeasurementCalculator，提供完整的即時測量功能。
