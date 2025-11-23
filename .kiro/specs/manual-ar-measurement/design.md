# 設計文件

## 概述

本設計文件描述手動 AR 測量功能的實現方案，該功能類似 Apple 測距儀應用程式。使用者透過畫面中心的白色游標和按鈕操作，在真實世界中放置測量點並計算距離。系統使用 ARKit 的世界追蹤和平面檢測功能，提供即時視覺回饋和精確的距離測量。

**需求覆蓋：**

- 需求 1：中心游標顯示與持續渲染
- 需求 2：起點記錄與視覺標記
- 需求 3：即時測量線繪製與距離顯示
- 需求 4：終點確認與最終距離計算
- 需求 5：測量重置與單一測量線模式

**核心設計決策：**

- 採用單一測量模式（一次只顯示一條測量線），簡化使用者體驗 _[需求 5.4]_
- 使用 ARKit 的 hit test 進行 3D 位置檢測，確保測量點準確對應真實世界表面 _[需求 2.1, 2.2, 3.1, 4.1]_
- 即時渲染測量線和距離，提供流暢的視覺回饋（目標 30+ FPS）_[需求 3.5]_
- 採用狀態機模式管理測量流程（等待起點 → 即時預覽 → 測量完成）_[需求 2, 3, 4, 5]_

## 架構

### 系統組件

```
┌─────────────────────────────────────────────────────────┐
│                  ManualMeasurementViewController         │
│  - 管理 UI 互動和測量按鈕事件                              │
│  - 協調各組件之間的通訊                                    │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  ARManager   │  │ MeasurementUI│  │ Measurement  │
│              │  │    Renderer  │  │   State      │
│ - AR Session │  │              │  │   Manager    │
│ - Hit Test   │  │ - 游標渲染   │  │              │
│ - 平面檢測   │  │ - 測量線繪製 │  │ - 狀態追蹤   │
│              │  │ - 距離顯示   │  │ - 點位儲存   │
└──────────────┘  └──────────────┘  └──────────────┘
```

**設計理由：**

- 分離關注點：AR 功能、UI 渲染和狀態管理各自獨立，便於測試和維護
- ViewController 作為協調者，避免業務邏輯分散
- 可重用的組件設計，未來可擴展多點測量或其他測量模式

### 測量狀態流程

```
┌──────────────┐
│   Initial    │ 啟動 AR Session
│   (等待)     │ 顯示中心游標
└──────┬───────┘
       │ 使用者點擊按鈕
       │ Hit Test 成功
       ▼
┌──────────────┐
│  StartPoint  │ 記錄起點座標
│   Recorded   │ 顯示起點標記
│   (預覽)     │ 開始即時繪製
└──────┬───────┘
       │ 使用者再次點擊
       │ Hit Test 成功
       ▼
┌──────────────┐
│  Measurement │ 記錄終點座標
│   Complete   │ 計算最終距離
│   (完成)     │ 固定顯示結果
└──────┬───────┘
       │ 使用者再次點擊
       │ 清除並重置
       ▼
   (回到 Initial)
```

## 組件與介面

### 1. ManualMeasurementViewController

主要視圖控制器，負責整合所有組件並處理使用者互動。

```swift
class ManualMeasurementViewController: UIViewController {
    // UI 組件
    private var arView: ARSCNView
    private var measureButton: UIButton
    private var reticleView: UIView

    // 核心組件
    private var arManager: ManualARManager
    private var stateManager: MeasurementStateManager
    private var renderer: MeasurementRenderer

    // 主要方法
    func setupARSession()
    func onMeasureButtonTapped()
    func updateRealtimePreview()
}
```

**職責：**

- 初始化和配置 AR Session _[需求 1.1]_
- 處理測量按鈕點擊事件 _[需求 2.1, 4.1, 5.2]_
- 協調狀態轉換和 UI 更新 _[需求 2, 3, 4, 5]_
- 管理視圖生命週期

### 2. ManualARManager

封裝 ARKit 相關功能，提供 hit test 和座標轉換。

