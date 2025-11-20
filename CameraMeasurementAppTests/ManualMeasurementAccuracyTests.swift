//
//  ManualMeasurementAccuracyTests.swift
//  CameraMeasurementAppTests
//
//  Accuracy verification tests for Manual AR Measurement feature
//  需求: 4.4 - 驗證測量誤差在 ± 2% 範圍內
//

import XCTest
import SceneKit
@testable import CameraMeasurementApp

class ManualMeasurementAccuracyTests: XCTestCase {
    
    var stateManager: MeasurementStateManager!
    
    override func setUp() {
        super.setUp()
        stateManager = MeasurementStateManager()
    }
    
    override func tearDown() {
        stateManager = nil
        super.tearDown()
    }
    
    // MARK: - Distance Calculation Accuracy Tests
    
    /// Test accuracy for horizontal distance (X-axis)
    func testHorizontalDistanceAccuracy() {
        // Known distance: 1.0 meter (100 cm)
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(1.0, 0, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 1.0
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test accuracy for vertical distance (Y-axis)
    func testVerticalDistanceAccuracy() {
        // Known distance: 0.5 meter (50 cm)
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(0, 0.5, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 0.5
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test accuracy for depth distance (Z-axis)
    func testDepthDistanceAccuracy() {
        // Known distance: 2.0 meters (200 cm)
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(0, 0, 2.0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 2.0
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test accuracy for diagonal distance (3D)
    func testDiagonalDistanceAccuracy() {
        // Known distance: sqrt(3) ≈ 1.732 meters
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(1.0, 1.0, 1.0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = sqrt(3.0)
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    // MARK: - Common Real-World Distance Tests
    
    /// Test accuracy for short distance (10 cm)
    func testShortDistanceAccuracy() {
        // Known distance: 0.1 meter (10 cm)
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(0.1, 0, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 0.1
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }

    /// Test accuracy for medium distance (50 cm)
    func testMediumDistanceAccuracy() {
        // Known distance: 0.5 meter (50 cm)
        let start = SCNVector3(0.2, 0.1, 0.3)
        let end = SCNVector3(0.5, 0.4, 0.6)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        // Calculate expected: sqrt((0.3)² + (0.3)² + (0.3)²) = sqrt(0.27) ≈ 0.5196
        let expectedDistance: Float = sqrt(0.27)
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test accuracy for long distance (3 meters)
    func testLongDistanceAccuracy() {
        // Known distance: 3.0 meters (300 cm)
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(3.0, 0, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 3.0
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test accuracy for typical room measurement (2.5 meters)
    func testRoomDistanceAccuracy() {
        // Known distance: 2.5 meters (250 cm)
        let start = SCNVector3(1.0, 0.5, 0.5)
        let end = SCNVector3(3.5, 0.5, 0.5)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 2.5
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    // MARK: - Pythagorean Theorem Verification Tests
    
    /// Test 3-4-5 right triangle (classic Pythagorean triple)
    func testPythagoreanTriple345() {
        // 3-4-5 triangle: hypotenuse should be 5
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(3.0, 4.0, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 5.0
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test 5-12-13 right triangle
    func testPythagoreanTriple51213() {
        // 5-12-13 triangle: hypotenuse should be 13
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(5.0, 12.0, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 13.0
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test 3D Pythagorean theorem (1-1-1 cube diagonal)
    func testCubeDiagonal() {
        // Cube diagonal: sqrt(1² + 1² + 1²) = sqrt(3) ≈ 1.732
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(1.0, 1.0, 1.0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = sqrt(3.0)
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    // MARK: - Edge Case Tests
    
    /// Test zero distance (same point)
    func testZeroDistance() {
        let point = SCNVector3(1.0, 2.0, 3.0)
        
        let measuredDistance = stateManager.calculateDistance(from: point, to: point)
        let expectedDistance: Float = 0.0
        
        XCTAssertEqual(measuredDistance, expectedDistance, accuracy: 0.0001, 
                      "Zero distance should be exactly 0")
    }
    
    /// Test very small distance (1 mm)
    func testVerySmallDistance() {
        // Known distance: 0.001 meter (1 mm)
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(0.001, 0, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 0.001
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test maximum practical distance (10 meters)
    func testMaximumDistance() {
        // Known distance: 10.0 meters (1000 cm)
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(10.0, 0, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 10.0
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    // MARK: - Negative Coordinate Tests
    
    /// Test with negative coordinates
    func testNegativeCoordinates() {
        // Distance should be same regardless of coordinate signs
        let start = SCNVector3(-1.0, -1.0, -1.0)
        let end = SCNVector3(1.0, 1.0, 1.0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        // Distance: sqrt((2)² + (2)² + (2)²) = sqrt(12) ≈ 3.464
        let expectedDistance: Float = sqrt(12.0)
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    /// Test with mixed positive and negative coordinates
    func testMixedCoordinates() {
        let start = SCNVector3(-2.0, 1.0, -3.0)
        let end = SCNVector3(1.0, -2.0, 1.0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        // Distance: sqrt((3)² + (-3)² + (4)²) = sqrt(34) ≈ 5.831
        let expectedDistance: Float = sqrt(34.0)
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02)
    }
    
    // MARK: - Measurement Result Accuracy Tests
    
    /// Test MeasurementResult distance conversion accuracy
    func testMeasurementResultConversion() {
        let startPoint = MeasurementPoint(
            position: SCNVector3(0, 0, 0),
            timestamp: Date(),
            confidence: 1.0
        )
        
        let endPoint = MeasurementPoint(
            position: SCNVector3(1.0, 0, 0),
            timestamp: Date(),
            confidence: 1.0
        )
        
        let result = MeasurementResult(
            startPoint: startPoint,
            endPoint: endPoint,
            distance: 1.0
        )
        
        // Verify meter to centimeter conversion
        XCTAssertEqual(result.distanceInCm, 100.0, accuracy: 0.01,
                      "1 meter should equal 100 cm")
        
        // Verify formatted string
        XCTAssertEqual(result.formattedDistance, "100.0 cm",
                      "Formatted distance should be '100.0 cm'")
    }
    
    /// Test distance formatting for various values
    func testDistanceFormatting() {
        let testCases: [(Float, String)] = [
            (0.1, "10.0 cm"),      // 10 cm
            (0.5, "50.0 cm"),      // 50 cm
            (1.0, "100.0 cm"),     // 100 cm
            (1.234, "123.4 cm"),   // 123.4 cm
            (2.567, "256.7 cm"),   // 256.7 cm
            (10.0, "1000.0 cm")    // 1000 cm
        ]
        
        for (distance, expected) in testCases {
            let startPoint = MeasurementPoint(
                position: SCNVector3(0, 0, 0),
                timestamp: Date(),
                confidence: 1.0
            )
            
            let endPoint = MeasurementPoint(
                position: SCNVector3(distance, 0, 0),
                timestamp: Date(),
                confidence: 1.0
            )
            
            let result = MeasurementResult(
                startPoint: startPoint,
                endPoint: endPoint,
                distance: distance
            )
            
            XCTAssertEqual(result.formattedDistance, expected,
                          "Distance \(distance)m should format as '\(expected)'")
        }
    }
    
    // MARK: - Statistical Accuracy Tests
    
    /// Test measurement consistency (multiple measurements of same distance)
    func testMeasurementConsistency() {
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(1.5, 0, 0)
        let expectedDistance: Float = 1.5
        
        var measurements: [Float] = []
        
        // Perform 100 measurements
        for _ in 0..<100 {
            let distance = stateManager.calculateDistance(from: start, to: end)
            measurements.append(distance)
        }
        
        // All measurements should be identical (deterministic calculation)
        for measurement in measurements {
            XCTAssertEqual(measurement, expectedDistance, accuracy: 0.0001,
                          "All measurements should be consistent")
        }
        
        // Calculate statistics
        let average = measurements.reduce(0, +) / Float(measurements.count)
        XCTAssertEqual(average, expectedDistance, accuracy: 0.0001,
                      "Average should equal expected distance")
    }
    
    /// Test accuracy across multiple random distances
    func testMultipleRandomDistances() {
        let testDistances: [Float] = [
            0.05,  // 5 cm
            0.15,  // 15 cm
            0.30,  // 30 cm
            0.75,  // 75 cm
            1.20,  // 120 cm
            2.00,  // 200 cm
            3.50,  // 350 cm
            5.00   // 500 cm
        ]
        
        for expectedDistance in testDistances {
            let start = SCNVector3(0, 0, 0)
            let end = SCNVector3(expectedDistance, 0, 0)
            
            let measuredDistance = stateManager.calculateDistance(from: start, to: end)
            
            verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02,
                          message: "Distance \(expectedDistance * 100) cm")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Verify measurement accuracy within tolerance
    /// - Parameters:
    ///   - measured: Measured distance value
    ///   - expected: Expected distance value
    ///   - tolerance: Acceptable error percentage (default 0.02 for ± 2%)
    ///   - message: Optional custom message
    private func verifyAccuracy(measured: Float, expected: Float, tolerance: Float, 
                               message: String = "") {
        let error = abs(measured - expected)
        let errorPercentage = expected > 0 ? (error / expected) : 0
        
        let displayMessage = message.isEmpty ? 
            "Measured: \(measured)m, Expected: \(expected)m" : message
        
        XCTAssertLessThanOrEqual(errorPercentage, tolerance,
                                "Error \(errorPercentage * 100)% exceeds ±\(tolerance * 100)% tolerance. \(displayMessage)")
        
        // Also verify absolute accuracy
        let absoluteTolerance = expected * tolerance
        XCTAssertEqual(measured, expected, accuracy: absoluteTolerance,
                      "Measured distance should be within ±\(tolerance * 100)% of expected. \(displayMessage)")
    }
}

// MARK: - Real-World Simulation Tests

extension ManualMeasurementAccuracyTests {
    
    /// Simulate measuring a standard A4 paper (21 cm width)
    func testA4PaperWidth() {
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(0.21, 0, 0)  // 21 cm = 0.21 m
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 0.21
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02,
                      message: "A4 paper width (21 cm)")
    }
    
    /// Simulate measuring a standard door height (2 meters)
    func testDoorHeight() {
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(0, 2.0, 0)  // 2 meters
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 2.0
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02,
                      message: "Door height (200 cm)")
    }
    
    /// Simulate measuring a table diagonal (typical 1.5m x 0.8m table)
    func testTableDiagonal() {
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(1.5, 0, 0.8)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        // sqrt(1.5² + 0.8²) = sqrt(2.25 + 0.64) = sqrt(2.89) ≈ 1.7
        let expectedDistance: Float = sqrt(2.89)
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02,
                      message: "Table diagonal (1.5m x 0.8m)")
    }
    
    /// Simulate measuring room width (typical 4 meters)
    func testRoomWidth() {
        let start = SCNVector3(0, 1.0, 0)
        let end = SCNVector3(4.0, 1.0, 0)
        
        let measuredDistance = stateManager.calculateDistance(from: start, to: end)
        let expectedDistance: Float = 4.0
        
        verifyAccuracy(measured: measuredDistance, expected: expectedDistance, tolerance: 0.02,
                      message: "Room width (400 cm)")
    }
}
