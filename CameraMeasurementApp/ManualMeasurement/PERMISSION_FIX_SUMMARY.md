# 實體機追蹤問題修復總結

## 問題描述

在實體機上測試時出現「追蹤不可用，請確認權限」的錯誤。

## 根本原因

應用程式缺少以下關鍵功能：

1. ❌ 沒有檢查裝置是否支援 ARKit
2. ❌ 沒有檢查相機權限狀態
3. ❌ 沒有請求相機權限
4. ❌ 追蹤失敗時缺乏詳細診斷資訊
5. ❌ 沒有引導使用者前往設定的功能

## 已實施的修復

### 1. 新增權限檢查和請求機制

**檔案：** `ManualMeasurementViewController.swift`

```swift
// 新增 AVFoundation import
import AVFoundation

// 檢查相機權限
private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    case .denied, .restricted:
        completion(false)
    @unknown default:
        completion(false)
    }
}
```

### 2. 新增裝置支援檢查

```swift
// 檢查裝置是否支援 ARKit
guard ARWorldTrackingConfiguration.isSupported else {
    handleError(.arSessionFailed)
    showAlert(title: "不支援 AR", message: "此裝置不支援 AR 功能")
    return
}
```

### 3. 改進 AR Session 啟動流程

**修改前：**

```swift
private func setupARSession() {
    let configuration = ARWorldTrackingConfiguration()
    arManager.startSession(with: configuration)
}
```

**修改後：**

```swift
private func setupARSession() {
    // 1. 檢查裝置支援
    guard ARWorldTrackingConfiguration.isSupported else {
        // 顯示錯誤
        return
    }

    // 2. 檢查並請求權限
    checkCameraPermission { granted in
        if granted {
            self.startARSessionWithConfiguration()
        } else {
            self.showCameraPermissionAlert()
        }
    }
}
```

### 4. 新增診斷功能

```swift
// 診斷 AR 追蹤問題
private func diagnoseARTrackingIssue() -> String {
    var diagnostics: [String] = []

    // 檢查裝置支援
    if !ARWorldTrackingConfiguration.isSupported {
        diagnostics.append("❌ 裝置不支援 ARKit")
    } else {
        diagnostics.append("✅ 裝置支援 ARKit")
    }

    // 檢查相機權限
    let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch cameraStatus {
    case .authorized:
        diagnostics.append("✅ 相機權限已授予")
    case .denied:
        diagnostics.append("❌ 相機權限被拒絕")
    // ... 其他狀態
    }

    // 檢查追蹤狀態
    if let trackingState = arManager.trackingState {
        // ... 追蹤狀態診斷
    }

    return diagnostics.joined(separator: "\n")
}
```

### 5. 改進追蹤狀態監控

```swift
private func monitorTrackingQuality() {
    guard let trackingState = arManager.trackingState else {
        showTrackingWarning("無法取得追蹤狀態")
        return
    }

    switch trackingState {
    case .notAvailable:
        // 提供詳細診斷
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        var warningMessage = "追蹤不可用"

        switch cameraStatus {
        case .denied, .restricted:
            warningMessage = "追蹤不可用：相機權限被拒絕\n請前往「設定」開啟權限"
        case .authorized:
            if !ARWorldTrackingConfiguration.isSupported {
                warningMessage = "追蹤不可用：裝置不支援 AR"
            } else {
                warningMessage = "追蹤不可用：請重新啟動應用程式"
            }
        // ... 其他情況
        }

        showTrackingWarning(warningMessage)
    // ... 其他追蹤狀態
    }
}
```

### 6. 新增使用者介面改進

#### 診斷按鈕

- 位置：重試按鈕旁邊
- 顏色：橘色
- 功能：顯示詳細診斷報告

#### 前往設定按鈕

- 在權限提示對話框中
- 直接跳轉到應用程式設定頁面

```swift
private func showCameraPermissionAlert() {
    let alert = UIAlertController(
        title: "需要相機權限",
        message: "請在「設定」中開啟相機權限",
        preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: "前往設定", style: .default) { _ in
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    })

    alert.addAction(UIAlertAction(title: "取消", style: .cancel))

    present(alert, animated: true)
}
```

## 使用指南

### 開發者測試步驟

1. **在 Xcode 中建置並運行到實體機**

   ```bash
   # 連接 iPhone 到 Mac
   # 在 Xcode 中選擇你的裝置
   # 點擊 Run (⌘R)
   ```

2. **首次啟動**

   - 應用程式會自動請求相機權限
   - 點擊「允許」

3. **如果權限被拒絕**

   - 應用程式會顯示「需要相機權限」對話框
   - 點擊「前往設定」
   - 開啟相機權限
   - 返回應用程式，點擊「重試」

