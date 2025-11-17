# 相機測量應用程式導航流程文件

## 概述

本文件說明相機測量應用程式中所有視圖控制器之間的導航關係和 Segue 設定。

## 視圖控制器架構

### 1. ViewController (主相機畫面)

- **Storyboard ID**: `BYZ-38-t0r`
- **類別**: `ViewController`
- **功能**: 主要的相機測量介面
- **初始視圖控制器**: ✓

#### IBOutlets

- `arSceneView`: AR 場景容器視圖
- `captureButton`: 拍照測量按鈕
- `settingsButton`: 設定按鈕
- `statusLabel`: 狀態標籤
- `measurementOverlayView`: 測量覆蓋視圖
- `guidanceLabel`: 引導標籤

#### IBActions

- `captureButtonTapped(_:)`: 處理拍照按鈕點擊
- `settingsButtonTapped(_:)`: 處理設定按鈕點擊

#### Segues

1. **showResults**

   - 目標: `ResultsViewController`
   - 識別碼: `"showResults"`
   - 類型: Presentation (Full Screen)
   - 觸發: 程式化觸發（拍照完成後）
   - 資料傳遞: `MeasurementRecord` 物件

2. **showSettings**
   - 目標: `Settings Navigation Controller`
   - 識別碼: `"showSettings"`
   - 類型: Presentation (Page Sheet)
   - 觸發: 設定按鈕點擊
   - 資料傳遞: 無

---

### 2. ResultsViewController (測量結果畫面)

- **Storyboard ID**: `results-vc`
- **類別**: `ResultsViewController`
- **功能**: 顯示測量結果和標註

#### IBOutlets

- `resultImageView`: 結果影像視圖
- `measurementOverlayView`: 測量覆蓋視圖
- `referenceObjectView`: 參考物件視圖
- `measurementInfoView`: 測量資訊容器視圖
- `objectNameLabel`: 物體名稱標籤
- `dimensionsLabel`: 尺寸標籤
- `accuracyLabel`: 準確度標籤
- `referenceObjectLabel`: 參考物件標籤
- `changeReferenceButton`: 更換參考物件按鈕
- `saveButton`: 儲存按鈕
- `shareButton`: 分享按鈕
- `retakeButton`: 重新拍攝按鈕

#### IBActions

- `changeReferenceButtonTapped(_:)`: 更換參考物件
- `saveButtonTapped(_:)`: 儲存測量結果
- `shareButtonTapped(_:)`: 分享測量結果
- `retakeButtonTapped(_:)`: 返回相機畫面

#### 導航

- **返回主畫面**: 透過 `dismiss(animated:)` 關閉當前視圖

---

### 3. Settings Navigation Controller

- **Storyboard ID**: `settings-nav`
- **類別**: `UINavigationController`
- **功能**: 設定頁面的導航容器

#### Root View Controller

- `SettingsViewController`

---

### 4. SettingsViewController (設定畫面)

- **Storyboard ID**: `settings-vc`
- **類別**: `SettingsViewController`
- **功能**: 應用程式設定介面

#### IBOutlets

- `unitSegmentedControl`: 測量單位選擇控制項
- `defaultReferenceTableView`: 預設參考物件表格視圖
- `showGuidanceSwitch`: 顯示引導開關
- `autoSaveSwitch`: 自動儲存開關

#### IBActions

- `unitSegmentedControlChanged(_:)`: 測量單位變更
- `showGuidanceSwitchChanged(_:)`: 引導顯示開關變更
- `autoSaveSwitchChanged(_:)`: 自動儲存開關變更

#### 導航按鈕

- **左側**: 關閉按鈕 (Close) - 關閉設定頁面
- **右側**: 儲存按鈕 (Save) - 儲存設定並關閉

#### 導航

- **返回主畫面**: 透過 `dismiss(animated:)` 關閉導航控制器

---

## 導航流程圖

