# 設計文件

## 概述

本設計文件描述 AR 平面偵測與測量準確性改進功能的實現方案。目前系統存在兩個關鍵問題：(1) 測量線條在相機角度改變時會飄移，(2) 測量距離嚴重不準確。這些問題源於缺少穩定的空間參考平面。本設計引入完整的平面偵測流程，類似 Apple 測距儀，確保測量點錨定在真實世界的穩定表面上。

**需求覆蓋：**

- 需求 1：平面偵測模式與狀態提示
- 需求 2：平面視覺化與即時更新
- 需求 3：測量點必須在已偵測平面上
- 需求 4：測量點錨定到平面，防止飄移
- 需求 5：追蹤品質監控與警告
- 需求 6：使用真實 3D 座標計算距離
- 需求 7：平面偵測確認機制

**核心設計決策：**

- 採用兩階段流程：平面偵測階段 → 測量階段，確保測量前已建立穩定的空間錨點 _[需求 1, 7]_
- 測量點必須錨定到 ARPlaneAnchor，而非僅使用 hit test 結果，解決飄移問題 _[需求 4]_
- 使用 ARPlaneAnchor 的 transform 計算世界座標，確保距離準確性 _[需求 6]_
- 平面視覺化提供即時回饋，讓使用者了解可測量的表面 _[需求 2]_
- 追蹤品質監控確保測量可靠性 _[需求 5]_

## 架構

### 系統組件

```
┌─────────────────────────────────────────────────────────┐
│           ManualMeasurementViewController                │
│  - 管理測量流程狀態機                                      │
│  - 協調平面偵測與測量階段                                  │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┬──────────────┐
        │                 │                 │              │
        ▼                 ▼                 ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ PlaneDetection│  │  ARManager   │  │ Measurement  │  │   Tracking   │
│   Manager    │  │              │  │   Renderer   │  │   Quality    │
│              │  │ - AR Session │  │              │  │   Monitor    │
│ - 平面追蹤   │  │ - Hit Test   │  │ - 平面視覺化 │  │              │
│ - 狀態管理   │  │ - 錨點管理   │  │ - 測量線渲染 │  │ - 品質監控   │
│ - 啟用條件   │  │              │  │ - 游標回饋   │  │ - 警告顯示   │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

**設計理由：**

- 分離平面偵測邏輯到專門的 PlaneDetectionManager，便於管理複雜的偵測狀態
- TrackingQualityMonitor 獨立監控追蹤品質，確保測量可靠性
- ARManager 擴展支援 ARPlaneAnchor 管理，提供穩定的空間錨點
- Renderer 負責所有視覺回饋，包括平面視覺化和游標狀態

### 測量流程狀態機

```
┌──────────────────┐
│  PlaneDetection  │ AR Session 啟動
│   (偵測階段)     │ 顯示「正在偵測平面...」
│                  │ 測量按鈕禁用
└────────┬─────────┘
         │ 偵測到足夠平面
         │ (≥2 個平面或面積 ≥0.5m²)
         ▼
┌──────────────────┐
│  PlaneDetected   │ 顯示「已偵測 X 個平面」
│   (準備測量)     │ 測量按鈕啟用
└────────┬─────────┘
         │ 使用者點擊「開始測量」
         ▼
┌──────────────────┐
│  MeasurementMode │ 固定平面
│   (測量中)       │ 停止新平面視覺化
│                  │ 允許放置測量點
└────────┬─────────┘
         │ 使用者點擊「重新偵測」
         ▼
   (回到 PlaneDetection)
```

## 組件與介面

### 1. PlaneDetectionManager

管理平面偵測流程、狀態和啟用條件。

```swift
enum PlaneDetectionState {
    case detecting              // 正在偵測
    case ready                  // 已偵測足夠平面，可開始測量
    case measurementMode        // 測量模式，平面已固定
}

class PlaneDetectionManager {
    private(set) var state: PlaneDetectionState = .detecting
    private var detectedPlanes: [ARPlaneAnchor] = []

    // 平面管理
    func addPlane(_ anchor: ARPlaneAnchor)
    func updatePlane(_ anchor: ARPlaneAnchor)
    func removePlane(_ anchor: ARPlaneAnchor)

