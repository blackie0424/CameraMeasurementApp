//
//  DetectedObject.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import SceneKit

struct DetectedObject {
    let id: UUID
    let boundingBox: CGRect
    let objectType: ObjectType
    let confidence: Float
    let worldPosition: SCNVector3
    let dimensions: ObjectDimensions?
    
    init(id: UUID = UUID(), 
         boundingBox: CGRect, 
         objectType: ObjectType, 
         confidence: Float, 
         worldPosition: SCNVector3, 
         dimensions: ObjectDimensions? = nil) {
        self.id = id
        self.boundingBox = boundingBox
        self.objectType = objectType
        self.confidence = confidence
        self.worldPosition = worldPosition
        self.dimensions = dimensions
    }
}

extension DetectedObject: Equatable {
    static func == (lhs: DetectedObject, rhs: DetectedObject) -> Bool {
        return lhs.id == rhs.id
    }
}

extension DetectedObject: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}