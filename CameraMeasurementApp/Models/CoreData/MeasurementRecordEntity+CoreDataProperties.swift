//
//  MeasurementRecordEntity+CoreDataProperties.swift
//  CameraMeasurementApp
//
//  Created by Core Data Generator
//

import Foundation
import CoreData

extension MeasurementRecordEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MeasurementRecordEntity> {
        return NSFetchRequest<MeasurementRecordEntity>(entityName: "MeasurementRecord")
    }

    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var imageData: Data?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var referenceObjectName: String?
    @NSManaged public var notes: String?
    @NSManaged public var detectedObjects: NSSet?

}

// MARK: Generated accessors for detectedObjects
extension MeasurementRecordEntity {

    @objc(addDetectedObjectsObject:)
    @NSManaged public func addToDetectedObjects(_ value: DetectedObjectEntity)

    @objc(removeDetectedObjectsObject:)
    @NSManaged public func removeFromDetectedObjects(_ value: DetectedObjectEntity)

    @objc(addDetectedObjects:)
    @NSManaged public func addToDetectedObjects(_ values: NSSet)

    @objc(removeDetectedObjects:)
    @NSManaged public func removeFromDetectedObjects(_ values: NSSet)

}

extension MeasurementRecordEntity : Identifiable {

}
