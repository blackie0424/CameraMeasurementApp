//
//  DetectedObjectEntity+CoreDataClass.swift
//  CameraMeasurementApp
//
//  Created by Core Data Generator
//

import Foundation
import CoreData
import SceneKit

@objc(DetectedObjectEntity)
public class DetectedObjectEntity: NSManagedObject {
    
    /// 設定邊界框
    func setBoundingBox(_ rect: CGRect) {
        boundingBoxX = Float(rect.origin.x)
        boundingBoxY = Float(rect.origin.y)
        boundingBoxWidth = Float(rect.width)
        boundingBoxHeight = Float(rect.height)
    }
    
    /// 取得邊界框
    func getBoundingBox() -> CGRect {
        return CGRect(
            x: CGFloat(boundingBoxX),
            y: CGFloat(boundingBoxY),
            width: CGFloat(boundingBoxWidth),
            height: CGFloat(boundingBoxHeight)
        )
    }
    
    /// 設定世界座標位置
    func setWorldPosition(_ position: SCNVector3) {
        worldPositionX = position.x
        worldPositionY = position.y
        worldPositionZ = position.z
    }
    
    /// 取得世界座標位置
    func getWorldPosition() -> SCNVector3? {
        if worldPositionX == 0 && worldPositionY == 0 && worldPositionZ == 0 {
            return nil
        }
        return SCNVector3(worldPositionX, worldPositionY, worldPositionZ)
    }
}
