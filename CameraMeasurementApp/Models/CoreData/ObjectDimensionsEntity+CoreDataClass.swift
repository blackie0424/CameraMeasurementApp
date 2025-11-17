//
//  ObjectDimensionsEntity+CoreDataClass.swift
//  CameraMeasurementApp
//
//  Created by Core Data Generator
//

import Foundation
import CoreData

@objc(ObjectDimensionsEntity)
public class ObjectDimensionsEntity: NSManagedObject {
    
    /// 取得格式化的尺寸字串
    func getFormattedDimensions(unit: String = "cm") -> String {
        return String(format: "%.1f x %.1f x %.1f %@", length, width, height, unit)
    }
    
    /// 取得準確度百分比字串
    func getAccuracyPercentage() -> String {
        return String(format: "%.0f%%", accuracy * 100)
    }
    
    /// 檢查測量是否在可接受的準確度範圍內
    func isAccuracyAcceptable(threshold: Float = 0.9) -> Bool {
        return accuracy >= threshold
    }
}
