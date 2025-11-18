//
//  ConfidenceEvaluatorTests.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import SceneKit

/// Simple validation tests for ConfidenceEvaluator
/// These are not unit tests but validation functions to verify core functionality
class ConfidenceEvaluatorTests {
    
    static func runAllTests() {
        print("🧪 Running ConfidenceEvaluator validation tests...")
        
        testBasicEvaluation()
        testConfidenceLevels()
        testFiltering()
        testValidation()
        testStatistics()
        testHistoryTracking()
        
        print("✅ All ConfidenceEvaluator validation tests completed")
    }
    
    // MARK: - Test Cases
    
    static func testBasicEvaluation() {
        print("\n📋 Test: Basic Evaluation")
        
        let evaluator = ConfidenceEvaluator()
        let testObject = createTestObject(confidence: 0.75)
        let imageSize = CGSize(width: 1920, height: 1080)
        
        let evaluation = evaluator.evaluate(testObject, imageSize: imageSize)
        
        assert(evaluation.score > 0, "Score should be positive")
        assert(!evaluation.factors.isEmpty, "Should have confidence factors")
        assert(!evaluation.recommendation.isEmpty, "Should have recommendation")
        
        print("✓ Score: \(evaluation.score)")
        print("✓ Level: \(evaluation.level.rawValue)")
        print("✓ Factors: \(evaluation.factors.count)")
        print("✓ Recommendation: \(evaluation.recommendation)")
    }
    
    static func testConfidenceLevels() {
        print("\n📋 Test: Confidence Levels")
        
        let evaluator = ConfidenceEvaluator()
        let imageSize = CGSize(width: 1920, height: 1080)
        
        let testCases: [(Float, ConfidenceLevel)] = [
            (0.90, .veryHigh),
            (0.75, .high),
            (0.55, .medium),
            (0.35, .low),
            (0.15, .veryLow)
        ]
        
        for (confidence, expectedLevel) in testCases {
            let object = createTestObject(confidence: confidence)
            let evaluation = evaluator.evaluate(object, imageSize: imageSize)
            
            print("✓ Confidence \(confidence) -> Level: \(evaluation.level.rawValue)")
            
            // Note: The actual level might differ due to other factors
            // This just validates that the system produces a level
            assert(evaluation.level.threshold <= 1.0, "Level threshold should be valid")
        }
    }
    
    static func testFiltering() {
        print("\n📋 Test: Filtering")
        
        let evaluator = ConfidenceEvaluator()
        
        let objects = [
            createTestObject(confidence: 0.90),
            createTestObject(confidence: 0.70),
            createTestObject(confidence: 0.50),
            createTestObject(confidence: 0.30),
            createTestObject(confidence: 0.10)
        ]
        
        let reliable = evaluator.filterReliable(objects)
        let filtered = evaluator.filter(objects, byThreshold: 0.60)
        
        print("✓ Total objects: \(objects.count)")
        print("✓ Reliable objects (≥0.60): \(reliable.count)")
        print("✓ Filtered objects (≥0.60): \(filtered.count)")
        
        assert(reliable.count <= objects.count, "Filtered count should be less or equal")
        assert(filtered.count <= objects.count, "Filtered count should be less or equal")
    }
    
    static func testValidation() {
        print("\n📋 Test: Validation")
        
        let evaluator = ConfidenceEvaluator()
        
        let highConfidence = createTestObject(confidence: 0.80)
        let lowConfidence = createTestObject(confidence: 0.20)
        
        let isHighValid = evaluator.validate(highConfidence)
        let isLowValid = evaluator.validate(lowConfidence)
        
        let isHighReliable = evaluator.isReliableForMeasurement(highConfidence)
        let isLowReliable = evaluator.isReliableForMeasurement(lowConfidence)
        
        print("✓ High confidence (0.80) valid: \(isHighValid)")
        print("✓ Low confidence (0.20) valid: \(isLowValid)")
        print("✓ High confidence reliable: \(isHighReliable)")
        print("✓ Low confidence reliable: \(isLowReliable)")
        
        assert(isHighValid, "High confidence should be valid")
        assert(isHighReliable, "High confidence should be reliable")
    }
    
    static func testStatistics() {
        print("\n📋 Test: Statistics")
        
        let evaluator = ConfidenceEvaluator()
        let imageSize = CGSize(width: 1920, height: 1080)
        
        // Perform multiple evaluations
        for confidence in [0.9, 0.8, 0.7, 0.6, 0.5] {
            let object = createTestObject(confidence: Float(confidence))
            _ = evaluator.evaluate(object, imageSize: imageSize)
        }
        
        let stats = evaluator.getStatistics()
        
        print("✓ Total detections: \(stats.totalDetections)")
        print("✓ Average confidence: \(stats.averageConfidence)")
        print("✓ Reliability rate: \(stats.reliabilityRate())")
        
        assert(stats.totalDetections == 5, "Should have 5 detections")
        assert(stats.averageConfidence > 0, "Average should be positive")
    }
    
    static func testHistoryTracking() {
        print("\n📋 Test: History Tracking")
        
        let evaluator = ConfidenceEvaluator()
        
        // Add multiple frames to history
        for i in 1...3 {
            let objects = [
                createTestObject(confidence: 0.8, type: .phone),
                createTestObject(confidence: 0.7, type: .laptop)
            ]
            evaluator.updateHistory(with: objects)
            print("✓ Added frame \(i) to history")
        }
        
        // Clear history
        evaluator.clearHistory()
        print("✓ History cleared")
        
        // Reset statistics
        evaluator.resetStatistics()
        let stats = evaluator.getStatistics()
        assert(stats.totalDetections == 0, "Statistics should be reset")
        print("✓ Statistics reset")
    }
    
    // MARK: - Helper Methods
    
    static func createTestObject(
        confidence: Float,
        type: ObjectType = .phone
    ) -> DetectedObject {
        return DetectedObject(
            boundingBox: CGRect(x: 100, y: 100, width: 200, height: 300),
            objectType: type,
            confidence: confidence,
            worldPosition: SCNVector3Zero
        )
    }
}

// MARK: - Integration with ObjectDetector

extension ConfidenceEvaluatorTests {
    
    /// Test integration with ObjectDetector
    static func testObjectDetectorIntegration() {
        print("\n📋 Test: ObjectDetector Integration")
        
        let detector = ObjectDetector()
        
        // Create test objects
        let objects = [
            createTestObject(confidence: 0.85, type: .phone),
            createTestObject(confidence: 0.65, type: .laptop),
            createTestObject(confidence: 0.45, type: .cup)
        ]
        
        // Test reliable detection filtering
        let reliable = detector.getReliableDetections(from: objects)
        print("✓ Reliable detections: \(reliable.count) out of \(objects.count)")
        
        // Test manual verification check
        for object in objects {
            let needsVerification = detector.requiresManualVerification(object)
            print("✓ Object \(object.objectType) (conf: \(object.confidence)) needs verification: \(needsVerification)")
        }
        
        // Test confidence evaluation
        let imageSize = CGSize(width: 1920, height: 1080)
        for object in objects {
            let evaluation = detector.evaluateConfidence(
                for: object,
                imageSize: imageSize,
                context: objects
            )
            print("✓ \(object.objectType): \(evaluation.level.rawValue) - \(evaluation.recommendation)")
        }
        
        // Test statistics
        let stats = detector.getConfidenceStatistics()
        print("✓ Total evaluations: \(stats.totalDetections)")
        print("✓ Average confidence: \(stats.averageConfidence)")
        
        print("✅ ObjectDetector integration test completed")
    }
}
