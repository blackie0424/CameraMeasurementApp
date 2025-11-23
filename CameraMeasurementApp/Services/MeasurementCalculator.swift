//
//  MeasurementCalculator.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import ARKit
import SceneKit

/// Calculator for measuring object dimensions using AR depth information
class MeasurementCalculator: MeasurementCalculatorProtocol {
    
    // MARK: - Properties
    
    /// Calibration manager for advanced calibration
    private let calibrationManager = CalibrationManager.shared
    
    /// Minimum confidence threshold for measurements
    private let minimumConfidence: Float = 0.5
    
    /// Maximum allowed measurement error percentage
    private let maxErrorPercentage: Float = 0.15 // 15%
    
    /// Coordinate transform utility
    private let coordinateTransform = CoordinateTransformUtility.self
    
    // MARK: - Initialization
    
    init() {
        // Calibration is managed by CalibrationManager singleton
    }
    
    // MARK: - MeasurementCalculatorProtocol Implementation
    
    /// Calculate dimensions of a detected object using AR frame data
    /// - Parameters:
    ///   - object: The detected object to measure
    ///   - arFrame: Current AR frame with depth and camera information
    /// - Returns: Calculated object dimensions
    func calculateDimensions(object: DetectedObject, arFrame: ARFrame) -> ObjectDimensions {
        // Get depth information for the object's bounding box
        guard let averageDepth = coordinateTransform.averageDepth(in: object.boundingBox, frame: arFrame) else {
            // Fallback: use world position distance if depth unavailable
            return calculateDimensionsFromWorldPosition(object: object, arFrame: arFrame)
        }
        
        // Calculate dimensions using pixel-to-real-world conversion
        let dimensions = pixelToRealWorld(
            boundingBox: object.boundingBox,
            depth: averageDepth,
            arFrame: arFrame,
            objectType: object.objectType
        )
        
        // Create initial dimensions
        let initialDimensions = ObjectDimensions(
            length: dimensions.length,
            width: dimensions.width,
            height: dimensions.height,
            accuracy: object.confidence,
            measurementDate: Date()
        )
        
        // Apply calibration using CalibrationManager
        let calibratedDimensions = calibrationManager.applyCalibration(to: initialDimensions)
        
        // Perform comprehensive confidence assessment
        let confidenceAssessment = calibrationManager.assessConfidence(
            dimensions: calibratedDimensions,
            objectType: object.objectType,
            detectionConfidence: object.confidence,
            depth: averageDepth,
            arFrame: arFrame
        )
        
        return ObjectDimensions(
            length: calibratedDimensions.length,
            width: calibratedDimensions.width,
            height: calibratedDimensions.height,
            accuracy: confidenceAssessment.overallConfidence,
            measurementDate: Date()
        )
    }
    
    /// Calibrate measurements using a reference object
    /// - Parameters:
    ///   - object: Reference object with known dimensions
    ///   - measuredDimensions: The dimensions measured by the system for the reference object
    ///   - arFrame: Current AR frame for environmental analysis
    /// - Returns: Calibration data
    func calibrateWithReference(object: ReferenceObject, measuredDimensions: ObjectDimensions, arFrame: ARFrame) -> CalibrationData {
        // Use CalibrationManager for advanced calibration
        return calibrationManager.calibrate(
            referenceObject: object,
            measuredDimensions: measuredDimensions,
            arFrame: arFrame
        )
    }
    
    /// Legacy calibrate method for backward compatibility
    /// - Parameter object: Reference object with known dimensions
    /// - Returns: Calibration data
    func calibrateWithReference(object: ReferenceObject) -> CalibrationData {
        // Create default calibration data without actual measurement
        let calibrationData = CalibrationData(
            scaleFactor: 1.0,
            confidence: object.standardDimensions.accuracy,
            referenceObject: object,
            calibrationDate: Date()
        )
        
        return calibrationData
    }
    
    /// Get current accuracy confidence level
    /// - Returns: Confidence value (0.0 - 1.0)
    func getAccuracyConfidence() -> Float {
        return calibrationManager.activeCalibration?.confidence ?? 0.7 // Default confidence without calibration
    }
    
    // MARK: - Private Helper Methods
    
