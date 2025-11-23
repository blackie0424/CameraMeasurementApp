//
//  ConfidenceEvaluator.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import SceneKit

/// Confidence level categories for detected objects
enum ConfidenceLevel: String {
    case veryHigh = "很高"
    case high = "高"
    case medium = "中"
    case low = "低"
    case veryLow = "很低"
    
    var threshold: Float {
        switch self {
        case .veryHigh: return 0.85
        case .high: return 0.70
        case .medium: return 0.50
        case .low: return 0.30
        case .veryLow: return 0.0
        }
    }
    
    var color: UIColor {
        switch self {
        case .veryHigh: return .systemGreen
        case .high: return .systemGreen
        case .medium: return .systemYellow
        case .low: return .systemOrange
        case .veryLow: return .systemRed
        }
    }
    
    var requiresManualVerification: Bool {
        switch self {
        case .veryHigh, .high:
            return false
        case .medium, .low, .veryLow:
            return true
        }
    }
}

/// Result of confidence evaluation
struct ConfidenceEvaluation {
    let object: DetectedObject
    let level: ConfidenceLevel
    let score: Float
    let factors: [ConfidenceFactor]
    let recommendation: String
    let shouldFilter: Bool
    
    var isReliable: Bool {
        return level == .veryHigh || level == .high
    }
}

/// Factors that contribute to confidence scoring
enum ConfidenceFactor {
    case detectionScore(Float)
    case classificationScore(Float)
    case boundingBoxQuality(Float)
    case objectSize(Float)
    case contextualSupport(Float)
    case temporalConsistency(Float)
    
    var weight: Float {
        switch self {
        case .detectionScore: return 0.30
        case .classificationScore: return 0.25
        case .boundingBoxQuality: return 0.15
        case .objectSize: return 0.10
        case .contextualSupport: return 0.10
        case .temporalConsistency: return 0.10
        }
    }
    
    var value: Float {
        switch self {
        case .detectionScore(let v),
             .classificationScore(let v),
             .boundingBoxQuality(let v),
             .objectSize(let v),
             .contextualSupport(let v),
             .temporalConsistency(let v):
            return v
        }
    }
    
    var description: String {
        switch self {
        case .detectionScore:
            return "檢測分數"
        case .classificationScore:
            return "分類分數"
        case .boundingBoxQuality:
            return "邊界框品質"
        case .objectSize:
            return "物體大小"
        case .contextualSupport:
            return "上下文支持"
        case .temporalConsistency:
            return "時間一致性"
        }
    }
}

/// Evaluates and manages confidence scores for detected objects
class ConfidenceEvaluator {
    
    // MARK: - Properties
    
    /// Minimum confidence threshold for accepting detections
    private let minimumThreshold: Float = 0.25
    
    /// Recommended confidence threshold for reliable measurements
    private let recommendedThreshold: Float = 0.60
    
    /// History of detected objects for temporal consistency analysis
    private var detectionHistory: [[DetectedObject]] = []
    private let maxHistorySize = 5
    
    /// Statistics for confidence analysis
    private var confidenceStats = ConfidenceStatistics()
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Main Evaluation Methods
    
    /// Evaluate confidence for a single detected object
    /// - Parameters:
    ///   - object: The detected object to evaluate
    ///   - imageSize: Size of the source image
    ///   - context: Other detected objects in the same frame
    /// - Returns: Confidence evaluation result
    func evaluate(
        _ object: DetectedObject,
        imageSize: CGSize,
        context: [DetectedObject] = []
    ) -> ConfidenceEvaluation {
        // Calculate individual confidence factors
        let factors = calculateFactors(object, imageSize: imageSize, context: context)
        
        // Calculate weighted confidence score
        let score = calculateWeightedScore(from: factors)
        
        // Determine confidence level
        let level = determineLevel(for: score)
        
        // Generate recommendation
        let recommendation = generateRecommendation(for: level, factors: factors)
        
        // Determine if object should be filtered
        let shouldFilter = score < minimumThreshold
        
        // Update statistics
        confidenceStats.record(score: score, level: level)
        
        return ConfidenceEvaluation(
            object: object,
            level: level,
            score: score,
            factors: factors,
            recommendation: recommendation,
            shouldFilter: shouldFilter
        )
    }
    
    /// Evaluate confidence for multiple detected objects
    /// - Parameters:
    ///   - objects: Array of detected objects
    ///   - imageSize: Size of the source image
    /// - Returns: Array of confidence evaluations
    func evaluateAll(
        _ objects: [DetectedObject],
        imageSize: CGSize
    ) -> [ConfidenceEvaluation] {
        return objects.map { object in
            evaluate(object, imageSize: imageSize, context: objects)
        }
    }
    
    // MARK: - Filtering Methods
    
