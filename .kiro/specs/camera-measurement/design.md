# 相機測量功能設計文件

## 概述

相機測量應用程式利用 ARKit、Vision 和 Core ML 框架，為使用者提供透過拍照測量物體尺寸的功能。系統結合擴增實境技術和機器學習物體識別，提供準確的測量結果並顯示參考物件進行比較。

## 架構

### 整體架構

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Layer      │    │  Business Logic │    │   Data Layer    │
│                 │    │                 │    │                 │
│ - CameraView    │◄──►│ - MeasurementMgr│◄──►│ - CoreData      │
│ - ResultView    │    │ - ObjectDetector│    │ - UserDefaults  │
│ - SettingsView  │    │ - ARManager     │    │ - FileManager   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frameworks    │    │   Core ML       │    │   Reference     │
│                 │    │                 │    │   Objects DB    │
│ - ARKit         │    │ - YOLOv5 Model  │    │                 │
│ - Vision        │    │ - Custom Models │    │ - Lighter.json  │
│ - AVFoundation  │    │                 │    │ - Coin.json     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 組件和介面

### 1. AR 管理器 (ARManager)

負責 ARKit 會話管理和平面檢測

```swift
protocol ARManagerProtocol {
    func startARSession()
    func stopARSession()
    func measureDistance(from: SCNVector3, to: SCNVector3) -> Float
    func detectPlanes() -> [ARPlaneAnchor]
    func placeVirtualObject(at: SCNVector3, object: VirtualObject)
}
```

**主要功能:**

- 管理 ARSCNView 和 ARSession
- 平面檢測和追蹤
- 3D 座標轉換
- 虛擬物件放置

### 2. 物體檢測器 (ObjectDetector)

使用 Vision 和 Core ML 進行物體識別

```swift
protocol ObjectDetectorProtocol {
    func detectObjects(in image: UIImage) -> [DetectedObject]
    func classifyObject(_ object: DetectedObject) -> ObjectType
    func getBoundingBox(for object: DetectedObject) -> CGRect
}
```

**主要功能:**

- YOLOv5 模型整合用於物體檢測
- 邊界框計算
- 物體分類和信心度評估
- 支援 20+種常見物體類別

### 3. 測量計算器 (MeasurementCalculator)

計算物體實際尺寸

```swift
protocol MeasurementCalculatorProtocol {
    func calculateDimensions(object: DetectedObject,
                           arFrame: ARFrame) -> ObjectDimensions
    func calibrateWithReference(object: ReferenceObject) -> CalibrationData
    func getAccuracyConfidence() -> Float
}
```

**主要功能:**

- 像素到實際尺寸轉換
- 深度資訊整合
- 參考物件校準
- 誤差計算和信心度評估

### 4. 參考物件管理器 (ReferenceObjectManager)

管理預設參考物件

```swift
protocol ReferenceObjectManagerProtocol {
    func getAvailableObjects() -> [ReferenceObject]
    func selectBestReference(for measuredObject: DetectedObject) -> ReferenceObject
    func getReferenceModel(for object: ReferenceObject) -> SCNNode
}
```

**預設參考物件:**

- 打火機 (7.5 x 2.5 x 1.2 cm)
- 硬幣 (直徑 2.4 cm)
- 信用卡 (8.5 x 5.4 cm)
- iPhone (14.7 x 7.1 cm)
- 原子筆 (14 x 1 cm)

## 資料模型

### DetectedObject

```swift
struct DetectedObject {
    let id: UUID
    let boundingBox: CGRect
    let objectType: ObjectType
    let confidence: Float
    let worldPosition: SCNVector3
    let dimensions: ObjectDimensions?
}
```

### ObjectDimensions

```swift
struct ObjectDimensions {
    let length: Float  // 公分
    let width: Float   // 公分
    let height: Float  // 公分
    let accuracy: Float // 0.0-1.0
    let measurementDate: Date
}
```

### ReferenceObject

```swift
struct ReferenceObject {
    let name: String
    let standardDimensions: ObjectDimensions
    let modelFileName: String
    let category: ObjectCategory
    let isCommonlyUsed: Bool
}
```

### MeasurementRecord

```swift
struct MeasurementRecord {
    let id: UUID
    let image: UIImage
    let detectedObjects: [DetectedObject]
    let referenceObject: ReferenceObject?
    let timestamp: Date
    let location: CLLocation?
}
```

## 錯誤處理

### 錯誤類型定義

```swift
enum MeasurementError: Error {
    case arSessionFailed
    case insufficientLighting
    case objectTooFar
    case objectTooClose
    case noPlaneDetected
    case lowConfidenceDetection
    case calibrationRequired
}
```

### 錯誤處理策略

1. **AR 會話錯誤**: 重新初始化 ARSession，提示使用者重新開始
2. **光線不足**: 顯示提示要求改善照明條件
3. **距離問題**: 引導使用者調整與物體的距離
4. **檢測信心度低**: 提供手動校準選項
5. **平面檢測失敗**: 引導使用者移動裝置尋找平面

## 測試策略

### 單元測試

- MeasurementCalculator 的尺寸計算邏輯
- ObjectDetector 的物體分類準確性
- ReferenceObjectManager 的物件選擇邏輯
- 資料模型的驗證和序列化

### 整合測試

- ARKit 與 Vision 框架的整合
- Core ML 模型載入和推論
- 相機權限和 ARKit 權限處理
- 資料持久化和檢索

### 使用者介面測試

- 相機預覽和拍照功能
- 測量結果顯示和互動
- 設定頁面和偏好設定
- 分享功能和匯出選項

### 效能測試

- Core ML 模型推論時間 (目標: <500ms)
- AR 渲染效能 (目標: 60fps)
- 記憶體使用量監控
- 電池消耗測試

### 準確性測試

- 已知尺寸物體的測量準確性驗證
- 不同距離和角度的測量一致性
- 各種光線條件下的效能
- 參考物件校準的有效性

## 技術考量

### ARKit 最佳實踐

- 使用 ARWorldTrackingConfiguration 進行 6DOF 追蹤
- 實作 ARSessionDelegate 處理會話狀態
- 利用 ARPlaneAnchor 進行平面檢測
- 適當的座標系轉換和單位處理

### Core ML 優化

- 模型量化減少檔案大小
- 批次處理提升推論效率
- 背景佇列處理避免 UI 阻塞
- 模型快取和預載入策略

### 使用者體驗

- 載入狀態和進度指示器
- 直觀的手勢控制
- 清晰的視覺回饋
- 離線功能支援

### 隱私和安全

- 本地處理避免資料上傳
- 相機權限適當請求和處理
- 使用者資料加密儲存
- 符合 App Store 審查指南
