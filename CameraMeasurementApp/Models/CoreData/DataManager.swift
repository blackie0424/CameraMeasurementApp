//
//  DataManager.swift
//  CameraMeasurementApp
//
//  測量記錄資料管理器
//  提供 CRUD 操作和資料查詢功能
//

import Foundation
import CoreData
import UIKit
import CoreLocation
import SceneKit

/// 資料管理器錯誤類型
enum DataManagerError: Error {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidData
    case recordNotFound
    
    var localizedDescription: String {
        switch self {
        case .saveFailed(let error):
            return "儲存失敗: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "讀取失敗: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "刪除失敗: \(error.localizedDescription)"
        case .invalidData:
            return "資料格式無效"
        case .recordNotFound:
            return "找不到指定的記錄"
        }
    }
}

/// 測量記錄資料管理器
class DataManager {
    
    // MARK: - Singleton
    static let shared = DataManager()
    
    private let coreDataStack: CoreDataStack
    
    private init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Create Operations
    
    /// 儲存測量記錄
    /// - Parameter record: 要儲存的測量記錄
    /// - Returns: 儲存成功的記錄 ID
    /// - Throws: DataManagerError
    @discardableResult
    func saveMeasurementRecord(_ record: MeasurementRecord) throws -> UUID {
        let context = coreDataStack.viewContext
        
        let entity = MeasurementRecordEntity(context: context)
        entity.id = record.id
        entity.timestamp = record.timestamp
        entity.setImage(record.image)
        entity.setLocation(record.location)
        entity.referenceObjectName = record.referenceObject?.name
        
        // 儲存檢測到的物體
        for detectedObject in record.detectedObjects {
            let objectEntity = createDetectedObjectEntity(from: detectedObject, in: context)
            entity.addToDetectedObjects(objectEntity)
        }
        
        do {
            try coreDataStack.save(context: context)
            return entity.id
        } catch {
            throw DataManagerError.saveFailed(error)
        }
    }
    
    /// 批次儲存多筆測量記錄
    /// - Parameter records: 要儲存的測量記錄陣列
    /// - Returns: 成功儲存的記錄數量
    /// - Throws: DataManagerError
    @discardableResult
    func saveMeasurementRecords(_ records: [MeasurementRecord]) throws -> Int {
        let context = coreDataStack.newBackgroundContext()
        var savedCount = 0
        
        context.performAndWait {
            for record in records {
                let entity = MeasurementRecordEntity(context: context)
                entity.id = record.id
                entity.timestamp = record.timestamp
                entity.setImage(record.image)
                entity.setLocation(record.location)
                entity.referenceObjectName = record.referenceObject?.name
                
                for detectedObject in record.detectedObjects {
                    let objectEntity = createDetectedObjectEntity(from: detectedObject, in: context)
                    entity.addToDetectedObjects(objectEntity)
                }
                
                savedCount += 1
            }
            
            do {
                try context.save()
            } catch {
                savedCount = 0
            }
        }
        
        guard savedCount > 0 else {
            throw DataManagerError.saveFailed(NSError(domain: "DataManager", code: -1))
        }
        
        return savedCount
    }
    
    // MARK: - Read Operations
    