```swift
class ManualARManager {
    private var arSession: ARSession
    private var sceneView: ARSCNView

    // Hit Test 方法
    func performHitTest(at screenCenter: CGPoint) -> ARHitTestResult?

    // 座標轉換
    func worldPosition(from hitResult: ARHitTestResult) -> SCNVector3

    // AR Session 管理
    func startSession(with configuration: ARWorldTrackingConfiguration)
    func pauseSession()
}
```

**設計決策：**

- 使用 `ARWorldTrackingConfiguration` 啟用世界追蹤和平面檢測 _[需求 2.2, 3.1]_
- Hit test 優先順序：existingPlaneUsingExtent > featurePoint _[需求 2.2, 4.2]_
- 返回可選值處理 hit test 失敗情況 _[需求 2.4]_

### 3. MeasurementStateManager

管理測量狀態和測量點資料。

```swift
enum MeasurementState {
    case initial
    case startPointRecorded(SCNVector3)
    case measurementComplete(start: SCNVector3, end: SCNVector3, distance: Float)
}

class MeasurementStateManager {
    private(set) var currentState: MeasurementState = .initial

    func recordStartPoint(_ position: SCNVector3)
    func recordEndPoint(_ position: SCNVector3)
    func calculateDistance(from start: SCNVector3, to end: SCNVector3) -> Float
    func reset()

    var startPoint: SCNVector3? { get }
    var endPoint: SCNVector3? { get }
}
```

**設計理由：**

- 使用枚舉表示狀態，確保狀態轉換的類型安全 _[需求 2, 3, 4, 5]_
- 關聯值儲存每個狀態的相關資料 _[需求 2.5, 4.4]_
- 距離計算使用歐幾里得距離公式：`sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)` _[需求 4.4]_

### 4. MeasurementRenderer

負責所有視覺元素的渲染。

```swift
class MeasurementRenderer {
    private var sceneView: ARSCNView
    private var lineNode: SCNNode?
    private var startMarkerNode: SCNNode?
    private var endMarkerNode: SCNNode?
    private var distanceLabel: UILabel

    // 游標渲染
    func showCenterReticle(on view: UIView)

    // 測量點標記
    func addMarker(at position: SCNVector3, color: UIColor) -> SCNNode

    // 測量線渲染
    func drawLine(from start: SCNVector3, to end: SCNVector3, color: UIColor)
    func updateLine(to currentPosition: SCNVector3)

    // 距離顯示
    func showDistance(_ distance: Float, at midpoint: SCNVector3)
    func updateDistanceLabel(_ distance: Float)

    // 清除
    func clearAllVisuals()
}
```

**視覺規格：**

- 中心游標：白色圓形，直徑 10 像素，透明度 0.8 _[需求 1.1, 1.3, 1.4]_
- 測量點標記：黃色球體，半徑 0.01 米（約 1 公分）_[需求 2.3, 4.3]_
- 測量線：黃色圓柱體，半徑 0.002 米，連接兩點 _[需求 3.2, 3.3]_
- 距離標籤：白色文字，背景半透明黑色，字體大小 16pt _[需求 3.4, 4.6]_

**渲染優化：**

- 使用 SCNNode 的幾何體快取，避免重複建立
- 即時預覽時只更新線條端點，不重建整個節點 _[需求 3.5]_
- 距離標籤使用 billboard constraint 保持面向相機

## 資料模型

### MeasurementPoint

```swift
struct MeasurementPoint {
    let position: SCNVector3      // 3D 世界座標
    let timestamp: Date           // 記錄時間
    let confidence: Float         // Hit test 信心度（0-1）
}
```

### MeasurementResult

```swift
struct MeasurementResult {
    let startPoint: MeasurementPoint
    let endPoint: MeasurementPoint
    let distance: Float           // 單位：公尺
    let distanceInCm: Float {     // 轉換為公分
        return distance * 100
    }
}
```

**設計考量：**

- 內部使用公尺（ARKit 標準單位）
- 顯示時轉換為公分（使用者友善）
- 保留 timestamp 供未來功能擴展（如測量歷史）

## 錯誤處理

### 錯誤類型

```swift
enum ManualMeasurementError: Error {
    case arSessionFailed
    case hitTestFailed
    case invalidMeasurementPoint
    case insufficientTracking
}
```

