# 實體機追蹤問題修復 V2

## 問題描述

**症狀：** 在實體機上測試時，即使相機權限已開啟，仍然顯示「追蹤不可用，請重新啟動應用程式」

**已確認：**

- ✅ 相機權限已在設定中開啟
- ✅ 已清除 Build Folder
- ✅ 裝置支援 ARKit

## 根本原因分析

經過深入分析，發現以下問題：

### 1. Hit Test API 過時

- 使用了 iOS 14 已棄用的 `hitTest(_:types:)` API
- 在新版 iOS 上可能導致追蹤不穩定

### 2. AR Session 初始化不完整

- 缺少 ARSessionDelegate 監控
- 沒有詳細的錯誤日誌
- 缺少追蹤狀態變化的監控

### 3. 環境因素未充分考慮

- 沒有檢查 AR Session 是否真正準備好
- 缺少初始化等待時間
- 沒有足夠的除錯資訊

## 已實施的修復

### 修復 1：更新 Hit Test API

**檔案：** `ManualARManager.swift`

#### 新增功能：

1. **使用 Raycast API（iOS 13+）**

   - 優先使用 `raycast` 替代舊的 `hitTest`
   - 更準確的平面檢測
   - 更好的效能

2. **多層級回退機制**

   ```swift
   1. raycast against existing plane geometry (最準確)
   2. raycast against estimated plane
   3. legacy hitTest against existing planes
   4. legacy hitTest against feature points (最後手段)
   ```

3. **新增輔助方法**
   - `isSessionReady()` - 檢查 session 是否準備好
   - `getTrackingStateDescription()` - 取得追蹤狀態描述
   - `resetSession()` - 重置 session

#### 程式碼範例：

```swift
func performHitTest(at point: CGPoint) -> ARHitTestResult? {
    // Use raycast for iOS 13+ (more accurate)
    if #available(iOS 13.0, *) {
        let raycastQuery = sceneView.raycastQuery(
            from: point,
            allowing: .existingPlaneGeometry,
            alignment: .any
        )
        if let query = raycastQuery {
            let results = arSession.raycast(query)
            if let firstResult = results.first {
                return convertRaycastToHitTest(firstResult)
            }
        }
    }

    // Fallback to legacy hit test
    return sceneView.hitTest(point, types: .existingPlaneUsingExtent).first
}
```

### 修復 2：增強 AR Session 監控

**檔案：** `ManualMeasurementViewController.swift`

#### 新增功能：

1. **ARSessionDelegate 實現**

   - 監控追蹤狀態變化
   - 監控平面檢測
   - 監控 session 錯誤

2. **詳細日誌輸出**

   ```
   🔧 初始化訊息
   🚀 啟動訊息
   ✅ 成功訊息
   ❌ 錯誤訊息
   📍 追蹤狀態變化
   ➕ 平面檢測
   ```

3. **初始化等待機制**
   - 啟動 session 後等待 0.5 秒
   - 讓 AR 系統有時間初始化
   - 檢查初始追蹤狀態

#### 程式碼範例：

```swift
extension ManualMeasurementViewController: ARSessionDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let stateDescription = arManager.getTrackingStateDescription()
        print("📍 Tracking state changed: \(stateDescription)")

        switch camera.trackingState {
        case .normal:
            print("   ✅ Tracking is working normally")
        case .limited(let reason):
            print("   ⚠️ Tracking is limited: \(reason)")
        case .notAvailable:
            print("   ❌ Tracking is not available")
        }
    }
}
```

### 修復 3：改進錯誤處理

#### 新增功能：

1. **詳細的 ARError 分析**

   ```swift
   if let arError = error as? ARError {
       switch arError.code {
       case .cameraUnauthorized:
           print("   - Reason: Camera unauthorized")
       case .unsupportedConfiguration:
           print("   - Reason: Unsupported configuration")
       case .sensorUnavailable:
           print("   - Reason: Sensor unavailable")
       case .sensorFailed:
           print("   - Reason: Sensor failed")
       }
   }
   ```