    /// Filter objects based on confidence threshold
    /// - Parameters:
    ///   - objects: Array of detected objects
    ///   - threshold: Minimum confidence threshold
    /// - Returns: Filtered array of objects
    func filter(
        _ objects: [DetectedObject],
        byThreshold threshold: Float
    ) -> [DetectedObject] {
        return objects.filter { $0.confidence >= threshold }
    }
    
    /// Filter objects to only include reliable detections
    /// - Parameter objects: Array of detected objects
    /// - Returns: Filtered array of reliable objects
    func filterReliable(_ objects: [DetectedObject]) -> [DetectedObject] {
        return filter(objects, byThreshold: recommendedThreshold)
    }
    
    /// Filter objects by confidence level
    /// - Parameters:
    ///   - objects: Array of detected objects
    ///   - level: Minimum confidence level
    /// - Returns: Filtered array of objects
    func filter(
        _ objects: [DetectedObject],
        byLevel level: ConfidenceLevel
    ) -> [DetectedObject] {
        return filter(objects, byThreshold: level.threshold)
    }
    
    // MARK: - Validation Methods
    
    /// Validate if an object meets minimum confidence requirements
    /// - Parameter object: The detected object to validate
    /// - Returns: True if object passes validation
    func validate(_ object: DetectedObject) -> Bool {
        return object.confidence >= minimumThreshold
    }
    
    /// Validate if an object is reliable for measurement
    /// - Parameter object: The detected object to validate
    /// - Returns: True if object is reliable
    func isReliableForMeasurement(_ object: DetectedObject) -> Bool {
        return object.confidence >= recommendedThreshold
    }
    
    /// Check if detection requires manual verification
    /// - Parameter object: The detected object to check
    /// - Returns: True if manual verification is recommended
    func requiresManualVerification(_ object: DetectedObject) -> Bool {
        let level = determineLevel(for: object.confidence)
        return level.requiresManualVerification
    }
    
    // MARK: - Factor Calculation
    
    /// Calculate all confidence factors for an object
    private func calculateFactors(
        _ object: DetectedObject,
        imageSize: CGSize,
        context: [DetectedObject]
    ) -> [ConfidenceFactor] {
        var factors: [ConfidenceFactor] = []
        
        // Detection score (from the object's confidence)
        factors.append(.detectionScore(object.confidence))
        
        // Classification score (based on object type)
        let classificationScore = calculateClassificationScore(object)
        factors.append(.classificationScore(classificationScore))
        
        // Bounding box quality
        let boxQuality = calculateBoundingBoxQuality(object.boundingBox, imageSize: imageSize)
        factors.append(.boundingBoxQuality(boxQuality))
        
        // Object size score
        let sizeScore = calculateSizeScore(object.boundingBox, imageSize: imageSize)
        factors.append(.objectSize(sizeScore))
        
        // Contextual support
        let contextScore = calculateContextualSupport(object, context: context)
        factors.append(.contextualSupport(contextScore))
        
        // Temporal consistency
        let temporalScore = calculateTemporalConsistency(object)
        factors.append(.temporalConsistency(temporalScore))
        
        return factors
    }
    
    /// Calculate classification confidence score
    private func calculateClassificationScore(_ object: DetectedObject) -> Float {
        // Higher score for known object types
        if object.objectType != .unknown {
            return min(object.confidence * 1.1, 1.0)
        }
        return object.confidence * 0.7
    }
    
    /// Calculate bounding box quality score
    private func calculateBoundingBoxQuality(_ box: CGRect, imageSize: CGSize) -> Float {
        // Check if box is well-formed
        guard box.width > 0 && box.height > 0 else { return 0.0 }
        
        // Penalize boxes that are too close to edges
        let edgeMargin: CGFloat = 10
        let tooCloseToEdge = box.minX < edgeMargin ||
                            box.minY < edgeMargin ||
                            box.maxX > imageSize.width - edgeMargin ||
                            box.maxY > imageSize.height - edgeMargin
        
        var score: Float = 1.0
        
        if tooCloseToEdge {
            score *= 0.8
        }
        
        // Penalize extreme aspect ratios
        let aspectRatio = box.width / box.height
        if aspectRatio < 0.1 || aspectRatio > 10.0 {
            score *= 0.6
        }
        
        return score
    }
    
    /// Calculate size score based on object size relative to image
    private func calculateSizeScore(_ box: CGRect, imageSize: CGSize) -> Float {
        let boxArea = box.width * box.height
        let imageArea = imageSize.width * imageSize.height
        let ratio = Float(boxArea / imageArea)
        
        // Optimal size is 5-50% of image
        if ratio >= 0.05 && ratio <= 0.50 {
            return 1.0
        } else if ratio < 0.05 {
            // Too small
            return max(ratio / 0.05, 0.3)
        } else {
            // Too large
            return max(1.0 - (ratio - 0.50) / 0.50, 0.3)
        }
    }
    
