# Core Data 測試指南

## 測試目標

驗證 Core Data 資料模型的建立、資料關聯、索引和驗證規則是否正確運作。

## 測試環境

- ✅ 可在模擬器中測試
- ✅ 建議在實體機上測試以驗證真實效能

## 測試前準備

### 1. 確認檔案已加入專案

在 Xcode 中確認以下檔案已正確加入專案：

- `CameraMeasurement.xcdatamodeld`
- `Models/CoreData/` 目錄下的所有 Swift 檔案

### 2. 編譯專案

```bash
# 確認專案可以成功編譯
⌘ + B (Command + B)
```

## 測試步驟

### 測試 1: 驗證 Core Data 初始化

**目的**: 確認 Core Data 堆疊正確載入

**步驟**:

1. 在 Xcode 中執行 App
2. 查看 Console 輸出

**預期結果**:

```
Core Data 成功載入: ...
✅ Core Data 資料模型驗證成功
```

**如何驗證**:

- Console 中應該看到成功訊息
- 沒有任何錯誤或警告

---

### 測試 2: 建立測試資料

**目的**: 驗證可以建立和儲存資料

**步驟**:

1. 在 `ViewController.swift` 的 `viewDidLoad()` 中加入測試程式碼：

```swift
override func viewDidLoad() {
    super.viewDidLoad()

    // 執行 Core Data 測試
    testCoreData()
}

func testCoreData() {
    print("\n=== 開始 Core Data 測試 ===\n")

    // 建立測試記錄
    let testRecord = CoreDataTestHelper.shared.createCompleteTestRecord()

    // 儲存資料
    do {
        try CoreDataStack.shared.save(context: CoreDataStack.shared.viewContext)
        print("✅ 測試資料儲存成功")

        // 查詢資料
        let count = CoreDataTestHelper.shared.getMeasurementRecordCount()
        print("📊 資料庫中的記錄數量: \(count)")

        // 驗證資料
        let validation = CoreDataValidator.validate(measurementRecord: testRecord)
        if validation.isValid {
            print("✅ 資料驗證通過")
        } else {
            print("❌ 資料驗證失敗: \(validation.errorMessage)")
        }

    } catch {
        print("❌ 測試失敗: \(error)")
    }

    print("\n=== Core Data 測試完成 ===\n")
}
```

2. 執行 App
3. 查看 Console 輸出

**預期結果**:

```
=== 開始 Core Data 測試 ===

✅ 測試資料儲存成功
📊 資料庫中的記錄數量: 1
✅ 資料驗證通過

=== Core Data 測試完成 ===
```

---

### 測試 3: 驗證資料關聯

**目的**: 確認實體間的關聯正確建立

**測試程式碼**:

```swift
func testDataRelationships() {
    let record = CoreDataTestHelper.shared.createCompleteTestRecord()

    // 驗證測量記錄有檢測物體
    if let objects = record.detectedObjects, objects.count > 0 {
        print("✅ 測量記錄包含 \(objects.count) 個檢測物體")

        // 取得第一個檢測物體
        if let firstObject = objects.allObjects.first as? DetectedObjectEntity {
            print("   物體類型: \(firstObject.objectType)")
            print("   信心度: \(firstObject.confidence)")

            // 驗證檢測物體有尺寸資料
            if let dimensions = firstObject.dimensions {
                print("✅ 檢測物體包含尺寸資料")
                print("   尺寸: \(dimensions.getFormattedDimensions())")
                print("   準確度: \(dimensions.getAccuracyPercentage())")
            } else {
                print("❌ 檢測物體缺少尺寸資料")
            }

            // 驗證反向關聯
            if firstObject.measurementRecord == record {
                print("✅ 反向關聯正確")
            } else {
                print("❌ 反向關聯錯誤")
            }
        }
    } else {
        print("❌ 測量記錄沒有檢測物體")
    }

    try? CoreDataStack.shared.save(context: CoreDataStack.shared.viewContext)
}
```

**預期結果**:

```
✅ 測量記錄包含 1 個檢測物體
   物體類型: 手機
   信心度: 0.95
✅ 檢測物體包含尺寸資料
   尺寸: 14.7 x 7.1 x 0.8 cm
   準確度: 92%
✅ 反向關聯正確
```