```
┌─────────────────────────────────────┐
│      ViewController (主畫面)         │
│                                     │
│  - AR 相機預覽                       │
│  - 拍照測量按鈕                      │
│  - 設定按鈕                          │
└─────────────────────────────────────┘
         │                    │
         │ showResults        │ showSettings
         │ (拍照完成)         │ (點擊設定按鈕)
         ▼                    ▼
┌──────────────────┐   ┌──────────────────────┐
│ ResultsView      │   │ Settings Navigation  │
│ Controller       │   │ Controller           │
│                  │   │  ┌────────────────┐  │
│ - 測量結果顯示   │   │  │ SettingsView   │  │
│ - 參考物件比較   │   │  │ Controller     │  │
│ - 儲存/分享      │   │  │                │  │
│ - 重新拍攝       │   │  │ - 測量單位     │  │
└──────────────────┘   │  │ - 參考物件     │  │
         │              │  │ - 其他設定     │  │
         │ dismiss      │  └────────────────┘  │
         │              └──────────────────────┘
         │                         │
         │                         │ dismiss
         ▼                         ▼
┌─────────────────────────────────────┐
│      ViewController (主畫面)         │
└─────────────────────────────────────┘
```

---

## Segue 識別碼清單

| 識別碼                | 來源                | 目標                   | 類型                       | 觸發方式 |
| --------------------- | ------------------- | ---------------------- | -------------------------- | -------- |
| `showResults`         | ViewController      | ResultsViewController  | Presentation (Full Screen) | 程式化   |
| `showSettings`        | ViewController      | Settings Navigation    | Presentation (Page Sheet)  | 按鈕點擊 |
| `settings-root-segue` | Settings Navigation | SettingsViewController | Relationship               | 自動     |

---

## 資料傳遞

### ViewController → ResultsViewController

透過 `prepare(for:sender:)` 方法傳遞：

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showResults",
       let resultsVC = segue.destination as? ResultsViewController,
       let record = sender as? MeasurementRecord {
        resultsVC.measurementRecord = record
    }
}
```

傳遞的資料：

- `MeasurementRecord`: 包含拍攝的影像、檢測到的物體和測量資料

### ViewController → SettingsViewController

無需傳遞資料，設定直接從 UserDefaults 讀取和儲存。

---

## 返回導航

### 從 ResultsViewController 返回

```swift
@IBAction func retakeButtonTapped(_ sender: UIButton) {
    dismiss(animated: true)
}
```

### 從 SettingsViewController 返回

```swift
@objc private func closeButtonTapped() {
    dismiss(animated: true, completion: nil)
}

@objc private func saveButtonTapped() {
    saveSettings()
    // 顯示確認對話框後關閉
    dismiss(animated: true, completion: nil)
}
```

---

## 測試檢查清單

- [x] ViewController 可以正確顯示為初始視圖控制器
- [x] 拍照按鈕可以觸發測量流程
- [x] 測量完成後可以正確導航到 ResultsViewController
- [x] ResultsViewController 可以接收並顯示 MeasurementRecord 資料
- [x] 設定按鈕可以開啟 SettingsViewController
- [x] SettingsViewController 以 Page Sheet 樣式呈現
- [x] 可以從 ResultsViewController 返回主畫面
- [x] 可以從 SettingsViewController 返回主畫面
- [x] 所有 IBOutlet 連接正確
- [x] 所有 IBAction 連接正確
- [x] Segue 識別碼設定正確
- [x] 專案建置成功無錯誤

---

## 注意事項

1. **Modal Presentation Style**:

   - ResultsViewController 使用 Full Screen 呈現，提供沉浸式的結果檢視體驗
   - SettingsViewController 使用 Page Sheet 呈現，保持輕量級的設定介面

2. **記憶體管理**:

   - 所有視圖控制器使用 weak self 避免循環引用
   - dismiss 時會自動釋放視圖控制器

3. **狀態保存**:

   - 設定資料透過 UserDefaults 持久化
   - 測量記錄在後續任務中會透過 Core Data 儲存

4. **錯誤處理**:
   - 所有導航操作都包含適當的錯誤處理
   - 使用 guard 語句確保資料完整性

---

## 未來擴展

以下功能將在後續任務中實作：

1. **測量歷史記錄頁面**:

   - 新增 HistoryViewController 顯示過往測量記錄
   - 從主畫面或設定頁面導航

2. **詳細說明頁面**:

   - 新增 HelpViewController 提供使用說明
   - 從設定頁面導航

3. **參考物件管理頁面**:
   - 新增 ReferenceObjectManagerViewController
   - 允許使用者自訂參考物件

---

**文件版本**: 1.0  
**最後更新**: 2024-11-17  
**維護者**: Camera Measurement Team
