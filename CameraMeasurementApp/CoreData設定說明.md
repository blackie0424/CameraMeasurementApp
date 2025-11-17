# Core Data 資料模型設定說明

## 概述

已成功建立 Core Data 資料模型，用於儲存測量記錄、檢測物體和尺寸資訊。

## 資料模型結構

### 實體關係圖

```
MeasurementRecord (測量記錄)
    ├── id: UUID
    ├── timestamp: Date
    ├── imageData: Binary (外部儲存)
    ├── latitude: Double
    ├── longitude: Double
    ├── referenceObjectName: String?
    ├── notes: String?
    └── detectedObjects: [DetectedObjectEntity] (一對多)

DetectedObjectEntity (檢測物體)
    ├── id: UUID
    ├── objectType: String
    ├── confidence: Float
    ├── boundingBox (x, y, width, height): Float
    ├── worldPosition (x, y, z): Float
    ├── dimensions: ObjectDimensionsEntity? (一對一)
    └── measurementRecord: MeasurementRecord? (多對一)

ObjectDimensionsEntity (物體尺寸)
    ├── length: Float (公分)
    ├── width: Float (公分)
    ├── height: Float (公分)
    ├── accuracy: Float (0.0-1.0)
    ├── measurementDate: Date
    └── detectedObject: DetectedObjectEntity? (一對一)
```

## 已建立的檔案

### 1. Core Data 模型檔案

- `CameraMeasurement.xcdatamodeld/` - Core Data 資料模型定義
  - 包含三個實體：MeasurementRecord、DetectedObjectEntity、ObjectDimensionsEntity
  - 設定了適當的關聯和刪除規則

### 2. NSManagedObject 子類別

- `MeasurementRecordEntity+CoreDataClass.swift` - 測量記錄類別擴展
- `MeasurementRecordEntity+CoreDataProperties.swift` - 測量記錄屬性定義
- `DetectedObjectEntity+CoreDataClass.swift` - 檢測物體類別擴展
- `DetectedObjectEntity+CoreDataProperties.swift` - 檢測物體屬性定義
- `ObjectDimensionsEntity+CoreDataClass.swift` - 物體尺寸類別擴展
- `ObjectDimensionsEntity+CoreDataProperties.swift` - 物體尺寸屬性定義

### 3. Core Data 管理類別

- `CoreDataStack.swift` - Core Data 堆疊管理（Singleton 模式）
- `CoreDataValidator.swift` - 資料驗證規則
- `CoreDataTestHelper.swift` - 測試輔助工具

## 主要功能

### CoreDataStack

- **Singleton 實例**: `CoreDataStack.shared`
- **持久化容器**: 自動載入和管理 Core Data 堆疊
- **Context 管理**: 提供主 context 和背景 context
- **儲存支援**: 提供儲存方法和錯誤處理
- **批次操作**: 支援批次刪除功能
- **資料驗證**: 驗證資料模型完整性

### CoreDataValidator

驗證規則包括：

- **MeasurementRecord**: 時間戳記、位置座標、物體數量驗證
- **DetectedObject**: 物體類型、信心度、邊界框驗證
- **ObjectDimensions**: 尺寸值、準確度、日期、合理性驗證

### CoreDataTestHelper

測試功能包括：

- 建立測試資料（測量記錄、檢測物體、尺寸資料）
- 查詢測試（記錄數量、最近記錄）
- 資料清理（批次刪除）
- 完整驗證測試流程

## 資料關聯和刪除規則

### MeasurementRecord → DetectedObjectEntity

- **關係**: 一對多
- **刪除規則**: Cascade（刪除測量記錄時，自動刪除所有關聯的檢測物體）

### DetectedObjectEntity → ObjectDimensionsEntity

- **關係**: 一對一
- **刪除規則**: Cascade（刪除檢測物體時，自動刪除關聯的尺寸資料）

### DetectedObjectEntity → MeasurementRecord

- **關係**: 多對一
- **刪除規則**: Nullify（刪除檢測物體時，不影響測量記錄）

## 使用方式

### 1. 初始化（已在 AppDelegate 中設定）

```swift
// 在 application(_:didFinishLaunchingWithOptions:) 中
_ = CoreDataStack.shared.persistentContainer
CoreDataStack.shared.validateDataModel()
```

### 2. 建立測量記錄

```swift
let context = CoreDataStack.shared.viewContext
let record = MeasurementRecordEntity(context: context)
record.id = UUID()
record.timestamp = Date()
// 設定其他屬性...

try? CoreDataStack.shared.save(context: context)
```

### 3. 查詢資料

```swift
let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

let results = try? CoreDataStack.shared.viewContext.fetch(fetchRequest)
```

### 4. 執行測試

```swift
// 建立測試資料
let testRecord = CoreDataTestHelper.shared.createCompleteTestRecord()

// 執行驗證測試
let testsPassed = CoreDataTestHelper.shared.runValidationTests()

// 清理測試資料
CoreDataTestHelper.shared.deleteAllTestData()
```

## 資料驗證

所有實體都有對應的驗證方法：

```swift
let record = // ... 建立或取得記錄
let validation = CoreDataValidator.validate(measurementRecord: record)

if validation.isValid {
    print("資料有效")
} else {
    print("驗證錯誤: \(validation.errorMessage)")
}
```

## 特殊功能

### 影像儲存

- 使用外部二進位儲存（`allowsExternalBinaryDataStorage = true`）
- 提供便利方法：`setImage(_:)` 和 `getImage()`
- 自動壓縮為 JPEG 格式（80% 品質）

### 位置資訊

- 儲存經緯度座標
- 提供便利方法：`setLocation(_:)` 和 `getLocation()`
- 自動驗證座標範圍

### 邊界框和世界座標

- 提供便利方法轉換 CGRect 和 SCNVector3
- 自動處理座標轉換

## 測試建議

### 模擬器測試

1. 建立測試資料
2. 驗證資料儲存和讀取
3. 測試查詢和過濾功能
4. 驗證資料關聯正確性

### 實體機測試

1. 測試大量資料的效能
2. 驗證影像儲存和讀取
3. 測試 App 生命週期（背景/前景切換）
4. 驗證資料持久化

## 注意事項

1. **執行緒安全**: 使用 `newBackgroundContext()` 進行背景操作
2. **記憶體管理**: 大量資料操作時使用批次處理
3. **錯誤處理**: 所有資料庫操作都應該有適當的錯誤處理
4. **資料遷移**: 未來修改資料模型時需要建立遷移策略

## 下一步

Core Data 資料模型已完成，可以進行：

- 任務 8: 實作測量記錄儲存和檢索（DataManager 類別）
- 任務 9: 實作使用者偏好儲存
- 任務 10: 實作影像和測量資料匯出

## 需求對應

此任務完成了以下需求：

- **需求 4.4**: 維護測量歷史記錄
- 為後續的資料儲存、檢索和匯出功能奠定基礎