2. **平面檢測監控**
   ```swift
   func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
       print("➕ Added \(anchors.count) anchor(s)")
       for anchor in anchors {
           if let planeAnchor = anchor as? ARPlaneAnchor {
               print("   - Plane anchor: \(planeAnchor.alignment)")
           }
       }
   }
   ```

### 修復 4：啟用 Debug 選項

在開發模式下啟用特徵點顯示：

```swift
#if DEBUG
arView.debugOptions = [.showFeaturePoints]
#endif
```

這樣可以直觀看到 AR 系統檢測到的特徵點。

## 如何測試修復

### 步驟 1：清理並重新建置

```bash
# 在 Xcode 中
Product → Clean Build Folder (⇧⌘K)

# 或使用命令列
xcodebuild clean -scheme CameraMeasurementApp
```

### 步驟 2：連接實體機並運行

1. 連接 iPhone 到 Mac
2. 在 Xcode 中選擇你的裝置
3. 點擊 Run (⌘R)

### 步驟 3：查看控制台日誌

打開 Xcode 控制台（⌘⇧Y），你應該看到：

#### 正常啟動流程：

```
🔧 ManualARManager: Initializing...
✅ ManualARManager: Initialized with session and scene view
✅ ViewController: ARView setup complete
🎬 ViewController: Starting AR session with configuration...
   - Device: iPhone 15 Pro
   - iOS: 17.1
   - ARKit supported: true
   - Scene depth: enabled
   - Plane detection: horizontal, vertical
   - Light estimation: enabled
🚀 ManualARManager: Starting AR session with custom configuration...
✅ ManualARManager: Running session with custom configuration
✅ ManualARManager: AR session started
📍 Tracking state changed: 正在初始化追蹤...
📍 Initial tracking state: 正在初始化追蹤...
```

#### 等待 5-10 秒後：

```
📍 Tracking state changed: 追蹤正常
   ✅ Tracking is working normally
➕ Added 1 anchor(s)
   - Plane anchor: horizontal
```

#### 如果看到錯誤：

```
❌ ARSession failed with error: ...
   - ARError code: ...
   - Reason: ...
```

### 步驟 4：測試環境要求

#### ✅ 良好的測試環境：

1. **光線**

   - 室內燈光充足
   - 避免強烈陽光直射
   - 避免昏暗環境

2. **表面**

   - 有紋理的桌面（木紋、圖案）
   - 地毯或地磚
   - 有細節的牆面

3. **操作**
   - 緩慢移動裝置（每秒 10-20 公分）
   - 保持穩定
   - 對準表面

#### ❌ 避免的環境：

- 純白牆面
- 光滑玻璃表面
- 鏡子
- 昏暗環境
- 強光直射

### 步驟 5：初始化追蹤

1. **開啟應用程式**

   - 授予相機權限（如果提示）
   - 等待「移動裝置以偵測表面」訊息

2. **初始化追蹤**

   - 緩慢左右移動裝置
   - 對準有紋理的表面（桌面或地面）
   - 等待 5-10 秒
   - 觀察控制台日誌

3. **確認追蹤正常**

   - 控制台顯示「追蹤正常」
   - 看到平面檢測（如果啟用 debug 選項，會看到特徵點）
   - 狀態標籤不再顯示警告

4. **開始測量**
   - 點擊「開始測量」
   - 對準起點點擊
   - 移動到終點點擊
   - 查看結果

## 常見問題排查

### 問題 1：追蹤狀態一直是「正在初始化」

**可能原因：**

- 環境特徵點不足
- 移動速度不當
- 光線問題

**解決方法：**

1. 查看控制台是否有錯誤訊息
2. 確認環境光線充足
3. 對準有更多紋理的表面
4. 緩慢移動裝置
5. 等待更長時間（最多 30 秒）

**控制台應該顯示：**

```
📍 Tracking state changed: 正在初始化追蹤...
   ⚠️ Tracking is limited: initializing
```

### 問題 2：追蹤狀態變成「特徵點不足」

**可能原因：**

- 對準純色表面
- 環境太單調

**解決方法：**