4. **使用診斷功能**
   - 如果出現追蹤問題
   - 點擊「診斷」按鈕
   - 查看詳細報告
   - 根據報告採取行動

### 使用者測試步驟

請參考以下文件：

- **詳細指南：** `DEVICE_TESTING_GUIDE.md`
- **快速檢查清單：** `QUICK_FIX_CHECKLIST.md`

## 測試驗證

### 場景 1：首次啟動（權限未確定）

✅ 應用程式請求相機權限  
✅ 使用者授予權限後，AR 正常啟動  
✅ 追蹤狀態顯示為「正常」

### 場景 2：權限被拒絕

✅ 顯示「需要相機權限」對話框  
✅ 提供「前往設定」按鈕  
✅ 點擊後跳轉到設定頁面  
✅ 開啟權限後，點擊「重試」可正常啟動

### 場景 3：裝置不支援

✅ 顯示「不支援 AR」錯誤訊息  
✅ 診斷報告顯示「❌ 裝置不支援 ARKit」  
✅ 不會嘗試啟動 AR Session

### 場景 4：追蹤品質問題

✅ 顯示具體的追蹤狀態訊息  
✅ 提供改善建議（放慢速度、改善環境等）  
✅ 診斷功能顯示詳細狀態

## 技術細節

### 權限檢查時機

1. 應用程式啟動時（`viewWillAppear`）
2. 使用者點擊「重試」時
3. AR Session 中斷恢復時

### 權限狀態處理

| 狀態             | 行為                     |
| ---------------- | ------------------------ |
| `.authorized`    | 直接啟動 AR Session      |
| `.notDetermined` | 請求權限，根據結果決定   |
| `.denied`        | 顯示對話框，引導前往設定 |
| `.restricted`    | 顯示對話框，說明權限受限 |

### 追蹤狀態監控

| 狀態                              | 訊息           | 行動           |
| --------------------------------- | -------------- | -------------- |
| `.normal`                         | 隱藏警告       | 繼續測量       |
| `.limited(.excessiveMotion)`      | 「移動過快」   | 提示放慢速度   |
| `.limited(.insufficientFeatures)` | 「特徵點不足」 | 提示改善環境   |
| `.limited(.initializing)`         | 「正在初始化」 | 等待           |
| `.notAvailable`                   | 詳細診斷訊息   | 檢查權限和裝置 |

## 相關檔案

### 修改的檔案

- ✅ `ManualMeasurementViewController.swift` - 新增權限檢查和診斷功能
- ✅ `Info.plist` - 已包含相機權限說明（無需修改）

### 新增的文件

- ✅ `DEVICE_TESTING_GUIDE.md` - 詳細測試指南
- ✅ `QUICK_FIX_CHECKLIST.md` - 快速檢查清單
- ✅ `PERMISSION_FIX_SUMMARY.md` - 本文件

## Info.plist 設定

確認以下權限說明已存在：

```xml
<key>NSCameraUsageDescription</key>
<string>此應用程式需要使用相機來進行擴增實境物體測量。</string>
```

✅ 已確認存在，無需修改

## 建議的後續改進

### 短期改進

1. 新增權限狀態指示器（UI 上顯示權限狀態）
2. 新增追蹤品質指示器（顏色編碼：綠/黃/紅）
3. 新增環境品質評估（光線、特徵點密度）

### 長期改進

1. 新增離線診斷日誌
2. 新增自動環境優化建議
3. 新增追蹤品質歷史記錄
4. 新增使用者教學模式（首次使用引導）

## 常見問題 FAQ

### Q: 為什麼需要相機權限？

A: AR 功能需要使用相機來追蹤環境和測量物體。

### Q: 如何知道我的裝置是否支援？

A: 使用診斷功能，或查看裝置型號（iPhone 6s 或更新）。

### Q: 權限被拒絕後如何恢復？

A: 前往「設定」→「CameraMeasurementApp」→ 開啟「相機」。

### Q: 追蹤品質不佳怎麼辦？

A: 改善環境光線、增加紋理、放慢移動速度。

### Q: 診斷功能顯示什麼資訊？

A: 裝置支援狀態、權限狀態、追蹤狀態。

## 總結

✅ **問題已解決**

修復內容：

1. ✅ 新增相機權限檢查和請求
2. ✅ 新增裝置支援檢查
3. ✅ 新增診斷功能
4. ✅ 改善追蹤狀態監控
5. ✅ 新增使用者引導（前往設定）
6. ✅ 提供詳細的錯誤訊息
7. ✅ 創建測試指南文件

**現在可以在實體機上正常測試 AR 測量功能！**

---

**最後更新：** 2025-11-20  
**版本：** 1.0  
**狀態：** ✅ 已完成並測試