---

### 測試 4: 驗證資料查詢

**目的**: 確認可以正確查詢和過濾資料

**測試程式碼**:

```swift
func testDataQuery() {
    // 建立多筆測試資料
    for i in 1...5 {
        let record = CoreDataTestHelper.shared.createCompleteTestRecord()
        record.notes = "測試記錄 \(i)"
    }

    try? CoreDataStack.shared.saveContext()

    // 查詢所有記錄
    let allRecords = CoreDataTestHelper.shared.getRecentMeasurements(limit: 10)
    print("📊 查詢到 \(allRecords.count) 筆記錄")

    // 顯示記錄資訊
    for (index, record) in allRecords.enumerated() {
        print("\n記錄 \(index + 1):")
        print("  ID: \(record.id)")
        print("  時間: \(record.timestamp)")
        print("  備註: \(record.notes ?? "無")")
        print("  參考物件: \(record.referenceObjectName ?? "無")")

        if let location = record.getLocation() {
            print("  位置: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
}
```

**預期結果**:

```
📊 查詢到 5 筆記錄

記錄 1:
  ID: ...
  時間: 2025-11-17 ...
  備註: 測試記錄 5
  參考物件: 信用卡
  位置: 25.033, 121.5654
...
```

---

### 測試 5: 驗證資料驗證規則

**目的**: 確認資料驗證規則正確運作

**測試程式碼**:

```swift
func testDataValidation() {
    let context = CoreDataStack.shared.viewContext

    // 測試 1: 有效的資料
    print("\n測試 1: 有效的資料")
    let validRecord = CoreDataTestHelper.shared.createCompleteTestRecord()
    let validation1 = CoreDataValidator.validate(measurementRecord: validRecord)
    print(validation1.isValid ? "✅ 通過" : "❌ 失敗: \(validation1.errorMessage)")

    // 測試 2: 無效的信心度
    print("\n測試 2: 無效的信心度")
    let invalidObject = DetectedObjectEntity(context: context)
    invalidObject.id = UUID()
    invalidObject.objectType = "測試"
    invalidObject.confidence = 1.5  // 超出範圍
    invalidObject.setBoundingBox(CGRect(x: 0, y: 0, width: 100, height: 100))
    let validation2 = CoreDataValidator.validate(detectedObject: invalidObject)
    print(validation2.isValid ? "❌ 應該失敗" : "✅ 正確檢測到錯誤: \(validation2.errorMessage)")

    // 測試 3: 無效的尺寸
    print("\n測試 3: 無效的尺寸")
    let invalidDimensions = ObjectDimensionsEntity(context: context)
    invalidDimensions.length = -5  // 負數
    invalidDimensions.width = 10
    invalidDimensions.height = 10
    invalidDimensions.accuracy = 0.9
    invalidDimensions.measurementDate = Date()
    let validation3 = CoreDataValidator.validate(dimensions: invalidDimensions)
    print(validation3.isValid ? "❌ 應該失敗" : "✅ 正確檢測到錯誤: \(validation3.errorMessage)")
}
```

**預期結果**:

```
測試 1: 有效的資料
✅ 通過

測試 2: 無效的信心度
✅ 正確檢測到錯誤: 信心度必須在 0 到 1 之間: 1.5

測試 3: 無效的尺寸
✅ 正確檢測到錯誤: 長度必須大於 0: -5.0
```

---

### 測試 6: 驗證刪除規則

**目的**: 確認級聯刪除正確運作

**測試程式碼**:

```swift
func testDeletionRules() {
    let context = CoreDataStack.shared.viewContext

    // 建立完整的測試記錄
    let record = CoreDataTestHelper.shared.createCompleteTestRecord()
    try? CoreDataStack.shared.save(context: context)

    // 記錄物件數量
    let objectsBefore = record.detectedObjects?.count ?? 0
    print("刪除前的檢測物體數量: \(objectsBefore)")

    // 刪除測量記錄
    context.delete(record)
    try? CoreDataStack.shared.save(context: context)

    // 驗證關聯的物體也被刪除
    let fetchRequest: NSFetchRequest<DetectedObjectEntity> = DetectedObjectEntity.fetchRequest()
    let remainingObjects = try? context.fetch(fetchRequest)

    print("刪除後剩餘的檢測物體數量: \(remainingObjects?.count ?? 0)")

    if remainingObjects?.count == 0 {
        print("✅ 級聯刪除正確運作")
    } else {
        print("❌ 級聯刪除失敗")
    }
}
```