    // 狀態檢查
    func checkReadyCondition() -> Bool
    func getTotalPlaneArea() -> Float
    func getPlaneCount() -> Int

    // 狀態轉換
    func enterMeasurementMode()
    func resetDetection()
}
```

**職責：**

- 追蹤所有偵測到的 ARPlaneAnchor _[需求 1, 2]_
- 計算平面總面積和數量 _[需求 1.5, 7.2]_
- 判斷是否滿足測量啟用條件（≥2 個平面或總面積 ≥0.5m²）_[需求 1.5, 7.2]_
- 管理偵測狀態轉換 _[需求 7]_

**設計決策：**

- 使用 ARPlaneAnchor 的 extent 屬性計算面積：`extent.x * extent.z` _[需求 1.5]_
- 在測量模式下停止接受新平面，確保測量環境穩定 _[需求 7.4]_
- 提供重置功能允許重新偵測 _[需求 7.5]_

### 2. ARManager (擴展)

擴展現有 ARManager 以支援平面錨點管理和錨定測量點。

```swift
class ManualARManager {
    private var arSession: ARSession
    private var sceneView: ARSCNView
    private var planeAnchors: [UUID: ARPlaneAnchor] = [:]

    // 平面相關
    func getPlaneAnchor(for hitResult: ARHitTestResult) -> ARPlaneAnchor?
    func worldPosition(from anchor: ARPlaneAnchor, localPoint: simd_float3) -> SCNVector3

    // Hit Test（優先平面）
    func performHitTestOnPlanes(at screenPoint: CGPoint) -> (result: ARHitTestResult, anchor: ARPlaneAnchor)?

    // 錨定測量點
    func createAnchoredPoint(on anchor: ARPlaneAnchor, at localPosition: simd_float3) -> AnchoredMeasurementPoint
}

struct AnchoredMeasurementPoint {
    let planeAnchor: ARPlaneAnchor
    let localPosition: simd_float3    // 相對於平面的局部座標

    func worldPosition() -> SCNVector3 {
        // 使用 planeAnchor.transform 轉換局部座標到世界座標
    }
}
```

**設計理由：**

- Hit test 優先檢測 existingPlaneUsingExtent，確保測量點在已知平面上 _[需求 3.1, 3.2]_
- 測量點儲存平面錨點引用和局部座標，而非僅世界座標 _[需求 4.1, 4.3]_
- 使用 ARPlaneAnchor.transform 動態計算世界座標，確保平面更新時測量點跟隨 _[需求 4.2, 4.4]_

### 3. TrackingQualityMonitor

監控 AR 追蹤品質並提供警告。

```swift
enum TrackingQuality {
    case normal
    case limited(ARCamera.TrackingState.Reason)
    case notAvailable
}

class TrackingQualityMonitor {
    private(set) var currentQuality: TrackingQuality = .notAvailable
    var onQualityChanged: ((TrackingQuality) -> Void)?

    func updateTrackingState(_ camera: ARCamera)
    func isMeasurementAllowed() -> Bool
    func getWarningMessage() -> String?
}
```

**職責：**

- 監控 ARCamera.trackingState _[需求 5.1]_
- 判斷是否允許測量（只有 normal 狀態允許）_[需求 5.3]_
- 提供適當的警告訊息 _[需求 5.2]_
- 通知 UI 更新追蹤品質狀態 _[需求 5.4, 5.5]_

### 4. MeasurementRenderer (擴展)

擴展現有 Renderer 以支援平面視覺化和游標狀態回饋。

```swift
class MeasurementRenderer {
    private var sceneView: ARSCNView
    private var planeNodes: [UUID: SCNNode] = [:]
    private var reticleView: UIView?

    // 平面視覺化
    func visualizePlane(_ anchor: ARPlaneAnchor)
    func updatePlaneVisualization(_ anchor: ARPlaneAnchor)
    func removePlaneVisualization(_ anchor: ARPlaneAnchor)
    func setPlaneColor(_ color: UIColor, for anchor: ARPlaneAnchor)

    // 游標狀態
    func updateReticleColor(_ color: UIColor)
    func setReticleState(_ state: ReticleState)

