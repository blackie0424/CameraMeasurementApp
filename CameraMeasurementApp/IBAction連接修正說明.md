# IBAction 連接修正說明

## 問題描述

在測試第一階段功能時，點擊「拍照測量」按鈕會導致應用程式崩潰，錯誤訊息如下：

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException',
reason: '-[CameraMeasurementApp.ViewController captureButtonTappedWithSender:]:
unrecognized selector sent to instance 0x101823e00'
```

## 問題原因

Storyboard 中的 IBAction 連接使用了 Objective-C 風格的方法名稱（例如 `captureButtonTappedWithSender:`），但 Swift 程式碼中的方法簽名是 `captureButtonTapped(_:)`。

這是因為 Swift 和 Objective-C 的方法命名慣例不同：

- **Objective-C 風格**：`captureButtonTappedWithSender:`
- **Swift 風格**：`captureButtonTapped(_:)`

## 修正內容

### 1. ViewController.swift

#### 修正前（Storyboard）：

```xml
<action selector="captureButtonTappedWithSender:" destination="BYZ-38-t0r" eventType="touchUpInside"/>
<action selector="settingsButtonTappedWithSender:" destination="BYZ-38-t0r" eventType="touchUpInside"/>
```

#### 修正後（Storyboard）：

```xml
<action selector="captureButtonTapped:" destination="BYZ-38-t0r" eventType="touchUpInside"/>
<action selector="settingsButtonTapped:" destination="BYZ-38-t0r" eventType="touchUpInside"/>
```

#### Swift 程式碼（保持不變）：

```swift
@IBAction func captureButtonTapped(_ sender: UIButton) { ... }
@IBAction func settingsButtonTapped(_ sender: UIButton) { ... }
```

---

### 2. ResultsViewController.swift

#### 修正前（Storyboard）：

```xml
<action selector="saveButtonTappedWithSender:" destination="results-vc" eventType="touchUpInside"/>
<action selector="shareButtonTappedWithSender:" destination="results-vc" eventType="touchUpInside"/>
<action selector="retakeButtonTappedWithSender:" destination="results-vc" eventType="touchUpInside"/>
<action selector="changeReferenceButtonTappedWithSender:" destination="results-vc" eventType="touchUpInside"/>
```

#### 修正後（Storyboard）：

```xml
<action selector="saveButtonTapped:" destination="results-vc" eventType="touchUpInside"/>
<action selector="shareButtonTapped:" destination="results-vc" eventType="touchUpInside"/>
<action selector="retakeButtonTapped:" destination="results-vc" eventType="touchUpInside"/>
<action selector="changeReferenceButtonTapped:" destination="results-vc" eventType="touchUpInside"/>
```

#### Swift 程式碼（保持不變）：

```swift
@IBAction func saveButtonTapped(_ sender: UIButton) { ... }
@IBAction func shareButtonTapped(_ sender: UIButton) { ... }
@IBAction func retakeButtonTapped(_ sender: UIButton) { ... }
@IBAction func changeReferenceButtonTapped(_ sender: UIButton) { ... }
```

---

### 3. SettingsViewController.swift

#### 修正前（Storyboard）：

```xml
<action selector="unitSegmentedControlChangedWithSender:" destination="settings-vc" eventType="valueChanged"/>
<action selector="showGuidanceSwitchChangedWithSender:" destination="settings-vc" eventType="valueChanged"/>
<action selector="autoSaveSwitchChangedWithSender:" destination="settings-vc" eventType="valueChanged"/>
```

#### 修正後（Storyboard）：

```xml
<action selector="unitSegmentedControlChanged:" destination="settings-vc" eventType="valueChanged"/>
<action selector="showGuidanceSwitchChanged:" destination="settings-vc" eventType="valueChanged"/>
<action selector="autoSaveSwitchChanged:" destination="settings-vc" eventType="valueChanged"/>
```

#### Swift 程式碼（保持不變）：

```swift
@IBAction func unitSegmentedControlChanged(_ sender: UISegmentedControl) { ... }
@IBAction func showGuidanceSwitchChanged(_ sender: UISwitch) { ... }
@IBAction func autoSaveSwitchChanged(_ sender: UISwitch) { ... }
```

---

## 修正總結

### 修正的連接數量

- **ViewController**: 2 個 IBAction
- **ResultsViewController**: 4 個 IBAction
- **SettingsViewController**: 3 個 IBAction
- **總計**: 9 個 IBAction 連接

### 修正規則

Swift 中的 IBAction 方法簽名：

```swift
@IBAction func methodName(_ sender: UIButton)
```

對應的 Storyboard selector 應該是：

```xml
<action selector="methodName:" destination="..." eventType="..."/>
```

**注意**：

- Swift 方法名稱後面只需要一個冒號 `:`
- 不需要 `WithSender` 後綴
- 參數名稱使用下劃線 `_` 表示外部參數名稱被省略

---

## 驗證結果

### 建置狀態

✅ **BUILD SUCCEEDED**

### 診斷檢查

✅ 所有檔案無診斷錯誤

### 測試狀態

✅ 應用程式可以正常啟動
✅ 拍照按鈕可以正常點擊
✅ 所有按鈕和控制項都能正常運作

---

## 預防措施

為了避免未來出現類似問題，建議：

1. **使用 Xcode Interface Builder 連接**

   - 在 Storyboard 中按住 Ctrl 拖曳到程式碼
   - Xcode 會自動產生正確的連接

2. **檢查連接**

   - 在 Storyboard 中選擇視圖控制器
   - 開啟 Connections Inspector
   - 確認所有 IBAction 連接正確

3. **命名慣例**

   - 使用 Swift 標準命名慣例
   - 避免手動編輯 Storyboard XML

4. **建置前測試**
   - 每次修改 Storyboard 後都要建置
   - 檢查是否有連接警告

---

## 相關文件

- [Swift IBAction 文件](https://developer.apple.com/documentation/uikit/ibaction)
- [Storyboard 連接指南](https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaApp/Storyboard.html)

---

**修正日期**: 2024-11-17  
**修正者**: Kiro AI Assistant  
**狀態**: ✅ 已完成並驗證
