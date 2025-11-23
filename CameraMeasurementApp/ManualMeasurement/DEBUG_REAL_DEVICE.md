# 實體機除錯指南

## 問題：權限已開啟但追蹤仍然不可用

如果你已經確認相機權限已開啟，但仍然看到「追蹤不可用，請重新啟動應用程式」，請按照以下步驟除錯。

## 🔍 除錯步驟

### 步驟 1：查看 Xcode 控制台日誌

1. 在 Xcode 中連接你的 iPhone
2. 運行應用程式 (⌘R)
3. 打開 Xcode 底部的控制台（View → Debug Area → Activate Console）
4. 查找以下關鍵訊息：

#### 正常啟動的日誌應該是：

```
🔧 ManualARManager: Initializing...
✅ ManualARManager: Initialized with session and scene view
✅ ViewController: ARView setup complete
🎬 ViewController: Starting AR session with configuration...
   - Device: iPhone
   - iOS: 17.x
   - ARKit supported: true
   - Plane detection: horizontal, vertical
   - Light estimation: enabled
🚀 ManualARManager: Starting AR session with custom configuration...
✅ ManualARManager: Running session with custom configuration
✅ ManualARManager: AR session started
📍 Tracking state changed: 正在初始化追蹤...
📍 Tracking state changed: 追蹤正常
➕ Added 1 anchor(s)
   - Plane anchor: horizontal
```

#### 如果看到錯誤：

```
❌ ARSession failed with error: ...
   - ARError code: ...
   - Reason: ...
```

### 步驟 2：檢查錯誤代碼

根據 ARError 代碼判斷問題：

| 錯誤代碼                   | 原因           | 解決方法           |
| -------------------------- | -------------- | ------------------ |
| `cameraUnauthorized`       | 相機權限未授予 | 前往設定開啟權限   |
| `unsupportedConfiguration` | 配置不支援     | 檢查裝置型號       |
| `sensorUnavailable`        | 感測器不可用   | 重啟裝置           |
| `sensorFailed`             | 感測器失敗     | 重啟裝置或聯絡支援 |

### 步驟 3：使用診斷功能

1. 在應用程式中點擊「診斷」按鈕
2. 查看診斷報告
3. 截圖保存

### 步驟 4：檢查環境

即使權限正確，環境也會影響追蹤：

#### ✅ 良好的測試環境：

- 📍 室內環境
- 💡 光線充足（自然光或室內燈光）
- 🎨 有紋理的表面（書桌、地毯、牆面）
- 🌡️ 室溫環境（不要太熱或太冷）

#### ❌ 不良的測試環境：

- 🌞 強烈陽光直射
- 🌑 光線昏暗
- ⬜ 純白牆面或光滑表面
- 🪞 鏡子或反光表面
- 🌊 移動的物體（水面、窗簾）

### 步驟 5：檢查裝置狀態

1. **電量**：確保電量 > 20%
2. **溫度**：裝置不要過熱
3. **儲存空間**：確保有足夠空間
4. **相機鏡頭**：清潔鏡頭，移除保護殼

### 步驟 6：重置 AR Session

如果追蹤狀態一直是「正在初始化」：

1. 點擊「重試」按鈕
2. 緩慢移動裝置（左右、上下）
3. 對準有紋理的表面
4. 等待 5-10 秒

### 步驟 7：完全重啟

1. **關閉應用程式**

   - 雙擊 Home 鍵（或從底部向上滑動）
   - 向上滑動關閉應用程式

2. **重新啟動 iPhone**

   - 長按電源鍵
   - 滑動關機
   - 等待 10 秒
   - 重新開機

3. **重新安裝應用程式**
   - 在 Xcode 中 Product → Clean Build Folder (⇧⌘K)
   - 刪除裝置上的應用程式
   - 重新建置並安裝

## 🐛 常見問題和解決方案

### 問題 1：追蹤狀態一直是「正在初始化」

**原因：**

- 環境特徵點不足
- 移動速度不當
- 光線問題

**解決：**

1. 緩慢移動裝置（每秒移動 10-20 公分）
2. 對準有紋理的表面（書桌、地毯）
3. 確保光線充足
4. 等待 10-15 秒

### 問題 2：追蹤狀態變成「特徵點不足」

**原因：**

- 對準純色表面
- 光線不足
- 環境太單調

**解決：**

1. 移動到有更多細節的區域
2. 對準有圖案或紋理的物體
3. 增加環境光線
4. 避免純白牆面

### 問題 3：追蹤狀態變成「移動過快」

**原因：**

- 裝置移動速度過快
- 手持不穩定

**解決：**

