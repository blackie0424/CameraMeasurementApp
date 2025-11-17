//
//  CoreDataValidator.swift
//  CameraMeasurementApp
//
//  Core Data 資料驗證規則
//

import Foundation
import CoreData

class CoreDataValidator {
    
    // MARK: - MeasurementRecord Validation
    
    /// 驗證測量記錄的完整性
    static func validate(measurementRecord: MeasurementRecordEntity) -> ValidationResult {
        var errors: [String] = []
        
        // 驗證時間戳記
        if measurementRecord.timestamp > Date() {
            errors.append("時間戳記不能是未來時間")
        }
        
        // 驗證位置資訊（如果有提供）
        if measurementRecord.latitude != 0 || measurementRecord.longitude != 0 {
            if !isValidLatitude(measurementRecord.latitude) {
                errors.append("緯度值無效: \(measurementRecord.latitude)")
            }
            if !isValidLongitude(measurementRecord.longitude) {
                errors.append("經度值無效: \(measurementRecord.longitude)")
            }
        }
        
        // 驗證是否有檢測到的物體
        if let objects = measurementRecord.detectedObjects, objects.count == 0 {
            errors.append("測量記錄必須至少包含一個檢測到的物體")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - DetectedObject Validation
    
    /// 驗證檢測物體的資料
    static func validate(detectedObject: DetectedObjectEntity) -> ValidationResult {
        var errors: [String] = []
        
        // 驗證物體類型
        if detectedObject.objectType.isEmpty {
            errors.append("物體類型不能為空")
        }
        
        // 驗證信心度
        if detectedObject.confidence < 0 || detectedObject.confidence > 1 {
            errors.append("信心度必須在 0 到 1 之間: \(detectedObject.confidence)")
        }
        
        // 驗證邊界框
        if detectedObject.boundingBoxWidth <= 0 || detectedObject.boundingBoxHeight <= 0 {
            errors.append("邊界框尺寸必須大於 0")
        }
        
        if detectedObject.boundingBoxX < 0 || detectedObject.boundingBoxY < 0 {
            errors.append("邊界框座標不能為負數")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - ObjectDimensions Validation
    
    /// 驗證物體尺寸資料
    static func validate(dimensions: ObjectDimensionsEntity) -> ValidationResult {
        var errors: [String] = []
        
        // 驗證尺寸值
        if dimensions.length <= 0 {
            errors.append("長度必須大於 0: \(dimensions.length)")
        }
        
        if dimensions.width <= 0 {
            errors.append("寬度必須大於 0: \(dimensions.width)")
        }
        
        if dimensions.height <= 0 {
            errors.append("高度必須大於 0: \(dimensions.height)")
        }
        
        // 驗證準確度
        if dimensions.accuracy < 0 || dimensions.accuracy > 1 {
            errors.append("準確度必須在 0 到 1 之間: \(dimensions.accuracy)")
        }
        
        // 驗證測量日期
        if dimensions.measurementDate > Date() {
            errors.append("測量日期不能是未來時間")
        }
        
        // 驗證尺寸的合理性（假設測量範圍在 0.1cm 到 1000cm 之間）
        let maxDimension = max(dimensions.length, dimensions.width, dimensions.height)
        let minDimension = min(dimensions.length, dimensions.width, dimensions.height)
        
        if maxDimension > 1000 {
            errors.append("尺寸過大，超過合理範圍: \(maxDimension) cm")
        }
        
        if minDimension < 0.1 {
            errors.append("尺寸過小，低於合理範圍: \(minDimension) cm")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Helper Methods
    
    private static func isValidLatitude(_ latitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90
    }
    
    private static func isValidLongitude(_ longitude: Double) -> Bool {
        return longitude >= -180 && longitude <= 180
    }
}

// MARK: - ValidationResult

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    
    var errorMessage: String {
        return errors.joined(separator: "\n")
    }
}