    // 測量線（使用錨定點）
    func drawLine(from startPoint: AnchoredMeasurementPoint,
                  to endPoint: AnchoredMeasurementPoint)
}

enum ReticleState {
    case onPlane        // 綠色
    case offPlane       // 紅色
    case disabled       // 灰色
}
```

**視覺規格：**

- 水平平面：藍色 (RGB: 0.2, 0.5, 1.0)，透明度 0.3 _[需求 2.2]_
- 垂直平面：綠色 (RGB: 0.2, 1.0, 0.5)，透明度 0.3 _[需求 2.3]_
- 追蹤品質不佳時：黃色 (RGB: 1.0, 0.8, 0.0)，透明度 0.3 _[需求 5.5]_
- 平面網格：使用 SCNPlane 幾何體，大小匹配 anchor.extent _[需求 2.1, 2.4]_
- 游標：綠色表示對準平面，紅色表示未對準 _[需求 3.4, 3.5]_

**渲染優化：**

- 平面視覺化使用 SCNPlane，根據 anchor.extent 動態調整大小 _[需求 2.4]_
- 平面移除時使用淡出動畫（2 秒）_[需求 2.5]_
- 游標顏色即時更新，提供流暢的視覺回饋 _[需求 3.4, 3.5]_

## 資料模型

### AnchoredMeasurementPoint

```swift
struct AnchoredMeasurementPoint {
    let id: UUID
    let planeAnchor: ARPlaneAnchor
    let localPosition: simd_float3    // 相對於平面的局部座標
    let timestamp: Date

    func worldPosition() -> SCNVector3 {
        // 使用 planeAnchor.transform 計算世界座標
        let worldTransform = planeAnchor.transform
        let localPoint = simd_float4(localPosition.x, localPosition.y, localPosition.z, 1.0)
        let worldPoint = worldTransform * localPoint
        return SCNVector3(worldPoint.x, worldPoint.y, worldPoint.z)
    }
}
```

**設計考量：**

- 儲存平面錨點引用，確保測量點跟隨平面更新 _[需求 4.1, 4.4]_
- 使用局部座標而非世界座標，解決飄移問題 _[需求 4.2]_
- worldPosition() 動態計算，確保相機角度改變時位置正確 _[需求 4.2]_

### PlaneInfo

```swift
struct PlaneInfo {
    let anchor: ARPlaneAnchor
    let area: Float               // 平面面積（平方公尺）
    let type: PlaneType           // 水平或垂直
    let detectionTime: Date

    var isHorizontal: Bool {
        return anchor.alignment == .horizontal
    }

    var isVertical: Bool {
        return anchor.alignment == .vertical
    }
}

enum PlaneType {
    case horizontal
    case vertical
}
```

### MeasurementResult (更新)

```swift
struct MeasurementResult {
    let startPoint: AnchoredMeasurementPoint
    let endPoint: AnchoredMeasurementPoint
    let distance: Float           // 單位：公尺

    var distanceInCm: Float {
        return distance * 100
    }

    var distanceFormatted: String {
        return String(format: "%.1f cm", distanceInCm)
    }