1. 放慢移動速度
2. 保持裝置穩定
3. 使用雙手持握
4. 考慮使用三腳架

### 問題 4：追蹤狀態變成「追蹤不可用」

**原因：**

- 相機被遮擋
- 感測器故障
- 系統資源不足

**解決：**

1. 檢查相機鏡頭是否被遮擋
2. 關閉其他應用程式
3. 重啟裝置
4. 檢查 iOS 更新

### 問題 5：應用程式崩潰

**原因：**

- 記憶體不足
- AR Session 配置錯誤
- 系統 bug

**解決：**

1. 查看 Xcode 崩潰日誌
2. 關閉其他應用程式
3. 重啟裝置
4. 更新 iOS 到最新版本

## 📊 效能監控

### 查看效能指標

在 Xcode 中：

1. Debug Navigator (⌘7)
2. 查看 CPU、Memory、Energy 使用情況

### 正常效能範圍：

- **FPS：** 30-60 FPS
- **Memory：** < 200 MB
- **CPU：** < 50%

### 如果效能不佳：

1. 關閉 Debug 選項（`arView.debugOptions`）
2. 關閉其他應用程式
3. 重啟裝置

## 🔧 進階除錯

### 啟用詳細日誌

在 `ManualARManager.swift` 和 `ManualMeasurementViewController.swift` 中已經添加了詳細的 print 語句。

### 查看 AR Session 配置

在控制台中查找：

```
🎬 ViewController: Starting AR session with configuration...
   - Device: ...
   - iOS: ...
   - ARKit supported: ...
   - Scene depth: ...
   - Plane detection: ...
   - Light estimation: ...
```

### 監控追蹤狀態變化

在控制台中查找：

```
📍 Tracking state changed: ...
```

### 監控平面檢測

在控制台中查找：

```
➕ Added X anchor(s)
   - Plane anchor: horizontal/vertical
```

## 📝 收集除錯資訊

如果問題持續存在，請收集以下資訊：

### 1. 裝置資訊

```
- 裝置型號：iPhone XX
- iOS 版本：XX.X
- 可用儲存空間：XX GB
- 電量：XX%
```

### 2. 環境資訊

```
- 測試地點：室內/室外
- 光線條件：充足/昏暗/強光
- 表面類型：書桌/地板/牆面
- 溫度：正常/過熱
```

### 3. Xcode 控制台日誌

```
複製完整的控制台輸出，特別是：
- 🔧 初始化訊息
- ❌ 錯誤訊息
- 📍 追蹤狀態變化
```

### 4. 診斷報告截圖

```
點擊「診斷」按鈕後的截圖
```

### 5. 重現步驟

```
1. 開啟應用程式
2. ...
3. 出現錯誤
```

## 🎯 快速檢查清單

在報告問題前，請確認：

- [ ] 裝置是 iPhone 6s 或更新
- [ ] iOS 版本是 11.0 或更新
- [ ] 相機權限已在設定中開啟
- [ ] 已清理相機鏡頭
- [ ] 在光線充足的環境測試
- [ ] 對準有紋理的表面
- [ ] 已重啟應用程式
- [ ] 已重啟裝置
- [ ] 已查看 Xcode 控制台日誌
- [ ] 已使用診斷功能
- [ ] 已截圖保存錯誤訊息

## 💡 提示

### 最佳測試流程

1. **準備階段**

   - 清潔相機鏡頭
   - 確保電量充足
   - 選擇良好的測試環境

2. **啟動階段**

   - 開啟應用程式
   - 授予權限
   - 等待初始化完成

3. **初始化追蹤**

   - 緩慢移動裝置
   - 對準有紋理的表面
   - 等待追蹤狀態變為「正常」
   - 看到平面檢測（地面或桌面出現網格）

4. **開始測量**
   - 點擊「開始測量」
   - 對準起點點擊
   - 移動到終點點擊
   - 查看結果

### 如果一直無法正常工作

1. 嘗試在不同環境測試（換個房間）
2. 嘗試在不同時間測試（不同光線條件）
3. 嘗試測量不同的物體
4. 檢查是否有 iOS 更新
5. 聯絡技術支援並提供除錯資訊

## 📞 技術支援

如果以上方法都無法解決問題，請提供：

1. 裝置資訊
2. 環境資訊
3. Xcode 控制台完整日誌
4. 診斷報告截圖
5. 問題重現步驟
6. 已嘗試的解決方法

---

**記住：大部分追蹤問題都是環境因素造成的。確保在良好的環境中測試！**

**關鍵成功因素：**

1. ✅ 光線充足
2. ✅ 有紋理的表面
3. ✅ 緩慢穩定的移動
4. ✅ 耐心等待初始化
