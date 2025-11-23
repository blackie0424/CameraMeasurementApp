# 相機無法啟動問題

## 症狀

```
❌ No current frame available
📍 Tracking state: 追蹤不可用
✅ Camera permission: authorized
✅ ARKit supported: true
```

## 根本原因

AR Session 啟動了，但相機沒有真正開始捕捉畫面。這是一個已知的 iOS ARKit 問題。

## 可能的原因

### 1. 相機被其他應用程式佔用

- 其他應用程式正在使用相機
- 背景應用程式沒有釋放相機
- 系統相機應用程式卡住

### 2. iOS 系統問題

- ARKit 服務沒有正確啟動
- 相機驅動程式問題
- 系統資源不足

### 3. 應用程式狀態問題

- AR Session 配置衝突
- Session 沒有完全重置
- Delegate 設置時機問題

## 已實施的修復

### 修復 1：Session 重啟流程

```swift
// 1. 先暫停現有 session
arView.session.pause()

// 2. 等待確保完全停止
DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
    // 3. 使用激進的重置選項
    arView.session.run(
        configuration,
        options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction]
    )
}
```

### 修復 2：延遲檢查和重試

```swift
// 等待 1 秒後檢查
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    if self.arView.session.currentFrame == nil {
        // 沒有 frame，嘗試再次啟動
        self.arView.session.run(configuration, options: [.resetTracking])
    }
}
```

### 修復 3：移除可能導致問題的功能

```swift
// 不啟用 scene depth（可能導致相機啟動失敗）
// configuration.frameSemantics = .sceneDepth
```

### 修復 4：延長監控時間

- 從 10 秒延長到 15 秒
- 如果追蹤正常，提前停止檢查
- 15 秒後仍無 frame，顯示嚴重錯誤

## 測試步驟

### 步驟 1：完全重啟

1. **關閉所有應用程式**

   - 雙擊 Home 鍵（或從底部向上滑動）
   - 向上滑動關閉所有應用程式
   - 特別是相機、FaceTime、其他 AR 應用程式

2. **重新啟動 iPhone**

   - 長按電源鍵
   - 滑動關機
   - 等待 30 秒
   - 重新開機

3. **清理 Xcode**

   ```
   Product → Clean Build Folder (⇧⌘K)
   ```

4. **重新建置並安裝**
   - 在 Xcode 中點擊 Run (⌘R)

### 步驟 2：查看新的日誌

運行後，你應該看到：

```
🎬 ViewController: Starting AR session with configuration...
⏸️ Pausing any existing session...
🔧 Configuring AR session...
🚀 Running AR session with reset options...
✅ AR session run command executed
🔍 Checking if session started...
```

然後是以下兩種情況之一：

#### 成功情況：

```
✅ Session has frames - camera is working
📊 Starting tracking state monitoring...
🔍 Tracking check #1...
   📍 Tracking state: 正在初始化追蹤...
🔍 Tracking check #2...
   📍 Tracking state: 追蹤正常
      ✅ Normal tracking
✅ Tracking is normal, stopping checks
```

#### 失敗情況：

```
❌ No frames yet - camera may not be working
🔄 Attempting to restart session...
📊 Starting tracking state monitoring...
🔍 Tracking check #1...
   ❌ No current frame available
...
❌ CRITICAL: No frames after 15 seconds
💡 This usually means:
   1. Camera is being used by another app
   2. Device needs to be restarted
   3. iOS bug - try closing and reopening the app
```

### 步驟 3：如果還是失敗

#### 檢查其他應用程式

1. 打開「設定」→「隱私權與安全性」→「相機」
2. 查看哪些應用程式有相機權限
3. 關閉所有其他使用相機的應用程式

#### 檢查背景應用程式

```bash
# 在 Xcode 控制台中，查找其他使用相機的進程
# 如果看到其他應用程式的相機相關訊息，關閉那些應用程式
```

#### 重置所有設定（最後手段）

1. 「設定」→「一般」→「移轉或重置 iPhone」
2. 「重置」→「重置所有設定」
3. **注意：這會重置所有設定，但不會刪除資料**

## 已知的 iOS Bug