**預期結果**:

```
刪除前的檢測物體數量: 1
刪除後剩餘的檢測物體數量: 0
✅ 級聯刪除正確運作
```

---

### 測試 7: 清理測試資料

**目的**: 驗證批次刪除功能

**測試程式碼**:

```swift
func testCleanup() {
    print("\n清理測試資料...")

    let countBefore = CoreDataTestHelper.shared.getMeasurementRecordCount()
    print("清理前的記錄數量: \(countBefore)")

    CoreDataTestHelper.shared.deleteAllTestData()

    let countAfter = CoreDataTestHelper.shared.getMeasurementRecordCount()
    print("清理後的記錄數量: \(countAfter)")

    if countAfter == 0 {
        print("✅ 資料清理成功")
    } else {
        print("❌ 資料清理失敗")
    }
}
```

**預期結果**:

```
清理測試資料...
清理前的記錄數量: 5
✅ 已刪除所有 MeasurementRecord 資料
✅ 已刪除所有 DetectedObjectEntity 資料
✅ 已刪除所有 ObjectDimensionsEntity 資料
清理後的記錄數量: 0
✅ 資料清理成功
```

---

## 實體機測試重點

在實體機上執行以下額外測試：

### 1. 效能測試

```swift
func testPerformance() {
    let startTime = Date()

    // 建立 100 筆記錄
    for _ in 1...100 {
        _ = CoreDataTestHelper.shared.createCompleteTestRecord()
    }

    try? CoreDataStack.shared.saveContext()

    let duration = Date().timeIntervalSince(startTime)
    print("建立 100 筆記錄耗時: \(duration) 秒")
}
```

### 2. 影像儲存測試

```swift
func testImageStorage() {
    let record = CoreDataTestHelper.shared.createCompleteTestRecord()

    // 設定較大的測試影像
    if let image = UIImage(named: "test_image") {
        record.setImage(image)
        try? CoreDataStack.shared.saveContext()

        // 讀取影像
        if let retrievedImage = record.getImage() {
            print("✅ 影像儲存和讀取成功")
            print("   影像尺寸: \(retrievedImage.size)")
        }
    }
}
```

### 3. App 生命週期測試

1. 建立測試資料
2. 將 App 切換到背景
3. 等待幾秒後回到前景
4. 驗證資料仍然存在

## 測試檢查清單

- [ ] Core Data 堆疊成功初始化
- [ ] 可以建立測量記錄
- [ ] 可以建立檢測物體
- [ ] 可以建立尺寸資料
- [ ] 實體間的關聯正確
- [ ] 反向關聯正確
- [ ] 可以查詢資料
- [ ] 可以過濾和排序資料
- [ ] 資料驗證規則運作正常
- [ ] 級聯刪除正確運作
- [ ] 批次刪除功能正常
- [ ] 影像可以正確儲存和讀取
- [ ] 位置資訊可以正確儲存和讀取
- [ ] App 重啟後資料持久化

## 常見問題排除

### 問題 1: Core Data 載入失敗

**解決方案**:

- 確認 `.xcdatamodeld` 檔案已加入專案
- 檢查檔案名稱是否正確
- 清理專案並重新編譯

### 問題 2: 找不到實體

**解決方案**:

- 確認實體名稱拼寫正確
- 檢查 `.xcdatamodel/contents` 檔案中的實體定義

### 問題 3: 儲存失敗

**解決方案**:

- 檢查 Console 中的錯誤訊息
- 驗證資料是否符合驗證規則
- 確認所有必要屬性都已設定

## 測試完成標準

✅ 所有測試步驟都通過
✅ Console 中沒有錯誤訊息
✅ 資料可以正確儲存和讀取
✅ 資料關聯正確建立
✅ 驗證規則正確運作
✅ 刪除規則正確運作

## 下一步

Core Data 測試通過後，可以繼續執行：

- **任務 8**: 實作測量記錄儲存和檢索（建立 DataManager 類別）
