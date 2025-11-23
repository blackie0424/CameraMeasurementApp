//
//  CalibrationManager.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//  Task 25: 實作測量校準和準確性評估
//

import Foundation
import ARKit

/// Advanced calibration manager for measurement accuracy improvement
class CalibrationManager {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = CalibrationManager()
    
    /// Current active calibration
    private(set) var activeCalibration: CalibrationData?
    
    /// Calibration history for analysis
    private var calibrationHistory: [CalibrationData] = []
    
    /// Maximum calibration history to keep
    private let maxHistorySize = 10
    
    /// Calibration quality thresholds
    private let qualityThresholds = CalibrationQualityThresholds(
        excellent: 0.95,
        good: 0.85,
        acceptable: 0.70,
        poor: 0.50
    )
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - Calibration Methods
    
    /// Perform calibration using a reference object with measured dimensions
    /// - Parameters:
    ///   - referenceObject: The reference object with known dimensions
    ///   - measuredDimensions: The dimensions measured by the system
    ///   - arFrame: Current AR frame for environmental analysis
    /// - Returns: Calibration data with calculated scale factor
    func calibrate(
        referenceObject: ReferenceObject,
        measuredDimensions: ObjectDimensions,
        arFrame: ARFrame
    ) -> CalibrationData {
        // Calculate scale factors for each dimension
        let lengthScale = referenceObject.standardDimensions.length / measuredDimensions.length
        let widthScale = referenceObject.standardDimensions.width / measuredDimensions.width
        let heightScale = referenceObject.standardDimensions.height / measuredDimensions.height
        
        // Use weighted average, giving more weight to larger dimensions (more accurate)
        let weights = calculateDimensionWeights(
            length: measuredDimensions.length,
            width: measuredDimensions.width,
            height: measuredDimensions.height
        )
        
        let scaleFactor = (lengthScale * weights.length +
                          widthScale * weights.width +
                          heightScale * weights.height)
        
        // Calculate calibration confidence based on measurement consistency
        let confidence = calculateCalibrationConfidence(
            lengthScale: lengthScale,
            widthScale: widthScale,
            heightScale: heightScale,
            measuredConfidence: measuredDimensions.accuracy,
            arFrame: arFrame
        )
        
        // Create calibration data
        let calibration = CalibrationData(
            scaleFactor: scaleFactor,
            confidence: confidence,
            referenceObject: referenceObject,
            calibrationDate: Date()
        )
        
        // Store as active calibration
        activeCalibration = calibration
        
        // Add to history
        addToHistory(calibration)
        
        return calibration
    }
    
    /// Perform multi-point calibration using multiple reference objects
    /// - Parameters:
    ///   - calibrationPoints: Array of reference objects with their measured dimensions
    ///   - arFrame: Current AR frame
    /// - Returns: Enhanced calibration data
    func multiPointCalibrate(
        calibrationPoints: [(reference: ReferenceObject, measured: ObjectDimensions)],
        arFrame: ARFrame
    ) -> CalibrationData {
        guard !calibrationPoints.isEmpty else {
            // Fallback to default calibration
            return CalibrationData(
                scaleFactor: 1.0,
                confidence: 0.5,
                referenceObject: ReferenceObject.creditCard,
                calibrationDate: Date()
            )
        }
        
        // Calculate scale factor for each calibration point
        var scaleFactors: [Float] = []
        var confidences: [Float] = []
        
        for point in calibrationPoints {
            let calibration = calibrate(
                referenceObject: point.reference,
                measuredDimensions: point.measured,
                arFrame: arFrame
            )
            scaleFactors.append(calibration.scaleFactor)
            confidences.append(calibration.confidence)
        }
        
        // Calculate weighted average scale factor
        let totalConfidence = confidences.reduce(0, +)
        var weightedScaleFactor: Float = 0
        
        for (index, scaleFactor) in scaleFactors.enumerated() {
            let weight = confidences[index] / totalConfidence
            weightedScaleFactor += scaleFactor * weight
        }
        
        // Use the highest confidence reference object
        let bestIndex = confidences.firstIndex(of: confidences.max() ?? 0) ?? 0
        let bestReference = calibrationPoints[bestIndex].reference
        
        // Calculate overall confidence (average of all confidences, boosted for multiple points)
        let averageConfidence = confidences.reduce(0, +) / Float(confidences.count)
        let multiPointBonus: Float = min(0.1, Float(calibrationPoints.count - 1) * 0.03)
        let finalConfidence = min(1.0, averageConfidence + multiPointBonus)
        
        let calibration = CalibrationData(
            scaleFactor: weightedScaleFactor,
            confidence: finalConfidence,
            referenceObject: bestReference,
            calibrationDate: Date()
        )
        
        activeCalibration = calibration
        addToHistory(calibration)
        
        return calibration
    }
    