    /// Convert pixel dimensions to real-world dimensions
    /// - Parameters:
    ///   - boundingBox: Bounding box in screen coordinates
    ///   - depth: Average depth to the object in meters
    ///   - arFrame: Current AR frame
    ///   - objectType: Type of object being measured
    /// - Returns: Dimensions in centimeters
    private func pixelToRealWorld(
        boundingBox: CGRect,
        depth: Float,
        arFrame: ARFrame,
        objectType: ObjectType
    ) -> (length: Float, width: Float, height: Float) {
        // Get camera intrinsics
        let camera = arFrame.camera
        let intrinsics = camera.intrinsics
        
        // Focal lengths in pixels
        let focalLengthX = intrinsics[0, 0]
        let focalLengthY = intrinsics[1, 1]
        
        // Calculate real-world dimensions using pinhole camera model
        // realWidth = (pixelWidth * depth) / focalLength
        let pixelWidth = Float(boundingBox.width)
        let pixelHeight = Float(boundingBox.height)
        
        // Convert to meters
        let realWidthMeters = (pixelWidth * depth) / focalLengthX
        let realHeightMeters = (pixelHeight * depth) / focalLengthY
        
        // Convert to centimeters
        let width = realWidthMeters * 100.0
        let height = realHeightMeters * 100.0
        
        // Estimate length (depth dimension) based on object type and aspect ratio
        let length = estimateDepthDimension(
            width: width,
            height: height,
            objectType: objectType
        )
        
        return (length, width, height)
    }
    
    /// Calculate dimensions from world position when depth data is unavailable
    /// - Parameters:
    ///   - object: Detected object
    ///   - arFrame: Current AR frame
    /// - Returns: Object dimensions
    private func calculateDimensionsFromWorldPosition(
        object: DetectedObject,
        arFrame: ARFrame
    ) -> ObjectDimensions {
        // Get camera position
        let cameraTransform = arFrame.camera.transform
        let cameraPosition = SCNVector3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // Calculate distance to object
        let distance = coordinateTransform.distance(from: cameraPosition, to: object.worldPosition)
        
        // Use distance as depth for pixel-to-real-world conversion
        let dimensions = pixelToRealWorld(
            boundingBox: object.boundingBox,
            depth: distance,
            arFrame: arFrame,
            objectType: object.objectType
        )
        
        // Lower confidence when using world position instead of depth data
        let confidence = min(object.confidence * 0.8, 0.85)
        
        return ObjectDimensions(
            length: dimensions.length,
            width: dimensions.width,
            height: dimensions.height,
            accuracy: confidence,
            measurementDate: Date()
        )
    }
    
    /// Estimate the depth dimension (length) based on width, height, and object type
    /// - Parameters:
    ///   - width: Measured width in cm
    ///   - height: Measured height in cm
    ///   - objectType: Type of object
    /// - Returns: Estimated length in cm
    private func estimateDepthDimension(
        width: Float,
        height: Float,
        objectType: ObjectType
    ) -> Float {
        // Use typical dimensions if available
        if let typical = objectType.typicalDimensions {
            // Calculate scale factor from width or height
            let scaleFromWidth = width / typical.width
            let scaleFromHeight = height / typical.height
            let averageScale = (scaleFromWidth + scaleFromHeight) / 2.0
            
            return typical.length * averageScale
        }
        
        // Fallback: estimate based on object category
        switch objectType.category {
        case .electronics:
            // Electronics tend to be relatively thin
            return min(width, height) * 0.3
            
        case .stationery:
            // Stationery items vary widely
            if width > height {
                // Horizontal item (ruler, pen lying down)
                return height * 0.5
            } else {
                // Vertical item (pen standing)
                return width * 0.5
            }
            
        case .currency:
            // Currency is very thin
            return min(width, height) * 0.05
            
        case .everyday:
            // Everyday items: assume roughly cubic proportions
            return (width + height) / 2.0
            
        case .furniture:
            // Furniture: assume depth similar to width
            return width * 0.8
            
        case .unknown:
            // Unknown: assume cubic proportions
            return (width + height) / 2.0
        }
    }
    
    /// Apply calibration to measured dimensions (deprecated - use CalibrationManager)
    /// - Parameter dimensions: Raw measured dimensions
    /// - Returns: Calibrated dimensions
    @available(*, deprecated, message: "Use CalibrationManager.applyCalibration instead")
    private func applyCalibration(
        to dimensions: (length: Float, width: Float, height: Float)
    ) -> (length: Float, width: Float, height: Float) {
        guard let calibration = calibrationManager.activeCalibration else {
            return dimensions
        }
        
        // Apply scale factor from calibration
        let scaleFactor = calibration.scaleFactor
        
        return (
            length: dimensions.length * scaleFactor,
            width: dimensions.width * scaleFactor,
            height: dimensions.height * scaleFactor
        )
    }
    
