//
//  DetectedObjectEntity+CoreDataProperties.swift
//  CameraMeasurementApp
//
//  Created by Core Data Generator
//

import Foundation
import CoreData

extension DetectedObjectEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DetectedObjectEntity> {
        return NSFetchRequest<DetectedObjectEntity>(entityName: "DetectedObjectEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var objectType: String
    @NSManaged public var confidence: Float
    @NSManaged public var boundingBoxX: Float
    @NSManaged public var boundingBoxY: Float
    @NSManaged public var boundingBoxWidth: Float
    @NSManaged public var boundingBoxHeight: Float
    @NSManaged public var worldPositionX: Float
    @NSManaged public var worldPositionY: Float
    @NSManaged public var worldPositionZ: Float
    @NSManaged public var dimensions: ObjectDimensionsEntity?
    @NSManaged public var measurementRecord: MeasurementRecordEntity?

}

extension DetectedObjectEntity : Identifiable {

}
