//
//  MeasurementCalculatorProtocol.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import ARKit

protocol MeasurementCalculatorProtocol {
    func calculateDimensions(object: DetectedObject, arFrame: ARFrame) -> ObjectDimensions
    func calibrateWithReference(object: ReferenceObject) -> CalibrationData
    func getAccuracyConfidence() -> Float
}

// Calibration data structure
struct CalibrationData {
    let scaleFactor: Float
    let confidence: Float
    let referenceObject: ReferenceObject
    let calibrationDate: Date
    
    init(scaleFactor: Float, confidence: Float, referenceObject: ReferenceObject, calibrationDate: Date = Date()) {
        self.scaleFactor = scaleFactor
        self.confidence = confidence
        self.referenceObject = referenceObject
        self.calibrationDate = calibrationDate
    }
}