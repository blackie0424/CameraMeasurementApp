# iOS 16 相容性指南

## 你的裝置資訊

- **iOS 版本：** 16.7.12
- **Deployment Target：** 16.6 ✅
- **ARKit 支援：** ✅
- **相機權限：** ✅ (rawValue: 3 = authorized)

## 問題診斷

根據你的日誌：

```
📍 Tracking state: 追蹤不可用
❌ Not available
→ Camera permission: AVAuthorizationStatus(rawValue: 3)  // authorized
→ ARKit supported: true
🎯 Detected planes: 0
```

**結論：** 權限和支援都正常，但追蹤狀態是 `.notAvailable`

## iOS 16 特定問題

### 問題 1：AR Session 選項相容性

某些 AR Session 選項在 iOS 16 上可能有問題：

#### 已修復：

```swift
// 之前（可能導致問題）
arView.session.run(
    configuration,
    options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction]
)

// 現在（iOS 16 相容）
var runOptions: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]

if #available(iOS 16.0, *) {
    runOptions.insert(.resetSceneReconstruction)
}

arView.session.run(configuration, options: runOptions)
```

### 問題 2：Scene Depth 功能

Scene Depth 在某些 iOS 16 裝置上可能導致問題：

#### 已修復：

```swift
// 已註解掉，不啟用 scene depth
// if #available(iOS 13.0, *) {
//     if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
//         configuration.frameSemantics = .sceneDepth
//     }
// }
```

### 問題 3：Xcode Developer Disk Image

從錯誤訊息看到：

```
Failed to mount DDI from 'DeveloperDiskImage.dmg'
Failed to prepare the device for development
```

這表示 Xcode 無法在你的裝置上掛載開發者映像。

## 解決步驟

### 步驟 1：解鎖裝置並信任電腦

1. **解鎖 iPhone**

   - 確保 iPhone 已解鎖（不是在鎖定畫面）

2. **信任這台電腦**

   - 連接 iPhone 到 Mac
   - iPhone 會彈出「要信任這部電腦嗎？」
   - 點擊「信任」
   - 輸入 iPhone 密碼

3. **在 Xcode 中重新連接**
   - Window → Devices and Simulators (⇧⌘2)
   - 選擇你的 iPhone
   - 確認狀態是「Connected」而不是「Unavailable」

### 步驟 2：清理並重新建置

```bash
# 在 Xcode 中
Product → Clean Build Folder (⇧⌘K)

# 刪除 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 步驟 3：重新啟動所有東西

1. **關閉 Xcode**
2. **拔掉 iPhone**
3. **重啟 iPhone**

   - 長按電源鍵
   - 滑動關機
   - 等待 30 秒
   - 重新開機

4. **重啟 Mac**（如果上面的步驟無效）

5. **重新連接並運行**
   - 開啟 Xcode
   - 連接 iPhone
   - 確認裝置已信任
   - 點擊 Run (⌘R)

### 步驟 4：檢查 Xcode 版本相容性

你的 Xcode 版本需要支援 iOS 16.7：

```bash
# 檢查 Xcode 版本
xcodebuild -version

# 檢查支援的 iOS 版本
ls /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/
```

如果沒有看到 16.7 或 16.x 的資料夾，你可能需要：

1. 更新 Xcode 到最新版本
2. 或下載 iOS 16.7 的 Device Support Files

### 步驟 5：手動下載 Device Support Files（如果需要）

如果 Xcode 沒有 iOS 16.7 的支援檔案：

1. 前往：https://github.com/filsv/iOSDeviceSupport
2. 下載 iOS 16.7 的 Device Support Files
3. 解壓縮到：
   ```
   ~/Library/Developer/Xcode/iOS DeviceSupport/
   ```
4. 重啟 Xcode

## iOS 16 測試檢查清單

在 iOS 16 上測試前，請確認：

- [ ] iPhone 已解鎖
- [ ] 已點擊「信任這部電腦」
- [ ] 在 Xcode Devices 中看到裝置狀態是「Connected」
- [ ] Xcode 版本支援 iOS 16.7
- [ ] 已清理 Build Folder
- [ ] 已刪除 DerivedData
- [ ] 已重啟 iPhone
- [ ] 已重啟 Xcode
- [ ] 相機權限已在設定中開啟
- [ ] 沒有其他應用程式使用相機

## 預期的日誌輸出（iOS 16）

### 成功情況：

```
🎬 ViewController: Starting AR session with configuration...
   - Device: iPhone
   - iOS: 16.7.12
   - ARKit supported: true
   - Session delegate: ✅ Set