    /// Apply calibration to measured dimensions
    /// - Parameter dimensions: Raw measured dimensions
    /// - Returns: Calibrated dimensions
    func applyCalibration(to dimensions: ObjectDimensions) -> ObjectDimensions {
        guard let calibration = activeCalibration else {
            return dimensions
        }
        
        let scaleFactor = calibration.scaleFactor
        
        // Apply scale factor to all dimensions
        let calibratedLength = dimensions.length * scaleFactor
        let calibratedWidth = dimensions.width * scaleFactor
        let calibratedHeight = dimensions.height * scaleFactor
        
        // Adjust accuracy based on calibration confidence
        let adjustedAccuracy = dimensions.accuracy * calibration.confidence
        
        return ObjectDimensions(
            length: calibratedLength,
            width: calibratedWidth,
            height: calibratedHeight,
            accuracy: adjustedAccuracy,
            measurementDate: Date()
        )
    }
    
    // MARK: - Error Calculation
    
    /// Calculate measurement error between measured and actual dimensions
    /// - Parameters:
    ///   - measured: Measured dimensions
    ///   - actual: Actual known dimensions
    /// - Returns: Error analysis result
    func calculateError(measured: ObjectDimensions, actual: ObjectDimensions) -> MeasurementErrorAnalysis {
        // Calculate absolute errors
        let lengthError = abs(measured.length - actual.length)
        let widthError = abs(measured.width - actual.width)
        let heightError = abs(measured.height - actual.height)
        
        // Calculate percentage errors
        let lengthErrorPercent = (lengthError / actual.length) * 100
        let widthErrorPercent = (widthError / actual.width) * 100
        let heightErrorPercent = (heightError / actual.height) * 100
        
        // Calculate average error
        let averageErrorPercent = (lengthErrorPercent + widthErrorPercent + heightErrorPercent) / 3.0
        
        // Calculate RMS error for overall accuracy
        let rmsError = sqrt(
            (lengthError * lengthError +
             widthError * widthError +
             heightError * heightError) / 3.0
        )
        
        return MeasurementErrorAnalysis(
            lengthError: lengthError,
            widthError: widthError,
            heightError: heightError,
            lengthErrorPercent: lengthErrorPercent,
            widthErrorPercent: widthErrorPercent,
            heightErrorPercent: heightErrorPercent,
            averageErrorPercent: averageErrorPercent,
            rmsError: rmsError
        )
    }
    
    /// Validate if measurement error is within acceptable range
    /// - Parameter error: Measurement error to validate
    /// - Returns: Validation result
    func validateError(_ error: MeasurementErrorAnalysis) -> ErrorValidationResult {
        let threshold: Float = 10.0 // 10% error threshold per requirement 3.3
        
        let isLengthAcceptable = error.lengthErrorPercent <= threshold
        let isWidthAcceptable = error.widthErrorPercent <= threshold
        let isHeightAcceptable = error.heightErrorPercent <= threshold
        let isAverageAcceptable = error.averageErrorPercent <= threshold
        
        let isValid = isLengthAcceptable && isWidthAcceptable && isHeightAcceptable
        
        // Determine quality level
        let quality: MeasurementQuality
        if error.averageErrorPercent <= 3.0 {
            quality = .excellent
        } else if error.averageErrorPercent <= 5.0 {
            quality = .good
        } else if error.averageErrorPercent <= threshold {
            quality = .acceptable
        } else {
            quality = .poor
        }
        
        return ErrorValidationResult(
            isValid: isValid,
            quality: quality,
            lengthAcceptable: isLengthAcceptable,
            widthAcceptable: isWidthAcceptable,
            heightAcceptable: isHeightAcceptable,
            averageAcceptable: isAverageAcceptable,
            errorDetails: error
        )
    }
    
    // MARK: - Confidence Assessment
    
