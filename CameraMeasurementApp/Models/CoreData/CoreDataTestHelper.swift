//
//  CoreDataTestHelper.swift
//  CameraMeasurementApp
//
//  Core Data 測試輔助工具
//

import Foundation
import CoreData
import UIKit
import CoreLocation

class CoreDataTestHelper {
    
    static let shared = CoreDataTestHelper()
    private init() {}
    
    // MARK: - Test Data Creation
    
    /// 建立測試用的測量記錄
    func createTestMeasurementRecord(context: NSManagedObjectContext? = nil) -> MeasurementRecordEntity {
        let ctx = context ?? CoreDataStack.shared.viewContext
        
        let record = MeasurementRecordEntity(context: ctx)
        record.id = UUID()
        record.timestamp = Date()
        record.referenceObjectName = "信用卡"
        record.notes = "測試測量記錄"
        
        // 設定測試位置（台北 101）
        let testLocation = CLLocation(latitude: 25.0330, longitude: 121.5654)
        record.setLocation(testLocation)
        
        // 建立測試影像
        if let testImage = createTestImage() {
            record.setImage(testImage)
        }
        
        return record
    }
    
    /// 建立測試用的檢測物體
    func createTestDetectedObject(context: NSManagedObjectContext? = nil) -> DetectedObjectEntity {
        let ctx = context ?? CoreDataStack.shared.viewContext
        
        let object = DetectedObjectEntity(context: ctx)
        object.id = UUID()
        object.objectType = "手機"
        object.confidence = 0.95
        
        // 設定邊界框
        object.setBoundingBox(CGRect(x: 100, y: 100, width: 200, height: 400))
        
        return object
    }
    
    /// 建立測試用的物體尺寸
    func createTestObjectDimensions(context: NSManagedObjectContext? = nil) -> ObjectDimensionsEntity {
        let ctx = context ?? CoreDataStack.shared.viewContext
        
        let dimensions = ObjectDimensionsEntity(context: ctx)
        dimensions.length = 14.7
        dimensions.width = 7.1
        dimensions.height = 0.8
        dimensions.accuracy = 0.92
        dimensions.measurementDate = Date()
        
        return dimensions
    }
    
    /// 建立完整的測試資料結構
    func createCompleteTestRecord(context: NSManagedObjectContext? = nil) -> MeasurementRecordEntity {
        let ctx = context ?? CoreDataStack.shared.viewContext
        
        // 建立測量記錄
        let record = createTestMeasurementRecord(context: ctx)
        
        // 建立檢測物體
        let detectedObject = createTestDetectedObject(context: ctx)
        
        // 建立尺寸資料
        let dimensions = createTestObjectDimensions(context: ctx)
        
        // 建立關聯
        dimensions.detectedObject = detectedObject
        detectedObject.dimensions = dimensions
        detectedObject.measurementRecord = record
        record.addToDetectedObjects(detectedObject)
        
        return record
    }
    
    // MARK: - Test Queries
    
    /// 取得所有測量記錄的數量
    func getMeasurementRecordCount() -> Int {
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        
        do {
            let count = try CoreDataStack.shared.viewContext.count(for: fetchRequest)
            return count
        } catch {
            print("查詢記錄數量失敗: \(error)")
            return 0
        }
    }
    
    /// 取得最近的測量記錄
    func getRecentMeasurements(limit: Int = 10) -> [MeasurementRecordEntity] {
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            let results = try CoreDataStack.shared.viewContext.fetch(fetchRequest)
            return results
        } catch {
            print("查詢最近記錄失敗: \(error)")
            return []
        }
    }
    
    // MARK: - Test Cleanup
    
    /// 刪除所有測試資料
    func deleteAllTestData() {
        let entities = ["MeasurementRecord", "DetectedObjectEntity", "ObjectDimensionsEntity"]
        
        for entityName in entities {
            do {
                try CoreDataStack.shared.batchDelete(entityName: entityName)
                print("✅ 已刪除所有 \(entityName) 資料")
            } catch {
                print("❌ 刪除 \(entityName) 失敗: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage? {
        // 建立簡單的測試影像
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Validation Test
    
    /// 執行完整的驗證測試
    func runValidationTests() -> Bool {
        print("\n=== 開始 Core Data 驗證測試 ===\n")
        
        var allTestsPassed = true
        
        // 測試 1: 建立測量記錄
        print("測試 1: 建立測量記錄")
        let record = createCompleteTestRecord()
        let recordValidation = CoreDataValidator.validate(measurementRecord: record)
        if recordValidation.isValid {
            print("✅ 測量記錄驗證通過")
        } else {
            print("❌ 測量記錄驗證失敗: \(recordValidation.errorMessage)")
            allTestsPassed = false
        }
        
        // 測試 2: 儲存資料
        print("\n測試 2: 儲存資料")
        do {
            try CoreDataStack.shared.save(context: CoreDataStack.shared.viewContext)
            print("✅ 資料儲存成功")
        } catch {
            print("❌ 資料儲存失敗: \(error)")
            allTestsPassed = false
        }
        
        // 測試 3: 查詢資料
        print("\n測試 3: 查詢資料")
        let count = getMeasurementRecordCount()
        print("資料庫中的記錄數量: \(count)")
        if count > 0 {
            print("✅ 資料查詢成功")
        } else {
            print("❌ 資料查詢失敗")
            allTestsPassed = false
        }
        
        print("\n=== Core Data 驗證測試完成 ===")
        print(allTestsPassed ? "✅ 所有測試通過" : "❌ 部分測試失敗")
        
        return allTestsPassed
    }
}
