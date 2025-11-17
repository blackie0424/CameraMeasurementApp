//
//  CoreDataStack.swift
//  CameraMeasurementApp
//
//  Core Data 堆疊管理類別
//

import Foundation
import CoreData

class CoreDataStack {
    
    // MARK: - Singleton
    static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CameraMeasurement")
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // 在生產環境中，應該適當處理錯誤而不是使用 fatalError
                print("Core Data 載入失敗: \(error), \(error.userInfo)")
                fatalError("無法載入 Core Data: \(error)")
            }
            print("Core Data 成功載入: \(storeDescription)")
        }
        
        // 設定自動合併來自父 context 的變更
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Background Context
    
    /// 建立背景 context 用於執行耗時的資料操作
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Core Data Saving Support
    
    /// 儲存主 context 的變更
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Core Data 儲存成功")
            } catch {
                let nserror = error as NSError
                print("Core Data 儲存失敗: \(nserror), \(nserror.userInfo)")
                // 在生產環境中應該適當處理錯誤
            }
        }
    }
    
    /// 儲存指定的 context
    func save(context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
            print("Context 儲存成功")
        }
    }
    
    // MARK: - Batch Operations
    
    /// 批次刪除指定實體的所有記錄
    func batchDelete(entityName: String) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        
        // 更新 view context
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes,
                into: [viewContext]
            )
        }
    }
    
    // MARK: - Validation
    
    /// 驗證資料模型的完整性
    func validateDataModel() -> Bool {
        do {
            let model = persistentContainer.managedObjectModel
            let entities = model.entities
            
            // 檢查必要的實體是否存在
            let requiredEntities = ["MeasurementRecord", "DetectedObjectEntity", "ObjectDimensionsEntity"]
            for entityName in requiredEntities {
                guard entities.contains(where: { $0.name == entityName }) else {
                    print("缺少必要的實體: \(entityName)")
                    return false
                }
            }
            
            print("資料模型驗證成功")
            return true
        } catch {
            print("資料模型驗證失敗: \(error)")
            return false
        }
    }
}
