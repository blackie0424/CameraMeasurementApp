//
//  ObjectDimensionsEntity+CoreDataProperties.swift
//  CameraMeasurementApp
//
//  Created by Core Data Generator
//

import Foundation
import CoreData

extension ObjectDimensionsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ObjectDimensionsEntity> {
        return NSFetchRequest<ObjectDimensionsEntity>(entityName: "ObjectDimensionsEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var length: Float
    @NSManaged public var width: Float
    @NSManaged public var height: Float
    @NSManaged public var accuracy: Float
    @NSManaged public var measurementDate: Date
    @NSManaged public var detectedObject: DetectedObjectEntity?

}

extension ObjectDimensionsEntity : Identifiable {

}