    func calculate3DDistance() -> Float {
        let start = startPoint.worldPosition()
        let end = endPoint.worldPosition()
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}
```

**設計理由：**

- 使用錨定測量點確保距離計算基於穩定的 3D 座標 _[需求 6.1]_
- 歐幾里得距離公式提供準確的 3D 距離 _[需求 6.2]_
- 格式化為公分並保留一位小數 _[需求 6.5]_

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property Reflection

在定義具體的 correctness properties 之前，我們需要識別並消除冗餘的屬性：

**識別的冗餘：**

1. 需求 1.5 和 7.2 描述相同的啟用條件邏輯，可以合併為一個屬性
2. 需求 2.2 和 2.3 都是測試平面渲染顏色，可以合併為一個屬性測試「平面類型到顏色的映射」
3. 需求 3.4 和 3.5 都是測試游標顏色，可以合併為一個屬性測試「平面對準狀態到游標顏色的映射」
4. 需求 5.2 和 5.3 都是測試追蹤品質不佳時的行為，可以合併為一個屬性
5. 需求 6.1、6.2 和 6.3 都是關於距離計算方法，可以合併為一個屬性驗證「使用世界座標的歐幾里得距離」

**保留的獨特屬性：**

- 平面偵測啟用條件（合併 1.5 和 7.2）
- 平面視覺化創建
- 平面類型到顏色映射（合併 2.2 和 2.3）
- 平面視覺化更新
- Hit test 優先平面
- 平面命中時放置測量點
- 平面未命中時拒絕測量點
- 游標顏色回饋（合併 3.4 和 3.5）
- 測量點錨定到平面
- 相機角度改變時座標穩定性
- 使用平面錨點座標系統
- 平面更新時測量點跟隨
- 測量線兩端都錨定
- 追蹤品質不佳時的行為（合併 5.2 和 5.3）
- 追蹤品質不佳時平面變黃色
- 3D 距離計算（合併 6.1、6.2、6.3）
- 跨平面距離計算
- 距離格式化
- 偵測進度顯示

### Correctness Properties

Property 1: 平面偵測啟用條件
_For any_ 偵測到的平面集合，當平面總面積 ≥ 0.5 平方公尺或平面數量 ≥ 2 時，測量功能應該被啟用
**Validates: Requirements 1.5, 7.2**

Property 2: 平面視覺化創建
_For any_ 新偵測到的平面，系統應該創建對應的視覺化節點並添加到場景中
**Validates: Requirements 2.1**

Property 3: 平面類型到顏色映射
_For any_ 偵測到的平面，水平平面應該渲染為藍色（透明度 0.3），垂直平面應該渲染為綠色（透明度 0.3）
**Validates: Requirements 2.2, 2.3**

Property 4: 平面視覺化更新
_For any_ 平面範圍更新事件，對應的視覺化節點大小和形狀應該更新以匹配新的平面範圍
**Validates: Requirements 2.4**

Property 5: Hit test 優先平面
_For any_ hit test 請求，當場景中同時存在平面和特徵點時，應該優先返回平面的 hit test 結果
**Validates: Requirements 3.1**

Property 6: 平面命中時放置測量點
_For any_ hit test 結果命中已偵測平面的情況，系統應該成功創建並放置測量點
**Validates: Requirements 3.2**

Property 7: 平面未命中時拒絕測量點
_For any_ hit test 結果未命中任何已偵測平面的情況，系統應該拒絕放置測量點並顯示提示訊息
**Validates: Requirements 3.3**

Property 8: 游標顏色回饋
_For any_ 游標狀態，當對準有效平面時游標應該為綠色，未對準時應該為紅色
**Validates: Requirements 3.4, 3.5**

Property 9: 測量點錨定到平面
_For any_ 成功放置的測量點，該點應該包含對應 Plane Anchor 的引用
**Validates: Requirements 4.1**

Property 10: 相機角度改變時座標穩定性
_For any_ 已放置的測量點，在相機角度改變前後，其世界座標應該保持不變（誤差 < 1mm）
**Validates: Requirements 4.2**

Property 11: 使用平面錨點座標系統
_For any_ 測量點，其世界座標應該通過 Plane Anchor 的 transform 矩陣計算得出，而非直接使用 hit test 結果
**Validates: Requirements 4.3**

Property 12: 平面更新時測量點跟隨
_For any_ 錨定在平面上的測量點，當平面位置或範圍更新時，測量點的世界座標應該相應調整
**Validates: Requirements 4.4**

Property 13: 測量線兩端都錨定
_For any_ 完整的測量（包含起點和終點），兩個測量點都應該錨定在有效的平面上
**Validates: Requirements 4.5**

Property 14: 追蹤品質不佳時的行為
_For any_ 追蹤狀態為 limited 或 notAvailable 的情況，系統應該顯示警告訊息並禁用測量點放置功能
**Validates: Requirements 5.2, 5.3**

Property 15: 追蹤品質不佳時平面變黃色
_For any_ 追蹤狀態為 limited 或 notAvailable 的情況，所有平面視覺化的顏色應該變更為黃色
**Validates: Requirements 5.5**

Property 16: 3D 距離計算
_For any_ 兩個測量點，計算的距離應該等於使用歐幾里得公式 sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²) 基於世界座標計算的結果（誤差 < 0.1mm）
**Validates: Requirements 6.1, 6.2, 6.3**

Property 17: 跨平面距離計算
_For any_ 位於不同平面上的兩個測量點，系統應該能夠計算跨平面的真實 3D 距離
**Validates: Requirements 6.4**

Property 18: 距離格式化
_For any_ 距離值，顯示格式應該為公分單位，保留一位小數（例如 "45.3 cm"）
**Validates: Requirements 6.5**

Property 19: 偵測進度顯示
_For any_ 偵測到的平面數量 N，UI 應該顯示「已偵測 N 個平面」
**Validates: Requirements 7.3**

## 錯誤處理

### 錯誤類型

```swift
enum PlaneDetectionError: Error {
    case noPlaneDetected
    case insufficientPlaneArea
    case trackingQualityPoor
    case hitTestFailedNoPlane
    case invalidAnchorReference
}
```

### 錯誤處理策略

1. **無平面偵測**

   - 顯示提示：「正在偵測平面，請緩慢移動裝置」_[需求 1.2]_
   - 保持測量按鈕禁用狀態 _[需求 7.1]_
   - 持續嘗試偵測，不中斷流程

2. **Hit Test 未命中平面** _[需求 3.3]_

   - 顯示提示：「請將游標對準已偵測的平面」
   - 游標變為紅色提供視覺回饋 _[需求 3.5]_
   - 不放置測量點，保持當前狀態

3. **追蹤品質不佳** _[需求 5.2, 5.3]_

   - 顯示警告：「追蹤品質不佳，請改善光線或移動到特徵豐富的環境」
   - 禁用測量點放置功能
   - 平面視覺化變為黃色 _[需求 5.5]_
   - 等待追蹤品質恢復

4. **平面錨點失效**
   - 檢測 ARPlaneAnchor 是否仍在 session 中
   - 如果錨點失效，標記對應的測量點為無效
   - 顯示警告：「測量點錨點失效，請重新測量」

## 測試策略

### 單元測試

1. **PlaneDetectionManager 測試**

   - 測試平面面積計算
   - 測試啟用條件邏輯（≥2 個平面或面積 ≥0.5m²）
   - 測試狀態轉換

2. **AnchoredMeasurementPoint 測試**

   - 測試世界座標計算
   - 使用已知的 transform 矩陣驗證座標轉換
   - 測試局部座標到世界座標的正確性

3. **距離計算測試**

   - 使用已知座標驗證歐幾里得距離公式
   - 測試跨平面距離計算
   - 測試距離格式化

4. **TrackingQualityMonitor 測試**
   - 測試追蹤狀態到品質等級的映射
   - 測試測量允許條件
   - 測試警告訊息生成

### Property-Based Testing

本設計使用 Swift 的 property-based testing 框架 **swift-check** 來驗證 correctness properties。

**框架配置：**

- 使用 swift-check (https://github.com/typelift/SwiftCheck)
- 每個 property test 運行至少 100 次迭代
- 每個 property test 必須標註對應的設計文件屬性編號

**Property Test 標註格式：**

```swift
// Feature: ar-plane-detection-accuracy, Property 1: 平面偵測啟用條件
func testPlaneDetectionEnableCondition() {
    // test implementation
}
```

**測試覆蓋的 Properties：**

1. Property 1: 平面偵測啟用條件 - 生成隨機平面集合，驗證啟用邏輯
2. Property 3: 平面類型到顏色映射 - 生成隨機平面類型，驗證顏色映射
3. Property 8: 游標顏色回饋 - 生成隨機游標狀態，驗證顏色
4. Property 10: 相機角度改變時座標穩定性 - 生成隨機相機角度，驗證座標不變
5. Property 16: 3D 距離計算 - 生成隨機測量點，驗證距離計算公式
6. Property 18: 距離格式化 - 生成隨機距離值，驗證格式化輸出
7. Property 19: 偵測進度顯示 - 生成隨機平面數量，驗證顯示文字

**測試生成器：**

```swift
// 平面生成器
extension ARPlaneAnchor: Arbitrary {
    public static var arbitrary: Gen<ARPlaneAnchor> {
        return Gen.compose { c in
            let extent = simd_float3(
                c.generate(using: Gen.fromElements(of: 0.1...5.0)),
                0,
                c.generate(using: Gen.fromElements(of: 0.1...5.0))
            )
            let alignment = c.generate(using: Gen.fromElements(of: [
                ARPlaneAnchor.Alignment.horizontal,
                ARPlaneAnchor.Alignment.vertical
            ]))
            // 創建模擬的 ARPlaneAnchor
        }
    }
}

// 測量點生成器
extension AnchoredMeasurementPoint: Arbitrary {
    public static var arbitrary: Gen<AnchoredMeasurementPoint> {
        return Gen.compose { c in
            let anchor = c.generate()
            let localPos = simd_float3(
                c.generate(using: Gen.fromElements(of: -1.0...1.0)),
                c.generate(using: Gen.fromElements(of: -1.0...1.0)),
                c.generate(using: Gen.fromElements(of: -1.0...1.0))
            )
            return AnchoredMeasurementPoint(
                id: UUID(),
                planeAnchor: anchor,
                localPosition: localPos,
                timestamp: Date()
            )
        }
    }
}
```

### 整合測試

1. **平面偵測流程整合**

   - 模擬 ARSession 偵測平面的過程
   - 驗證狀態轉換和 UI 更新
   - 測試從偵測到測量的完整流程

2. **測量點錨定整合**

   - 測試測量點放置和錨定
   - 驗證相機移動時測量點位置穩定
   - 測試平面更新時測量點跟隨

3. **追蹤品質監控整合**
   - 模擬不同的追蹤品質狀態
   - 驗證 UI 警告和功能禁用
   - 測試品質恢復後的功能恢復

### 手動測試場景

1. **平面偵測流程**

   - 啟動應用程式，驗證顯示「正在偵測平面...」
   - 緩慢移動裝置掃描環境
   - 驗證平面視覺化出現（藍色或綠色網格）
   - 確認偵測到足夠平面後測量按鈕啟用
   - 驗證顯示「已偵測 X 個平面」

2. **測量準確性驗證**

   - 使用實體尺規測量已知距離（例如 50cm）
   - 在應用程式中測量相同距離
   - 比對結果，驗證誤差 < 2%
   - 改變相機角度，確認測量線不飄移
   - 驗證顯示的距離保持穩定

3. **游標回饋測試**

   - 將游標對準已偵測平面，驗證變為綠色
   - 將游標對準空白區域，驗證變為紅色
   - 嘗試在紅色游標狀態下放置測量點，驗證被拒絕

4. **追蹤品質測試**

   - 在光線不足環境測試，驗證顯示警告
   - 驗證平面視覺化變為黃色
   - 確認測量功能被禁用
   - 移動到光線充足環境，驗證警告消失

5. **跨平面測量**
   - 在一個水平平面上放置起點
   - 在另一個垂直平面上放置終點
   - 驗證能夠計算跨平面距離
   - 確認距離計算正確

### 效能測試

- 監控平面視覺化的渲染效能（目標：60 FPS）
- 測試大量平面（10+ 個）時的效能
- 驗證長時間運行的記憶體穩定性
- 測試平面更新的即時性

## 實現注意事項

### AR Session 配置

```swift
let configuration = ARWorldTrackingConfiguration()
configuration.planeDetection = [.horizontal, .vertical]
configuration.isLightEstimationEnabled = true
configuration.environmentTexturing = .automatic
```

**理由：**

- 啟用水平和垂直平面檢測 _[需求 1, 2]_
- 光線估計改善視覺效果
- 環境紋理提升平面視覺化品質

### ARSessionDelegate 實現

```swift
func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for anchor in anchors {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            planeDetectionManager.addPlane(planeAnchor)
            renderer.visualizePlane(planeAnchor)
        }
    }
}