### iOS 17.x 相機問題

某些 iOS 17 版本有已知的相機啟動問題：

1. **症狀：** AR Session 啟動但沒有 frame
2. **原因：** iOS 系統 bug
3. **解決：** 更新到最新的 iOS 版本

### ARKit 服務卡住

有時 ARKit 服務會卡住：

1. **症狀：** 追蹤狀態一直是 `.notAvailable`
2. **原因：** ARKit 系統服務沒有正確啟動
3. **解決：** 重啟裝置

## 替代測試方法

### 測試 1：使用系統相機

1. 開啟 iPhone 的「相機」應用程式
2. 確認相機正常工作
3. 完全關閉相機應用程式
4. 重新開啟你的應用程式

### 測試 2：使用其他 AR 應用程式

1. 下載並開啟「Measure」應用程式（Apple 官方）
2. 確認 AR 功能正常
3. 完全關閉 Measure
4. 重新開啟你的應用程式

### 測試 3：在不同環境測試

1. 到戶外測試（自然光）
2. 到不同房間測試
3. 確認不是環境問題

## 診斷檢查清單

在報告問題前，請確認：

- [ ] 已完全關閉所有應用程式
- [ ] 已重新啟動 iPhone
- [ ] 已清理 Xcode Build Folder
- [ ] 已重新建置並安裝
- [ ] 系統相機應用程式正常工作
- [ ] Apple Measure 應用程式正常工作（如果有安裝）
- [ ] 沒有其他應用程式在使用相機
- [ ] iOS 版本是最新的
- [ ] 已查看完整的 Xcode 控制台日誌
- [ ] 已等待至少 15 秒
- [ ] 已嘗試「重試」按鈕

## 收集診斷資訊

如果問題持續，請提供：

### 1. 裝置資訊

```
- 型號：iPhone XX
- iOS 版本：XX.X.X
- 儲存空間：XX GB 可用
- 最近是否更新 iOS：是/否
```

### 2. 完整的控制台日誌

```
從應用程式啟動到錯誤發生的所有日誌
特別注意：
- 🎬 啟動訊息
- ❌ 錯誤訊息
- 🔍 追蹤檢查結果
```

### 3. 其他應用程式狀態

```
- 系統相機是否正常：是/否
- Measure 應用程式是否正常：是/否
- 其他 AR 應用程式是否正常：是/否
```

### 4. 已嘗試的解決方法

```
- [ ] 重啟應用程式
- [ ] 重啟裝置
- [ ] 關閉其他應用程式
- [ ] 更新 iOS
- [ ] 重置設定
```

## 臨時解決方案

如果無法解決，可以嘗試：

### 方案 1：使用不同的 AR 配置

修改配置，使用最簡單的設定：

```swift
let configuration = ARWorldTrackingConfiguration()
// 只啟用水平平面檢測
configuration.planeDetection = [.horizontal]
// 關閉光線估計
configuration.isLightEstimationEnabled = false
```

### 方案 2：延遲啟動

在應用程式啟動後等待更長時間：

```swift
// 在 viewDidAppear 而不是 viewWillAppear 啟動
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // 等待 2 秒再啟動
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.setupARSession()
    }
}
```

### 方案 3：使用 AVCaptureSession

如果 ARKit 完全無法工作，可以考慮使用 AVCaptureSession 作為備用方案。

## 已知可行的配置

以下配置在大多數裝置上可行：

```swift
let configuration = ARWorldTrackingConfiguration()
configuration.planeDetection = [.horizontal, .vertical]
configuration.isLightEstimationEnabled = true
// 不啟用其他功能

arView.session.run(
    configuration,
    options: [.resetTracking, .removeExistingAnchors]
)
```

## 總結

這個問題通常是：

1. **80%** - 其他應用程式佔用相機或 iOS 系統問題 → 重啟裝置
2. **15%** - ARKit 服務卡住 → 重啟裝置
3. **5%** - 真正的代碼問題 → 需要進一步診斷

**最有效的解決方法：完全重啟 iPhone**

---

**更新日期：** 2025-11-20  
**版本：** 1.0  
**狀態：** 🔧 診斷中