    /// Calculate contextual support score
    private func calculateContextualSupport(
        _ object: DetectedObject,
        context: [DetectedObject]
    ) -> Float {
        guard !context.isEmpty else { return 0.5 }
        
        // Check if there are similar objects nearby
        let similarObjects = context.filter { $0.objectType.category == object.objectType.category }
        
        if similarObjects.count > 1 {
            return 0.9 // Strong contextual support
        } else if !similarObjects.isEmpty {
            return 0.7 // Some contextual support
        }
        
        return 0.5 // Neutral
    }
    
    /// Calculate temporal consistency score
    private func calculateTemporalConsistency(_ object: DetectedObject) -> Float {
        guard !detectionHistory.isEmpty else { return 0.5 }
        
        // Check how many times similar objects appeared in recent history
        var matchCount = 0
        for frame in detectionHistory {
            if frame.contains(where: { $0.objectType == object.objectType }) {
                matchCount += 1
            }
        }
        
        let consistency = Float(matchCount) / Float(detectionHistory.count)
        return consistency
    }
    
    // MARK: - Score Calculation
    
    /// Calculate weighted confidence score from factors
    private func calculateWeightedScore(from factors: [ConfidenceFactor]) -> Float {
        var totalScore: Float = 0.0
        var totalWeight: Float = 0.0
        
        for factor in factors {
            totalScore += factor.value * factor.weight
            totalWeight += factor.weight
        }
        
        return totalWeight > 0 ? totalScore / totalWeight : 0.0
    }
    
    /// Determine confidence level from score
    private func determineLevel(for score: Float) -> ConfidenceLevel {
        if score >= ConfidenceLevel.veryHigh.threshold {
            return .veryHigh
        } else if score >= ConfidenceLevel.high.threshold {
            return .high
        } else if score >= ConfidenceLevel.medium.threshold {
            return .medium
        } else if score >= ConfidenceLevel.low.threshold {
            return .low
        } else {
            return .veryLow
        }
    }
    
    // MARK: - Recommendation Generation
    
    /// Generate recommendation based on confidence level and factors
    private func generateRecommendation(
        for level: ConfidenceLevel,
        factors: [ConfidenceFactor]
    ) -> String {
        switch level {
        case .veryHigh:
            return "檢測結果非常可靠，可以直接使用"
        case .high:
            return "檢測結果可靠，建議進行測量"
        case .medium:
            return "檢測結果尚可，建議使用參考物件校準"
        case .low:
            return "檢測信心度較低，建議改善拍攝條件或手動校準"
        case .veryLow:
            // Find the weakest factor
            if let weakestFactor = factors.min(by: { $0.value < $1.value }) {
                return generateSpecificRecommendation(for: weakestFactor)
            }
            return "檢測信心度很低，建議重新拍攝"
        }
    }
    
    /// Generate specific recommendation based on weak factor
    private func generateSpecificRecommendation(for factor: ConfidenceFactor) -> String {
        switch factor {
        case .detectionScore:
            return "物體檢測不清晰，請改善光線或調整角度"
        case .classificationScore:
            return "物體類型不確定，請使用參考物件進行校準"
        case .boundingBoxQuality:
            return "物體邊界不清晰，請確保物體完整在畫面中"
        case .objectSize:
            return "物體大小不適合，請調整與物體的距離"
        case .contextualSupport:
            return "缺少上下文資訊，建議包含更多參考物件"
        case .temporalConsistency:
            return "檢測結果不穩定，請保持相機穩定"
        }
    }
    
    // MARK: - History Management
    
    /// Update detection history with new frame
    /// - Parameter objects: Detected objects in the current frame
    func updateHistory(with objects: [DetectedObject]) {
        detectionHistory.append(objects)
        
        // Maintain maximum history size
        if detectionHistory.count > maxHistorySize {
            detectionHistory.removeFirst()
        }
    }
    
    /// Clear detection history
    func clearHistory() {
        detectionHistory.removeAll()
    }
    
    // MARK: - Statistics
    
    /// Get confidence statistics
    func getStatistics() -> ConfidenceStatistics {
        return confidenceStats
    }
    
    /// Reset statistics
    func resetStatistics() {
        confidenceStats = ConfidenceStatistics()
    }
}

// MARK: - Supporting Types

/// Statistics for confidence analysis
struct ConfidenceStatistics {
    var totalDetections: Int = 0
    var averageConfidence: Float = 0.0
    var levelCounts: [ConfidenceLevel: Int] = [:]
    
    mutating func record(score: Float, level: ConfidenceLevel) {
        totalDetections += 1
        
        // Update average (running average)
        averageConfidence = ((averageConfidence * Float(totalDetections - 1)) + score) / Float(totalDetections)
        
        // Update level counts
        levelCounts[level, default: 0] += 1
    }
    
    func reliabilityRate() -> Float {
        let reliableCount = (levelCounts[.veryHigh] ?? 0) + (levelCounts[.high] ?? 0)
        return totalDetections > 0 ? Float(reliableCount) / Float(totalDetections) : 0.0
    }
}