### 錯誤處理策略

1. **AR Session 失敗**

   - 顯示錯誤訊息：「無法啟動 AR 功能，請檢查相機權限」
   - 提供重試按鈕

2. **Hit Test 失敗** _[需求 2.4]_

   - 顯示提示：「請移動裝置以偵測表面」
   - 不記錄測量點，保持當前狀態
   - 視覺回饋：游標變為紅色表示無效位置

3. **追蹤品質不足**

   - 監控 `ARCamera.trackingState`
   - 當追蹤品質為 `.limited` 或 `.notAvailable` 時顯示警告
   - 建議使用者改善光線或移動到特徵豐富的環境

4. **無效測量點**
   - 檢查測量點距離是否過近（< 1 公分）
   - 檢查測量點是否過遠（> 10 公尺）
   - 顯示合理範圍提示

## 測試策略

### 單元測試

1. **MeasurementStateManager 測試**

   - 測試狀態轉換邏輯
   - 測試距離計算準確性
   - 測試重置功能

2. **距離計算測試**
   - 使用已知座標驗證計算結果
   - 測試邊界情況（零距離、極大距離）

### 整合測試

1. **AR Hit Test 整合**

   - 使用模擬的 ARFrame 測試 hit test
   - 驗證座標轉換正確性

2. **UI 更新測試**
   - 驗證狀態變化時 UI 正確更新
   - 測試即時預覽的流暢性

### 手動測試場景

1. **基本測量流程**

   - 啟動應用程式，驗證游標顯示
   - 點擊按鈕記錄起點，驗證標記出現
   - 移動裝置，驗證即時線條繪製
   - 點擊按鈕記錄終點，驗證最終距離顯示

2. **錯誤情況測試**

   - 在無平面環境測試 hit test 失敗處理
   - 測試快速連續點擊的行為
   - 測試 AR Session 中斷後的恢復

3. **準確性驗證**
   - 使用實體尺規測量已知距離
   - 比對應用程式測量結果
   - 目標誤差：± 2%

### 效能測試

- 監控即時預覽的幀率（目標：30+ FPS）
- 測試記憶體使用（避免節點洩漏）
- 驗證長時間運行的穩定性

## 實現注意事項

### AR Session 配置

```swift
let configuration = ARWorldTrackingConfiguration()
configuration.planeDetection = [.horizontal, .vertical]
configuration.isLightEstimationEnabled = true
```

**理由：**

- 啟用水平和垂直平面檢測，提高 hit test 成功率
- 光線估計改善渲染效果

### Hit Test 優先順序

```swift
let hitTestOptions: [SCNHitTestOption: Any] = [
    .searchMode: SCNHitTestSearchMode.all.rawValue
]

// 優先順序
1. existingPlaneUsingExtent  // 已檢測的平面（最準確）
2. featurePoint              // 特徵點（次選）
```

### 效能優化

1. **節流機制** _[需求 3.5]_

   - 即時預覽更新限制為 30 FPS
   - 避免每幀都執行 hit test

2. **節點重用**

   - 更新現有節點而非重建
   - 使用物件池管理標記節點

3. **記憶體管理** _[需求 5.2]_
   - 測量完成後移除不需要的節點
   - 適當使用 weak 引用避免循環引用

### 使用者體驗細節

1. **視覺回饋**

   - 按鈕點擊時提供觸覺回饋（haptic feedback）
   - 成功記錄點位時播放音效

2. **距離格式化**
   - 統一使用公分（cm）作為顯示單位
   - 保留一位小數（例：45.3 cm、125.8 cm）
   - _對應需求：3.4, 4.6_

## 未來擴展考量

本設計預留以下擴展空間：

1. **多點測量**

   - 狀態管理器可擴展支援多個測量結果
   - 渲染器支援多條測量線同時顯示

2. **測量歷史**

   - MeasurementResult 已包含 timestamp
   - 可輕鬆整合現有的 CoreData 儲存系統

3. **面積測量**

   - 可基於多點測量計算封閉區域面積
   - 狀態機可擴展新的測量模式

4. **匯出功能**
   - 可整合現有的 ExportManager
   - 支援匯出測量結果和標註圖片
