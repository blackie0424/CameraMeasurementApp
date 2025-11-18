# Mock Data Generator 使用說明

## 概述

`MockDataGenerator` 是一個用於生成模擬測量資料的工具類別，專為 UI 測試和整合測試設計。它可以生成各種測試場景的假資料，無需實際的相機或 AR 功能。

## 主要功能

### 1. 生成模擬檢測物體

```swift
// 生成單一物體
let mockObject = MockDataGenerator.shared.generateMockDetectedObject(
    objectType: .phone,
    confidence: 0.85,
    withDimensions: true
)

// 生成多個物體
let mockObjects = MockDataGenerator.shared.generateMockDetectedObjects(count: 3)
```

### 2. 生成模擬測量記錄

```swift
// 生成單一測量記錄
let record = MockDataGenerator.shared.generateMockMeasurementRecord(
    withObjects: 2,
    includeReferenceObject: true
)

// 生成多個測量記錄
let records = MockDataGenerator.shared.generateMockMeasurementRecords(count: 5)
```

### 3. 預設測試場景

```swift
// 高準確度場景
let highAccuracy = MockDataGenerator.shared.generateHighAccuracyScenario()

// 低信心度場景
let lowConfidence = MockDataGenerator.shared.generateLowConfidenceScenario()

// 多物體場景
let multiObject = MockDataGenerator.shared.generateMultiObjectScenario()
```

### 4. 歷史記錄生成

```swift
// 生成過去 30 天的歷史記錄
let historicalRecords = MockDataGenerator.shared.generateHistoricalRecords(
    count: 10,
    daysBack: 30
)
```

## 使用場景

### UI 測試

在 UI 測試中使用模擬資料來測試介面顯示：

```swift
func testResultsDisplay() {
    let mockRecord = MockDataGenerator.shared.generateHighAccuracyScenario()

    // 將模擬資料傳遞給 ResultsViewController
    let resultsVC = ResultsViewController()
    resultsVC.measurementRecord = mockRecord

    // 驗證 UI 顯示
    XCTAssertNotNil(resultsVC.view)
}
```

### 整合測試

測試資料流程和組件整合：

```swift
func testDataPersistence() {
    let mockRecords = MockDataGenerator.shared.generateMockMeasurementRecords(count: 3)

    // 測試儲存功能
    for record in mockRecords {
        dataManager.saveMeasurementRecord(record)
    }

    // 驗證資料檢索
    let savedRecords = dataManager.fetchAllRecords()
    XCTAssertEqual(savedRecords.count, 3)
}
```

### 模擬器測試

在模擬器中測試完整流程（無需實體裝置）：

```swift
func testMeasurementFlow() {
    // 使用模擬資料替代實際的 AR 檢測
    let mockObjects = MockDataGenerator.shared.generateMockDetectedObjects(count: 2)

    // 測試測量計算邏輯
    for object in mockObjects {
        if let dimensions = object.dimensions {
            print("物體尺寸: \(dimensions.formattedDimensions())")
        }
    }
}
```

## 生成的資料特性

### DetectedObject

- 隨機但合理的邊界框位置
- 真實的物體類型和尺寸
- 可調整的信心度值（0.7-0.95）
- 3D 世界座標位置

### ObjectDimensions

- 基於物體類型的標準尺寸
- 10% 的隨機變化模擬真實測量
- 準確度值（0.80-0.95）
- 時間戳記

### MeasurementRecord

- 自動生成的模擬影像
- 1-4 個檢測物體
- 可選的參考物件
- 模擬的地理位置（台北地區）

## 支援的物體類型

生成器支援所有 `ObjectType` 列舉中定義的物體類型：

- 電子產品：phone, laptop, tablet, monitor, watch
- 日常用品：lighter, creditCard, book, bottle, cup, box, key
- 貨幣：coin, bill
- 文具：pen, pencil, notebook, ruler
- 家具：chair, table, desk

## 注意事項

1. **僅用於測試**：此生成器僅用於開發和測試環境，不應在生產代碼中使用
2. **模擬影像**：生成的影像是簡單的漸層背景，不是真實的相機拍攝
3. **資料變化**：每次生成的資料都會有隨機變化，確保測試的多樣性
4. **效能考量**：大量生成資料時注意記憶體使用

## 擴展建議

如需添加新的測試場景，可以在 `MockDataGenerator` 類別中添加新的方法：

```swift
extension MockDataGenerator {
    func generateCustomScenario() -> MeasurementRecord {
        // 自訂場景邏輯
    }
}
```