    /// Calculate comprehensive confidence score for a measurement
    /// - Parameters:
    ///   - dimensions: Measured dimensions
    ///   - objectType: Type of object measured
    ///   - detectionConfidence: Confidence from object detection
    ///   - depth: Depth value used for measurement
    ///   - arFrame: Current AR frame
    /// - Returns: Confidence assessment result
    func assessConfidence(
        dimensions: ObjectDimensions,
        objectType: ObjectType,
        detectionConfidence: Float,
        depth: Float,
        arFrame: ARFrame
    ) -> ConfidenceAssessment {
        var factors: [CalibrationConfidenceFactor] = []
        var overallConfidence: Float = 1.0
        
        // Factor 1: Detection confidence
        let detectionFactor = CalibrationConfidenceFactor(
            name: "物體檢測",
            value: detectionConfidence,
            weight: 0.25,
            description: getConfidenceDescription(detectionConfidence)
        )
        factors.append(detectionFactor)
        overallConfidence *= pow(detectionConfidence, 0.25)
        
        // Factor 2: Calibration confidence
        let calibrationConfidence = activeCalibration?.confidence ?? 0.7
        let calibrationFactor = CalibrationConfidenceFactor(
            name: "校準狀態",
            value: calibrationConfidence,
            weight: 0.20,
            description: activeCalibration != nil ? "已校準" : "未校準"
        )
        factors.append(calibrationFactor)
        overallConfidence *= pow(calibrationConfidence, 0.20)
        
        // Factor 3: Depth quality
        let depthQuality = assessDepthQuality(depth)
        let depthFactor = CalibrationConfidenceFactor(
            name: "深度品質",
            value: depthQuality,
            weight: 0.20,
            description: getDepthQualityDescription(depth)
        )
        factors.append(depthFactor)
        overallConfidence *= pow(depthQuality, 0.20)
        
        // Factor 4: Dimension reasonableness
        let dimensionQuality = assessDimensionReasonableness(dimensions, objectType: objectType)
        let dimensionFactor = CalibrationConfidenceFactor(
            name: "尺寸合理性",
            value: dimensionQuality,
            weight: 0.20,
            description: getDimensionQualityDescription(dimensionQuality)
        )
        factors.append(dimensionFactor)
        overallConfidence *= pow(dimensionQuality, 0.20)
        
        // Factor 5: Environmental conditions
        let environmentQuality = assessEnvironmentalConditions(arFrame)
        let environmentFactor = CalibrationConfidenceFactor(
            name: "環境條件",
            value: environmentQuality,
            weight: 0.15,
            description: getEnvironmentQualityDescription(environmentQuality)
        )
        factors.append(environmentFactor)
        overallConfidence *= pow(environmentQuality, 0.15)
        
        // Determine overall quality level
        let qualityLevel = determineQualityLevel(overallConfidence)
        
        return ConfidenceAssessment(
            overallConfidence: overallConfidence,
            qualityLevel: qualityLevel,
            factors: factors,
            recommendations: generateRecommendations(factors: factors)
        )
    }
    
    // MARK: - Verification Mechanism
    
    /// Verify measurement result against multiple criteria
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
        var checks: [VerificationCheck] = []
        var allPassed = true
        
        // Check 1: Minimum confidence threshold
        let minConfidenceCheck = dimensions.accuracy >= 0.5
        checks.append(VerificationCheck(
            name: "最低信心度",
            passed: minConfidenceCheck,
            value: dimensions.accuracy,
            threshold: 0.5,
            description: minConfidenceCheck ? "通過" : "信心度過低"
        ))
        allPassed = allPassed && minConfidenceCheck
        
        // Check 2: Dimension validity (no zero or negative values)
        let dimensionValidCheck = dimensions.length > 0 && dimensions.width > 0 && dimensions.height > 0
        checks.append(VerificationCheck(
            name: "尺寸有效性",
            passed: dimensionValidCheck,
            value: dimensionValidCheck ? 1.0 : 0.0,
            threshold: 1.0,
            description: dimensionValidCheck ? "所有尺寸為正值" : "存在無效尺寸"
        ))
        allPassed = allPassed && dimensionValidCheck
        
        // Check 3: Reasonable size range (0.1cm to 500cm)
        let maxDimension = max(dimensions.length, dimensions.width, dimensions.height)
        let minDimension = min(dimensions.length, dimensions.width, dimensions.height)
        let sizeRangeCheck = minDimension >= 0.1 && maxDimension <= 500.0
        checks.append(VerificationCheck(
            name: "尺寸範圍",
            passed: sizeRangeCheck,
            value: maxDimension,
            threshold: 500.0,
            description: sizeRangeCheck ? "尺寸在合理範圍內" : "尺寸超出合理範圍"
        ))
        allPassed = allPassed && sizeRangeCheck
        
        // Check 4: Aspect ratio reasonableness (no dimension > 100x another)
        let maxRatio = maxDimension / (minDimension > 0 ? minDimension : 0.1)
        let aspectRatioCheck = maxRatio <= 100.0
        checks.append(VerificationCheck(
            name: "長寬比",
            passed: aspectRatioCheck,
            value: maxRatio,
            threshold: 100.0,
            description: aspectRatioCheck ? "長寬比合理" : "長寬比異常"
        ))
        allPassed = allPassed && aspectRatioCheck
        