    /// 讀取所有測量記錄
    /// - Returns: 測量記錄陣列
    /// - Throws: DataManagerError
    func fetchAllRecords() throws -> [MeasurementRecord] {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { convertToMeasurementRecord($0) }
        } catch {
            throw DataManagerError.fetchFailed(error)
        }
    }
    
    /// 根據 ID 讀取特定測量記錄
    /// - Parameter id: 記錄 ID
    /// - Returns: 測量記錄
    /// - Throws: DataManagerError
    func fetchRecord(byId id: UUID) throws -> MeasurementRecord {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let entities = try context.fetch(fetchRequest)
            guard let entity = entities.first,
                  let record = convertToMeasurementRecord(entity) else {
                throw DataManagerError.recordNotFound
            }
            return record
        } catch {
            throw DataManagerError.fetchFailed(error)
        }
    }
    
    /// 根據日期範圍讀取測量記錄
    /// - Parameters:
    ///   - startDate: 開始日期
    ///   - endDate: 結束日期
    /// - Returns: 測量記錄陣列
    /// - Throws: DataManagerError
    func fetchRecords(from startDate: Date, to endDate: Date) throws -> [MeasurementRecord] {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", 
                                            startDate as CVarArg, 
                                            endDate as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { convertToMeasurementRecord($0) }
        } catch {
            throw DataManagerError.fetchFailed(error)
        }
    }
    
    /// 根據參考物件名稱讀取測量記錄
    /// - Parameter referenceObjectName: 參考物件名稱
    /// - Returns: 測量記錄陣列
    /// - Throws: DataManagerError
    func fetchRecords(byReferenceObject referenceObjectName: String) throws -> [MeasurementRecord] {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "referenceObjectName == %@", referenceObjectName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { convertToMeasurementRecord($0) }
        } catch {
            throw DataManagerError.fetchFailed(error)
        }
    }
    
    /// 讀取最近的 N 筆測量記錄
    /// - Parameter limit: 記錄數量限制
    /// - Returns: 測量記錄陣列
    /// - Throws: DataManagerError
    func fetchRecentRecords(limit: Int = 10) throws -> [MeasurementRecord] {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { convertToMeasurementRecord($0) }
        } catch {
            throw DataManagerError.fetchFailed(error)
        }
    }
    
    /// 搜尋測量記錄（根據備註）
    /// - Parameter searchText: 搜尋文字
    /// - Returns: 測量記錄陣列
    /// - Throws: DataManagerError
    func searchRecords(withText searchText: String) throws -> [MeasurementRecord] {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "notes CONTAINS[cd] %@", searchText)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { convertToMeasurementRecord($0) }
        } catch {
            throw DataManagerError.fetchFailed(error)
        }
    }
    
    /// 取得記錄總數
    /// - Returns: 記錄總數
    /// - Throws: DataManagerError
    func getRecordCount() throws -> Int {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            throw DataManagerError.fetchFailed(error)
        }
    }
    
    // MARK: - Update Operations
    
    /// 更新測量記錄的備註
    /// - Parameters:
    ///   - id: 記錄 ID
    ///   - notes: 新的備註內容
    /// - Throws: DataManagerError
    func updateRecordNotes(id: UUID, notes: String) throws {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let entities = try context.fetch(fetchRequest)
            guard let entity = entities.first else {
                throw DataManagerError.recordNotFound
            }
            
            entity.notes = notes
            try coreDataStack.save(context: context)
        } catch {
            throw DataManagerError.saveFailed(error)
        }
    }
    
    /// 更新測量記錄的參考物件
    /// - Parameters:
    ///   - id: 記錄 ID
    ///   - referenceObjectName: 新的參考物件名稱
    /// - Throws: DataManagerError
    func updateRecordReferenceObject(id: UUID, referenceObjectName: String?) throws {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let entities = try context.fetch(fetchRequest)
            guard let entity = entities.first else {
                throw DataManagerError.recordNotFound
            }
            
            entity.referenceObjectName = referenceObjectName
            try coreDataStack.save(context: context)
        } catch {
            throw DataManagerError.saveFailed(error)
        }
    }
    
    // MARK: - Delete Operations
    
    /// 刪除特定測量記錄
    /// - Parameter id: 記錄 ID
    /// - Throws: DataManagerError
    func deleteRecord(byId id: UUID) throws {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let entities = try context.fetch(fetchRequest)
            guard let entity = entities.first else {
                throw DataManagerError.recordNotFound
            }
            
            context.delete(entity)
            try coreDataStack.save(context: context)
        } catch {
            throw DataManagerError.deleteFailed(error)
        }
    }
    
    /// 刪除多筆測量記錄
    /// - Parameter ids: 記錄 ID 陣列
    /// - Returns: 成功刪除的記錄數量
    /// - Throws: DataManagerError
    @discardableResult
    func deleteRecords(byIds ids: [UUID]) throws -> Int {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
        
        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            try coreDataStack.save(context: context)
            return entities.count
        } catch {
            throw DataManagerError.deleteFailed(error)
        }
    }
    
    /// 刪除指定日期之前的所有記錄
    /// - Parameter date: 日期
    /// - Returns: 成功刪除的記錄數量
    /// - Throws: DataManagerError
    @discardableResult
    func deleteRecords(before date: Date) throws -> Int {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", date as CVarArg)
        
        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            try coreDataStack.save(context: context)
            return entities.count
        } catch {
            throw DataManagerError.deleteFailed(error)
        }
    }
    
    /// 刪除所有測量記錄
    /// - Returns: 成功刪除的記錄數量
    /// - Throws: DataManagerError
    @discardableResult
    func deleteAllRecords() throws -> Int {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            try coreDataStack.save(context: context)
            return entities.count
        } catch {
            throw DataManagerError.deleteFailed(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 建立 DetectedObjectEntity
    private func createDetectedObjectEntity(from detectedObject: DetectedObject, 
                                           in context: NSManagedObjectContext) -> DetectedObjectEntity {
        let entity = DetectedObjectEntity(context: context)
        entity.id = detectedObject.id
        entity.objectType = detectedObject.objectType.rawValue
        entity.confidence = detectedObject.confidence
        entity.setBoundingBox(detectedObject.boundingBox)
        entity.setWorldPosition(detectedObject.worldPosition)
        
        // 如果有尺寸資訊，建立 ObjectDimensionsEntity
        if let dimensions = detectedObject.dimensions {
            let dimensionsEntity = ObjectDimensionsEntity(context: context)
            dimensionsEntity.id = UUID()
            dimensionsEntity.length = dimensions.length
            dimensionsEntity.width = dimensions.width
            dimensionsEntity.height = dimensions.height
            dimensionsEntity.accuracy = dimensions.accuracy
            dimensionsEntity.measurementDate = dimensions.measurementDate
            entity.dimensions = dimensionsEntity
        }
        
        return entity
    }
    
    /// 將 MeasurementRecordEntity 轉換為 MeasurementRecord
    private func convertToMeasurementRecord(_ entity: MeasurementRecordEntity) -> MeasurementRecord? {
        guard let image = entity.getImage() else {
            return nil
        }
        
        // 轉換檢測到的物體
        var detectedObjects: [DetectedObject] = []
        if let objectEntities = entity.detectedObjects as? Set<DetectedObjectEntity> {
            for objectEntity in objectEntities {
                if let detectedObject = convertToDetectedObject(objectEntity) {
                    detectedObjects.append(detectedObject)
                }
            }
        }
        
        // 取得參考物件
        var referenceObject: ReferenceObject?
        if let refName = entity.referenceObjectName {
            referenceObject = ReferenceObject.defaultObjects.first { $0.name == refName }
        }
        
        return MeasurementRecord(
            id: entity.id,
            image: image,
            detectedObjects: detectedObjects,
            referenceObject: referenceObject,
            timestamp: entity.timestamp,
            location: entity.getLocation()
        )
    }
    
    /// 將 DetectedObjectEntity 轉換為 DetectedObject
    private func convertToDetectedObject(_ entity: DetectedObjectEntity) -> DetectedObject? {
        guard let objectType = ObjectType(rawValue: entity.objectType) else {
            return nil
        }
        
        var dimensions: ObjectDimensions?
        if let dimensionsEntity = entity.dimensions {
            dimensions = ObjectDimensions(
                length: dimensionsEntity.length,
                width: dimensionsEntity.width,
                height: dimensionsEntity.height,
                accuracy: dimensionsEntity.accuracy,
                measurementDate: dimensionsEntity.measurementDate
            )
        }
        
        let worldPosition = entity.getWorldPosition() ?? SCNVector3(0, 0, 0)
        
        return DetectedObject(
            id: entity.id,
            boundingBox: entity.getBoundingBox(),
            objectType: objectType,
            confidence: entity.confidence,
            worldPosition: worldPosition,
            dimensions: dimensions
        )
    }
}

// MARK: - Query Builder

extension DataManager {
    
    /// 查詢建構器，用於建立複雜的查詢條件
    class QueryBuilder {
        private var predicates: [NSPredicate] = []
        private var sortDescriptors: [NSSortDescriptor] = []
        private var fetchLimit: Int?
        
        /// 添加日期範圍條件
        func dateRange(from startDate: Date, to endDate: Date) -> QueryBuilder {
            let predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", 
                                       startDate as CVarArg, 
                                       endDate as CVarArg)
            predicates.append(predicate)
            return self
        }
        
        /// 添加參考物件條件
        func referenceObject(_ name: String) -> QueryBuilder {
            let predicate = NSPredicate(format: "referenceObjectName == %@", name)
            predicates.append(predicate)
            return self
        }
        
        /// 添加備註搜尋條件
        func notesContain(_ text: String) -> QueryBuilder {
            let predicate = NSPredicate(format: "notes CONTAINS[cd] %@", text)
            predicates.append(predicate)
            return self
        }
        
        /// 設定排序方式
        func sortBy(_ key: String, ascending: Bool = true) -> QueryBuilder {
            let sortDescriptor = NSSortDescriptor(key: key, ascending: ascending)
            sortDescriptors.append(sortDescriptor)
            return self
        }
        
        /// 設定結果數量限制
        func limit(_ count: Int) -> QueryBuilder {
            fetchLimit = count
            return self
        }
        
        /// 執行查詢
        func execute() throws -> [MeasurementRecord] {
            let context = CoreDataStack.shared.viewContext
            let fetchRequest: NSFetchRequest<MeasurementRecordEntity> = MeasurementRecordEntity.fetchRequest()
            
            if !predicates.isEmpty {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            if !sortDescriptors.isEmpty {
                fetchRequest.sortDescriptors = sortDescriptors
            }
            
            if let limit = fetchLimit {
                fetchRequest.fetchLimit = limit
            }
            
            do {
                let entities = try context.fetch(fetchRequest)
                return entities.compactMap { DataManager.shared.convertToMeasurementRecord($0) }
            } catch {
                throw DataManagerError.fetchFailed(error)
            }
        }
    }
    
    /// 建立查詢建構器
    func query() -> QueryBuilder {
        return QueryBuilder()
    }
}