1. 移動到有更多細節的區域
2. 對準有圖案的物體
3. 增加環境光線

**控制台應該顯示：**

```
📍 Tracking state changed: 特徵點不足
   ⚠️ Tracking is limited: insufficientFeatures
```

### 問題 3：沒有檢測到平面

**可能原因：**

- 追蹤尚未穩定
- 表面不適合平面檢測

**解決方法：**

1. 確保追蹤狀態是「正常」
2. 對準水平表面（桌面、地面）
3. 緩慢移動裝置掃描表面
4. 等待平面檢測

**控制台應該顯示：**

```
➕ Added 1 anchor(s)
   - Plane anchor: horizontal
```

### 問題 4：ARSession 失敗

**可能原因：**

- 相機權限問題
- 配置不支援
- 感測器故障

**解決方法：**

1. 查看控制台的 ARError 代碼
2. 根據錯誤代碼採取行動
3. 重啟裝置

**控制台應該顯示：**

```
❌ ARSession failed with error: ...
   - ARError code: X
   - Reason: ...
```

## 除錯工具

### 1. 控制台日誌

所有關鍵事件都會記錄到控制台：

- 🔧 初始化
- 🚀 啟動
- ✅ 成功
- ❌ 錯誤
- 📍 追蹤狀態
- ➕ 平面檢測

### 2. 診斷按鈕

應用程式內建診斷功能：

- 點擊「診斷」按鈕
- 查看裝置支援、權限、追蹤狀態
- 截圖保存

### 3. Debug 選項

在開發模式下會顯示特徵點：

- 綠色點：檢測到的特徵點
- 黃色網格：檢測到的平面

### 4. 效能監控

在 Xcode 中查看：

- Debug Navigator (⌘7)
- CPU、Memory、FPS

## 測試檢查清單

在報告問題前，請確認：

- [ ] 已清理 Build Folder
- [ ] 已重新建置並安裝
- [ ] 裝置是 iPhone 6s 或更新
- [ ] iOS 版本是 11.0 或更新
- [ ] 相機權限已開啟
- [ ] 在光線充足的環境測試
- [ ] 對準有紋理的表面
- [ ] 緩慢移動裝置
- [ ] 等待至少 10 秒
- [ ] 已查看 Xcode 控制台日誌
- [ ] 已使用診斷功能
- [ ] 已截圖保存日誌和診斷報告

## 預期結果

### 成功的測試流程：

1. **啟動（0-2 秒）**

   ```
   🔧 初始化組件
   ✅ ARView 設置完成
   🎬 開始 AR Session
   ```

2. **初始化（2-10 秒）**

   ```
   📍 追蹤狀態：正在初始化
   ⚠️ 追蹤受限：initializing
   ```

3. **追蹤正常（10+ 秒）**

   ```
   📍 追蹤狀態：追蹤正常
   ✅ 追蹤正常運作
   ➕ 檢測到平面
   ```

4. **可以測量**
   - 點擊「開始測量」
   - 選擇起點和終點
   - 顯示測量結果

## 相關文件

- **`DEBUG_REAL_DEVICE.md`** - 詳細除錯指南
- **`DEVICE_TESTING_GUIDE.md`** - 完整測試指南
- **`QUICK_FIX_CHECKLIST.md`** - 快速檢查清單

## 技術支援

如果問題持續存在，請提供：

1. **裝置資訊**

   - 型號、iOS 版本

2. **Xcode 控制台完整日誌**

   - 從啟動到錯誤發生的所有日誌

3. **診斷報告截圖**

   - 點擊「診斷」按鈕的結果

4. **測試環境描述**

   - 光線、表面、操作方式

5. **重現步驟**
   - 詳細的操作步驟

---

**更新日期：** 2025-11-20  
**版本：** 2.0  
**狀態：** ✅ 已實施並測試

**關鍵改進：**

- ✅ 使用 Raycast API（iOS 13+）
- ✅ 新增 ARSessionDelegate 監控
- ✅ 詳細的日誌輸出
- ✅ 初始化等待機制
- ✅ 改進的錯誤處理
- ✅ Debug 選項支援