    /// Calculate confidence score for the measurement (deprecated - use CalibrationManager)
    /// - Parameters:
    ///   - dimensions: Measured dimensions
    ///   - objectType: Type of object
    ///   - detectionConfidence: Confidence from object detection
    ///   - depth: Depth value used for measurement
    /// - Returns: Confidence score (0.0 - 1.0)
    @available(*, deprecated, message: "Use CalibrationManager.assessConfidence instead")
    private func calculateConfidence(
        dimensions: (length: Float, width: Float, height: Float),
        objectType: ObjectType,
        detectionConfidence: Float,
        depth: Float
    ) -> Float {
        var confidence: Float = detectionConfidence
        
        // Factor 1: Calibration confidence
        if let calibration = calibrationManager.activeCalibration {
            confidence *= calibration.confidence
        } else {
            // Reduce confidence if not calibrated
            confidence *= 0.85
        }
        
        // Factor 2: Depth quality
        // Optimal depth range: 0.3m to 3.0m
        let depthQuality: Float
        if depth < 0.3 {
            // Too close
            depthQuality = depth / 0.3
        } else if depth > 3.0 {
            // Too far
            depthQuality = max(0.3, 3.0 / depth)
        } else {
            // Optimal range
            depthQuality = 1.0
        }
        confidence *= depthQuality
        
        // Factor 3: Dimension reasonableness
        // Check if dimensions match typical values for object type
        if let typical = objectType.typicalDimensions {
            let lengthRatio = dimensions.length / typical.length
            let widthRatio = dimensions.width / typical.width
            let heightRatio = dimensions.height / typical.height
            
            // Calculate average deviation from expected
            let avgRatio = (lengthRatio + widthRatio + heightRatio) / 3.0
            
            // If within 50% of expected, high confidence
            // If more than 2x different, lower confidence
            let dimensionConfidence: Float
            if avgRatio > 0.5 && avgRatio < 1.5 {
                dimensionConfidence = 1.0
            } else if avgRatio > 0.3 && avgRatio < 2.0 {
                dimensionConfidence = 0.8
            } else {
                dimensionConfidence = 0.6
            }
            
            confidence *= dimensionConfidence
        }
        
        // Ensure confidence is within valid range
        return max(0.0, min(1.0, confidence))
    }
    
    // MARK: - Public Utility Methods
    
    /// Calculate measurement error estimate
    /// - Parameters:
    ///   - measured: Measured dimensions
    ///   - actual: Actual known dimensions (for validation)
    /// - Returns: Error percentage
    func calculateError(measured: ObjectDimensions, actual: ObjectDimensions) -> Float {
        let error = calibrationManager.calculateError(measured: measured, actual: actual)
        return error.averageErrorPercent
    }
    
    /// Calculate detailed measurement error
    /// - Parameters:
    ///   - measured: Measured dimensions
    ///   - actual: Actual known dimensions
    /// - Returns: Detailed error analysis
    func calculateDetailedError(measured: ObjectDimensions, actual: ObjectDimensions) -> MeasurementErrorAnalysis {
        return calibrationManager.calculateError(measured: measured, actual: actual)
    }
    
    /// Validate measurement error
    /// - Parameters:
    ///   - measured: Measured dimensions
    ///   - actual: Actual known dimensions
    /// - Returns: Error validation result
    func validateError(measured: ObjectDimensions, actual: ObjectDimensions) -> ErrorValidationResult {
        let error = calibrationManager.calculateError(measured: measured, actual: actual)
        return calibrationManager.validateError(error)
    }
    
    /// Check if measurement is within acceptable error range
    /// - Parameter dimensions: Measured dimensions
    /// - Returns: True if measurement is acceptable
    func isAcceptableMeasurement(_ dimensions: ObjectDimensions) -> Bool {
        return dimensions.accuracy >= minimumConfidence
    }
    
    /// Get measurement quality description
    /// - Parameter confidence: Confidence score
    /// - Returns: Quality description string
    func measurementQuality(for confidence: Float) -> String {
        switch confidence {
        case 0.9...1.0:
            return "優秀"
        case 0.8..<0.9:
            return "良好"
        case 0.7..<0.8:
            return "中等"
        case 0.6..<0.7:
            return "可接受"
        default:
            return "較低"
        }
    }
    
    /// Reset calibration
    func resetCalibration() {
        calibrationManager.resetCalibration()
    }
    
    /// Verify measurement result
    /// - Parameters:
    ///   - dimensions: Measured dimensions
    ///   - objectType: Type of object
    ///   - detectionConfidence: Detection confidence
    ///   - arFrame: AR frame
    /// - Returns: Verification result
    func verifyMeasurement(
        dimensions: ObjectDimensions,
        objectType: ObjectType,
        detectionConfidence: Float,
        arFrame: ARFrame
    ) -> MeasurementVerificationResult {
        return calibrationManager.verifyMeasurement(
            dimensions: dimensions,
            objectType: objectType,
            detectionConfidence: detectionConfidence,
            arFrame: arFrame
        )
    }
    
    /// Get calibration quality
    /// - Returns: Current calibration quality level
    func getCalibrationQuality() -> CalibrationQuality {
        return calibrationManager.getCalibrationQuality()
    }
    
    /// Check if calibration is valid
    /// - Returns: True if calibration is valid and not expired
    func isCalibrationValid() -> Bool {
        return calibrationManager.isCalibrationValid()
    }
}