        // Check 5: Calibration status
        let calibrationCheck = activeCalibration != nil
        checks.append(VerificationCheck(
            name: "校準狀態",
            passed: calibrationCheck,
            value: calibrationCheck ? 1.0 : 0.0,
            threshold: 1.0,
            description: calibrationCheck ? "已校準" : "建議進行校準"
        ))
        // Note: Calibration is recommended but not required for passing
        
        // Determine overall result
        let result = allPassed ? MeasurementVerificationStatus.passed : .failed
        let confidence = calculateVerificationConfidence(checks: checks)
        
        return MeasurementVerificationResult(
            status: result,
            confidence: confidence,
            checks: checks,
            timestamp: Date()
        )
    }
    
    // MARK: - Calibration Management
    
    /// Reset active calibration
    func resetCalibration() {
        activeCalibration = nil
    }
    
    /// Get calibration quality level
    /// - Returns: Quality level of current calibration
    func getCalibrationQuality() -> CalibrationQuality {
        guard let calibration = activeCalibration else {
            return .none
        }
        
        let confidence = calibration.confidence
        
        if confidence >= qualityThresholds.excellent {
            return .excellent
        } else if confidence >= qualityThresholds.good {
            return .good
        } else if confidence >= qualityThresholds.acceptable {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    /// Check if calibration is still valid (not too old)
    /// - Returns: True if calibration is valid
    func isCalibrationValid() -> Bool {
        guard let calibration = activeCalibration else {
            return false
        }
        
        // Calibration expires after 1 hour
        let expirationInterval: TimeInterval = 3600
        let timeSinceCalibration = Date().timeIntervalSince(calibration.calibrationDate)
        
        return timeSinceCalibration < expirationInterval
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateDimensionWeights(length: Float, width: Float, height: Float) -> (length: Float, width: Float, height: Float) {
        let total = length + width + height
        guard total > 0 else {
            return (0.33, 0.33, 0.34)
        }
        
        return (
            length: length / total,
            width: width / total,
            height: height / total
        )
    }
    
    private func calculateCalibrationConfidence(
        lengthScale: Float,
        widthScale: Float,
        heightScale: Float,
        measuredConfidence: Float,
        arFrame: ARFrame
    ) -> Float {
        // Calculate variance in scale factors
        let avgScale = (lengthScale + widthScale + heightScale) / 3.0
        let variance = (
            pow(lengthScale - avgScale, 2) +
            pow(widthScale - avgScale, 2) +
            pow(heightScale - avgScale, 2)
        ) / 3.0
        
        // Lower variance = higher confidence
        let consistencyConfidence = max(0.0, 1.0 - variance * 10.0)
        
        // Combine with measured confidence
        let baseConfidence = (consistencyConfidence + measuredConfidence) / 2.0
        
        // Adjust for environmental factors
        let environmentalFactor = assessEnvironmentalConditions(arFrame)
        
        return baseConfidence * environmentalFactor
    }
    
    private func assessDepthQuality(_ depth: Float) -> Float {
        // Optimal depth range: 0.3m to 3.0m
        if depth < 0.3 {
            return depth / 0.3
        } else if depth > 3.0 {
            return max(0.3, 3.0 / depth)
        } else {
            return 1.0
        }
    }
    
    private func assessDimensionReasonableness(_ dimensions: ObjectDimensions, objectType: ObjectType) -> Float {
        guard let typical = objectType.typicalDimensions else {
            return 0.8 // Default for unknown types
        }
        
        let lengthRatio = dimensions.length / typical.length
        let widthRatio = dimensions.width / typical.width
        let heightRatio = dimensions.height / typical.height
        
        let avgRatio = (lengthRatio + widthRatio + heightRatio) / 3.0
        
        // Within 50% of expected: high confidence
        if avgRatio > 0.5 && avgRatio < 1.5 {
            return 1.0
        } else if avgRatio > 0.3 && avgRatio < 2.0 {
            return 0.8
        } else {
            return 0.6
        }
    }
    
    private func assessEnvironmentalConditions(_ arFrame: ARFrame) -> Float {
        // Check tracking state
        let trackingState = arFrame.camera.trackingState
        
        switch trackingState {
        case .normal:
            return 1.0
        case .limited(.initializing):
            return 0.7
        case .limited(.relocalizing):
            return 0.6
        case .limited(.excessiveMotion):
            return 0.5
        case .limited(.insufficientFeatures):
            return 0.4
        case .notAvailable:
            return 0.3
        @unknown default:
            return 0.5
        }
    }
    
    private func determineQualityLevel(_ confidence: Float) -> MeasurementQuality {
        if confidence >= qualityThresholds.excellent {
            return .excellent
        } else if confidence >= qualityThresholds.good {
            return .good
        } else if confidence >= qualityThresholds.acceptable {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    private func getConfidenceDescription(_ confidence: Float) -> String {
        switch confidence {
        case 0.9...1.0: return "非常高"
        case 0.8..<0.9: return "高"
        case 0.7..<0.8: return "中等"
        case 0.6..<0.7: return "可接受"
        default: return "較低"
        }
    }
    
    private func getDepthQualityDescription(_ depth: Float) -> String {
        if depth < 0.3 {
            return "距離過近"
        } else if depth > 3.0 {
            return "距離過遠"
        } else {
            return "距離適中"
        }
    }
    
    private func getDimensionQualityDescription(_ quality: Float) -> String {
        switch quality {
        case 0.9...1.0: return "非常合理"
        case 0.8..<0.9: return "合理"
        case 0.6..<0.8: return "可接受"
        default: return "可能不準確"
        }
    }
    
    private func getEnvironmentQualityDescription(_ quality: Float) -> String {
        switch quality {
        case 0.9...1.0: return "優秀"
        case 0.7..<0.9: return "良好"
        case 0.5..<0.7: return "一般"
        default: return "較差"
        }
    }
    
    private func generateRecommendations(factors: [CalibrationConfidenceFactor]) -> [String] {
        var recommendations: [String] = []
        
        for factor in factors {
            if factor.value < 0.7 {
                switch factor.name {
                case "物體檢測":
                    recommendations.append("改善光線條件或調整拍攝角度")
                case "校準狀態":
                    recommendations.append("使用參考物件進行校準")
                case "深度品質":
                    recommendations.append("調整與物體的距離至 30-300 公分")
                case "尺寸合理性":
                    recommendations.append("確認物體類型識別正確")
                case "環境條件":
                    recommendations.append("減少相機移動，等待 AR 追蹤穩定")
                default:
                    break
                }
            }
        }
        
        if recommendations.isEmpty {
            recommendations.append("測量品質良好")
        }
        
        return recommendations
    }
    
    private func calculateVerificationConfidence(checks: [VerificationCheck]) -> Float {
        let passedCount = checks.filter { $0.passed }.count
        return Float(passedCount) / Float(checks.count)
    }
    
    private func addToHistory(_ calibration: CalibrationData) {
        calibrationHistory.append(calibration)
        
        // Keep only recent calibrations
        if calibrationHistory.count > maxHistorySize {
            calibrationHistory.removeFirst()
        }
    }
}

// MARK: - Supporting Types

/// Measurement error analysis details
struct MeasurementErrorAnalysis {
    let lengthError: Float
    let widthError: Float
    let heightError: Float
    let lengthErrorPercent: Float
    let widthErrorPercent: Float
    let heightErrorPercent: Float
    let averageErrorPercent: Float
    let rmsError: Float
}

/// Error validation result
struct ErrorValidationResult {
    let isValid: Bool
    let quality: MeasurementQuality
    let lengthAcceptable: Bool
    let widthAcceptable: Bool
    let heightAcceptable: Bool
    let averageAcceptable: Bool
    let errorDetails: MeasurementErrorAnalysis
}

/// Measurement quality levels
enum MeasurementQuality: String {
    case excellent = "優秀"
    case good = "良好"
    case acceptable = "可接受"
    case poor = "較差"
}

/// Confidence factor for calibration assessment
struct CalibrationConfidenceFactor {
    let name: String
    let value: Float
    let weight: Float
    let description: String
}

/// Confidence assessment result
struct ConfidenceAssessment {
    let overallConfidence: Float
    let qualityLevel: MeasurementQuality
    let factors: [CalibrationConfidenceFactor]
    let recommendations: [String]
}

/// Verification check
struct VerificationCheck {
    let name: String
    let passed: Bool
    let value: Float
    let threshold: Float
    let description: String
}

/// Measurement verification status
enum MeasurementVerificationStatus {
    case passed
    case failed
    case warning
}

/// Measurement verification result
struct MeasurementVerificationResult {
    let status: MeasurementVerificationStatus
    let confidence: Float
    let checks: [VerificationCheck]
    let timestamp: Date
}

/// Calibration quality levels
enum CalibrationQuality: String {
    case none = "未校準"
    case poor = "較差"
    case acceptable = "可接受"
    case good = "良好"
    case excellent = "優秀"
}

/// Calibration quality thresholds
struct CalibrationQualityThresholds {
    let excellent: Float
    let good: Float
    let acceptable: Float
    let poor: Float
}
