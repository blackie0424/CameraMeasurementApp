# 整合測試文件

## 概述

本文件說明相機測量系統的整合測試套件，涵蓋端到端測試流程、組件整合測試和完整使用者流程驗證。

## 測試架構

### 測試檔案

1. **IntegrationTests.swift** - 使用 Swift Testing 框架的正式測試套件
2. **IntegrationTestRunner.swift** - 手動測試執行器，可在應用程式中直接執行

### 測試範圍

整合測試涵蓋以下需求：

- **需求 1.1**: 相機功能和物體分析
- **需求 3.3**: 測量準確性和信心度評估
- **需求 5.1**: 使用者介面和互動流程
- **需求 4.1, 4.4**: 資料儲存和檢索
- **需求 4.2, 4.5**: 資料匯出功能
- **需求 2.2**: 校準和準確性評估
- **需求 5.2**: 錯誤處理

## 測試案例

### 1. 完整測量工作流程測試

**目的**: 驗證從拍照到儲存的完整測量流程

**測試步驟**:

1. 物體檢測
2. 測量計算
3. 參考物件選擇
4. 建立測量記錄
5. 儲存到 Core Data
6. 檢索和驗證
7. 清理測試資料

**驗證點**:

- 物體成功檢測
- 尺寸計算正確
- 資料成功儲存
- 資料可正確檢索
- 記錄 ID 一致

### 2. ObjectDetector 和 ConfidenceEvaluator 整合測試

**目的**: 驗證物體檢測和信心度評估的整合

**測試步驟**:

1. 建立不同信心度的測試物體
2. 評估每個物體的信心度
3. 過濾可靠的檢測結果
4. 檢查是否需要手動驗證

**驗證點**:

- 信心度分數在有效範圍內 (0.0-1.0)
- 可靠物體過濾正確
- 低信心度物體被正確識別

### 3. MeasurementCalculator 和 CalibrationManager 整合測試

**目的**: 驗證測量計算和校準系統的整合

**測試步驟**:

1. 測量未校準的尺寸
2. 使用參考物件進行校準
3. 應用校準到新測量
4. 計算誤差

**驗證點**:

- 校準提高測量準確性
- 誤差在可接受範圍內 (<10%)
- 校準資料正確應用

### 4. DataManager CRUD 操作測試

**目的**: 驗證資料管理器的完整 CRUD 功能

**測試步驟**:

1. 建立 (Create) - 儲存多筆測量記錄
2. 讀取 (Read) - 檢索所有記錄和最近記錄
3. 更新 (Update) - 修改記錄備註
4. 刪除 (Delete) - 刪除測試記錄

**驗證點**:

- 所有 CRUD 操作成功執行
- 資料完整性保持
- 查詢結果正確

### 5. ExportManager 和 DataManager 整合測試

**目的**: 驗證資料匯出功能

**測試步驟**:

1. 建立測量記錄
2. 匯出為 CSV 格式
3. 建立標註影像
4. 驗證匯出內容

**驗證點**:

- CSV 資料包含正確標題
- 標註影像成功建立
- 匯出資料格式正確

### 6. 完整使用者流程模擬測試

**目的**: 模擬真實使用者操作流程

**測試步驟**:

1. 開啟相機
2. 拍攝照片
3. 自動物體檢測
4. 計算測量值
5. 顯示參考物件
6. 儲存結果
7. 查看歷史記錄
8. 匯出資料

**驗證點**:

- 每個步驟順利執行
- 使用者流程無中斷
- 資料在各步驟間正確傳遞

### 7. 錯誤處理整合測試

**目的**: 驗證系統錯誤處理機制

**測試步驟**:

1. 嘗試讀取不存在的記錄
2. 嘗試刪除不存在的記錄
3. 處理低信心度檢測

**驗證點**:

- 錯誤被正確捕獲
- 錯誤訊息清晰
- 系統保持穩定

### 8. 效能整合測試

**目的**: 驗證整合系統的效能

**測試指標**:

- 物體檢測時間
- 資料儲存時間 (<1 秒)
- 資料檢索時間 (<1 秒)

**驗證點**:

- 所有操作在可接受時間內完成
- 無明顯效能瓶頸

## 執行測試

### 方法 1: 使用 Xcode Test Navigator

1. 開啟 Xcode
2. 選擇 Test Navigator (⌘6)
3. 找到 IntegrationTests
4. 點擊測試旁的播放按鈕

### 方法 2: 使用命令列

```bash
xcodebuild test \
  -scheme CameraMeasurementApp \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  -only-testing:CameraMeasurementAppTests/IntegrationTests
```

### 方法 3: 使用手動測試執行器

在應用程式中呼叫：

```swift
IntegrationTestRunner.shared.runAllTests()
```

## 測試環境需求

### 必要條件

- iOS 17.0 或更高版本
- Xcode 15.0 或更高版本
- iOS 模擬器或實體裝置

### 可選條件

- YOLOv5 Core ML 模型（用於實際物體檢測）
- AR 支援裝置（用於 AR 功能測試）

### 測試資料

測試使用模擬資料：

- 合成測試影像
- 模擬檢測物體
- 預設參考物件

## 測試限制

### 當前限制

1. **AR 功能**: 無法在單元測試中完全模擬 ARFrame

   - 解決方案: 使用模擬資料和實體裝置測試

2. **Core ML 模型**: 測試不依賴實際 ML 模型

   - 解決方案: 使用模擬檢測結果

3. **相機權限**: 測試環境中無法測試實際相機
   - 解決方案: 使用合成影像

### 未來改進

1. 增加更多邊界情況測試
2. 加入效能基準測試
3. 增加並發操作測試
4. 加入記憶體洩漏檢測

## 測試資料清理

所有測試都包含清理步驟：

```swift
// 測試結束後刪除測試資料
try dataManager.deleteRecord(byId: savedId)
```

確保測試不會留下殘留資料。

## 持續整合

### CI/CD 整合

測試可整合到 CI/CD 流程：

```yaml
# GitHub Actions 範例
- name: Run Integration Tests
  run: |
    xcodebuild test \
      -scheme CameraMeasurementApp \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -only-testing:CameraMeasurementAppTests/IntegrationTests
```

## 測試報告

### 測試輸出格式

測試執行時會輸出詳細日誌：

```
🧪 Testing complete measurement workflow...
📋 Step 1: Object Detection
✓ Detected 1 objects
📋 Step 2: Measurement Calculation
✓ Calculated dimensions: 14.7x7.1x0.8 cm
...
✅ Complete measurement workflow test passed
```

### 測試摘要

測試完成後顯示摘要：

```
📊 TEST SUMMARY
✅ Passed: 7
❌ Failed: 0
📈 Total: 7
🎯 Success Rate: 100.0%
```

## 疑難排解

### 常見問題

1. **測試失敗: Core Data 錯誤**

   - 檢查 Core Data 模型是否正確設定
   - 確認測試清理程式碼執行

2. **測試超時**

   - 增加測試超時時間
   - 檢查是否有死鎖

3. **模擬器問題**
   - 重置模擬器
   - 使用不同的模擬器版本

## 貢獻指南

### 新增測試

1. 在 IntegrationTests.swift 中新增測試方法
2. 使用 @Test 屬性標記
3. 包含清理步驟
4. 更新本文件

### 測試命名規範

- 使用描述性名稱
- 包含測試目的
- 遵循現有命名模式

## 參考資料

- [Swift Testing 文件](https://developer.apple.com/documentation/testing)
- [XCTest 框架](https://developer.apple.com/documentation/xctest)
- [Core Data 測試最佳實踐](https://developer.apple.com/documentation/coredata)

## 版本歷史

- **v1.0** (2025-11-18): 初始版本
  - 7 個核心整合測試
  - 完整工作流程覆蓋
  - 手動測試執行器

## 聯絡資訊

如有問題或建議，請聯絡開發團隊。