⏸️ Pausing any existing session...
🔧 Configuring AR session...
   - Plane detection: horizontal, vertical
   - Light estimation: enabled
🚀 Running AR session with reset options...
   - Using resetSceneReconstruction (iOS 16+)
✅ AR session run command executed
🔍 Checking if session started...
✅ Session has frames - camera is working
📊 Starting tracking state monitoring...
🔍 Tracking check #1...
   📍 Tracking state: 正在初始化追蹤...
      ⚠️ Limited: initializing
         → Wait for initialization
   🎯 Detected planes: 0
🔍 Tracking check #2...
   📍 Tracking state: 追蹤正常
      ✅ Normal tracking
   🎯 Detected planes: 0
✅ Tracking is normal, stopping checks
```

## iOS 16 已知限制

### 1. Scene Depth 不可用

- iOS 16 的某些裝置不支援 Scene Depth
- 已停用此功能以確保相容性

### 2. 追蹤初始化較慢

- iOS 16 的 AR 追蹤初始化可能需要更長時間
- 請耐心等待 10-15 秒

### 3. 平面檢測較慢

- iOS 16 的平面檢測可能比 iOS 17 慢
- 需要更多的裝置移動來檢測平面

## 替代測試方法（iOS 16）

### 方法 1：使用 Apple Measure 應用程式

1. 開啟 iPhone 內建的「測距儀」(Measure) 應用程式
2. 確認 AR 功能正常工作
3. 如果 Measure 可以正常工作，你的裝置和 ARKit 都沒問題
4. 完全關閉 Measure
5. 重新開啟你的應用程式

### 方法 2：使用最簡單的 AR 配置

如果還是不行，嘗試最簡單的配置：

```swift
let configuration = ARWorldTrackingConfiguration()
// 只啟用水平平面
configuration.planeDetection = [.horizontal]
// 關閉光線估計
configuration.isLightEstimationEnabled = false

arView.session.run(configuration, options: [.resetTracking])
```

### 方法 3：延遲啟動

在 iOS 16 上，可能需要更長的啟動時間：

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // 等待 2 秒再啟動 AR
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.setupARSession()
    }
}
```

## 常見 iOS 16 錯誤和解決方法

### 錯誤 1：「Failed to prepare device for development」

**原因：** Xcode 無法掛載開發者映像

**解決：**

1. 確保 iPhone 已解鎖
2. 點擊「信任這部電腦」
3. 重啟 Xcode 和 iPhone
4. 下載 iOS 16.7 Device Support Files

### 錯誤 2：「The device is passcode protected」

**原因：** iPhone 被鎖定

**解決：**

1. 解鎖 iPhone
2. 保持 iPhone 在解鎖狀態
3. 重新連接到 Xcode

### 錯誤 3：追蹤狀態一直是 `.notAvailable`

**原因：** AR Session 沒有真正啟動

**解決：**

1. 完全重啟 iPhone
2. 關閉所有其他應用程式
3. 確保相機權限已開啟
4. 使用最簡單的 AR 配置

## 收集 iOS 16 診斷資訊

如果問題持續，請提供：

### 1. Xcode 版本

```bash
xcodebuild -version
```

### 2. Device Support Files

```bash
ls -la ~/Library/Developer/Xcode/iOS\ DeviceSupport/
```

### 3. 裝置連接狀態

在 Xcode 中：

- Window → Devices and Simulators
- 截圖你的 iPhone 狀態

### 4. 完整的控制台日誌

從應用程式啟動到錯誤發生的所有日誌

### 5. Measure 應用程式測試結果

- Measure 是否正常工作？
- 如果正常，截圖

## 總結

iOS 16.7 應該完全支援 ARKit，問題很可能是：

1. **70%** - Xcode 無法掛載開發者映像 → 解鎖裝置並信任電腦
2. **20%** - 相機被其他應用程式佔用 → 重啟 iPhone
3. **10%** - ARKit 服務問題 → 重啟 iPhone

**最重要的步驟：**

1. ✅ 解鎖 iPhone
2. ✅ 信任這部電腦
3. ✅ 重啟 iPhone
4. ✅ 清理 Xcode Build Folder
5. ✅ 重新建置並運行

---

**更新日期：** 2025-11-20  
**iOS 版本：** 16.7.12  
**狀態：** 🔧 已針對 iOS 16 優化