func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    for anchor in anchors {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            planeDetectionManager.updatePlane(planeAnchor)
            renderer.updatePlaneVisualization(planeAnchor)
        }
    }
}

func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    for anchor in anchors {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            planeDetectionManager.removePlane(planeAnchor)
            renderer.removePlaneVisualization(planeAnchor)
        }
    }
}
```

### Hit Test 實現

```swift
func performHitTestOnPlanes(at screenPoint: CGPoint) -> (result: ARHitTestResult, anchor: ARPlaneAnchor)? {
    // 優先檢測已存在的平面
    let results = sceneView.hitTest(screenPoint, types: .existingPlaneUsingExtent)

    for result in results {
        if let planeAnchor = result.anchor as? ARPlaneAnchor {
            return (result, planeAnchor)
        }
    }

    return nil
}
```

**設計理由：**

- 只使用 existingPlaneUsingExtent，確保測量點在已知平面上 _[需求 3.1, 3.2]_
- 不使用 featurePoint，避免測量點放置在不穩定的位置
- 返回 ARPlaneAnchor 引用，用於錨定測量點 _[需求 4.1]_

### 測量點錨定實現

```swift
func createAnchoredPoint(on anchor: ARPlaneAnchor, at hitResult: ARHitTestResult) -> AnchoredMeasurementPoint {
    // 將世界座標轉換為平面的局部座標
    let worldPosition = hitResult.worldTransform.columns.3
    let planeTransform = anchor.transform
    let planeInverse = simd_inverse(planeTransform)
    let localPosition = planeInverse * worldPosition

    return AnchoredMeasurementPoint(
        id: UUID(),
        planeAnchor: anchor,
        localPosition: simd_float3(localPosition.x, localPosition.y, localPosition.z),
        timestamp: Date()
    )
}
```

**設計理由：**

- 儲存局部座標而非世界座標 _[需求 4.3]_
- 使用逆矩陣轉換世界座標到局部座標
- 確保平面更新時測量點能正確跟隨 _[需求 4.4]_

### 距離計算實現

```swift
func calculate3DDistance(from start: AnchoredMeasurementPoint, to end: AnchoredMeasurementPoint) -> Float {
    // 動態獲取當前世界座標
    let startWorld = start.worldPosition()
    let endWorld = end.worldPosition()

    // 歐幾里得距離
    let dx = endWorld.x - startWorld.x
    let dy = endWorld.y - startWorld.y
    let dz = endWorld.z - startWorld.z

    return sqrt(dx*dx + dy*dy + dz*dz)
}
```

**設計理由：**

- 使用動態計算的世界座標，確保準確性 _[需求 6.1]_
- 標準歐幾里得距離公式 _[需求 6.2]_
- 支援跨平面測量 _[需求 6.4]_

### 效能優化

1. **平面視覺化優化**

   - 使用 SCNPlane 而非複雜的網格幾何體
   - 限制平面視覺化數量（最多顯示 10 個最大的平面）
   - 使用 LOD（Level of Detail）根據距離調整視覺化細節

2. **更新節流**

   - 平面視覺化更新限制為 30 FPS
   - 游標顏色更新限制為 60 FPS
   - 避免每幀都執行 hit test

3. **記憶體管理**
   - 移除的平面視覺化及時釋放
   - 使用 weak 引用避免循環引用
   - 定期清理不再追蹤的平面錨點

### 使用者體驗細節

1. **視覺回饋**

   - 平面偵測到時播放輕微的觸覺回饋
   - 測量點放置成功時播放音效
   - 追蹤品質變化時提供觸覺警告

2. **提示訊息**

   - 使用半透明背景的浮動標籤
   - 自動淡入淡出動畫
   - 不遮擋中心游標和測量區域

3. **平面視覺化**
   - 使用柔和的顏色和適當的透明度
   - 平面邊緣使用抗鋸齒
   - 平面出現和消失使用淡入淡出動畫

## 未來擴展考量

本設計預留以下擴展空間：

1. **平面合併**

   - 檢測相鄰的平面並合併為更大的平面
   - 提高測量範圍和準確性

2. **平面語義識別**

   - 識別平面類型（地板、牆壁、桌面等）
   - 根據平面類型提供不同的測量建議

3. **多點測量**

   - 在穩定的平面基礎上支援多點測量
   - 計算面積和體積

4. **測量歷史與平面關聯**

   - 儲存測量結果與對應的平面資訊
   - 支援在相同平面上重複測量

5. **AR 錨點持久化**
   - 儲存平面錨點到 ARWorldMap
   - 支援跨 session 的測量恢復
