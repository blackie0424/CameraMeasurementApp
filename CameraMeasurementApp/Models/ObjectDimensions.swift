//
//  ObjectDimensions.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation

struct ObjectDimensions {
    let length: Float  // 公分
    let width: Float   // 公分
    let height: Float  // 公分
    let accuracy: Float // 0.0-1.0
    let measurementDate: Date
    
    init(length: Float, width: Float, height: Float, accuracy: Float, measurementDate: Date = Date()) {
        self.length = length
        self.width = width
        self.height = height
        self.accuracy = accuracy
        self.measurementDate = measurementDate
    }
    
    // Computed properties for convenience
    var volume: Float {
        return length * width * height
    }
    
    var surfaceArea: Float {
        return 2 * (length * width + width * height + height * length)
    }
    
    // Format dimensions for display
    func formattedDimensions(unit: MeasurementUnit = .centimeters) -> String {
        let factor = unit.conversionFactor
        let unitSymbol = unit.symbol
        
        return String(format: "%.1f%@ × %.1f%@ × %.1f%@", 
                     length * factor, unitSymbol,
                     width * factor, unitSymbol,
                     height * factor, unitSymbol)
    }
}

// Measurement units supported by the system
enum MeasurementUnit: String, CaseIterable {
    case centimeters = "cm"
    case inches = "in"
    case millimeters = "mm"
    
    var symbol: String {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .centimeters: return "公分"
        case .inches: return "英吋"
        case .millimeters: return "公釐"
        }
    }
    
    var conversionFactor: Float {
        switch self {
        case .centimeters: return 1.0
        case .inches: return 0.393701
        case .millimeters: return 10.0
        }
    }
}