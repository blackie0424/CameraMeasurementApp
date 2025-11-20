//
//  ManualMeasurementIntegrationTests.swift
//  CameraMeasurementAppTests
//
//  Integration tests for Manual AR Measurement feature
//

import Testing
import SceneKit
@testable import CameraMeasurementApp

/// Integration tests for Manual AR Measurement feature (Task 7.1)
/// Tests the coordination between all components and state transitions
struct ManualMeasurementIntegrationTests {
    
    // MARK: - State Manager Integration Tests
    
    @Test("State Manager: Initial state")
    func testStateManagerInitialState() async throws {
        let stateManager = MeasurementStateManager()
        
        // Verify initial state
        if case .initial = stateManager.currentState {
            // Success
        } else {
            Issue.record("Expected initial state")
        }
        
        // Verify no points recorded
        #expect(stateManager.startPoint == nil)
        #expect(stateManager.endPoint == nil)
    }
    
    @Test("State Manager: Record start point")
    func testStateManagerRecordStartPoint() async throws {
        let stateManager = MeasurementStateManager()
        let startPosition = SCNVector3(1.0, 0.5, -2.0)
        
        // Record start point
        stateManager.recordStartPoint(startPosition)
        
        // Verify state transition
        if case .startPointRecorded(let position) = stateManager.currentState {
            #expect(position.x == startPosition.x)
            #expect(position.y == startPosition.y)
            #expect(position.z == startPosition.z)
        } else {
            Issue.record("Expected startPointRecorded state")
        }
        
        // Verify start point accessible
        #expect(stateManager.startPoint != nil)
        #expect(stateManager.endPoint == nil)
    }
    
    @Test("State Manager: Record end point and calculate distance")
    func testStateManagerRecordEndPoint() async throws {
        let stateManager = MeasurementStateManager()
        let startPosition = SCNVector3(0.0, 0.0, 0.0)
        let endPosition = SCNVector3(3.0, 4.0, 0.0)
        
        // Record start and end points
        stateManager.recordStartPoint(startPosition)
        stateManager.recordEndPoint(endPosition)
        
        // Verify state transition
        if case .measurementComplete(let start, let end, let distance) = stateManager.currentState {
            #expect(start.x == startPosition.x)
            #expect(end.x == endPosition.x)
            
            // Verify distance calculation (3-4-5 triangle: distance should be 5.0)
            #expect(abs(distance - 5.0) < 0.001)
        } else {
            Issue.record("Expected measurementComplete state")
        }
        
        // Verify both points accessible
        #expect(stateManager.startPoint != nil)
        #expect(stateManager.endPoint != nil)
    }
    
    @Test("State Manager: Reset functionality")
    func testStateManagerReset() async throws {
        let stateManager = MeasurementStateManager()
        
        // Record a complete measurement
        stateManager.recordStartPoint(SCNVector3(0, 0, 0))
        stateManager.recordEndPoint(SCNVector3(1, 0, 0))
        
        // Reset
        stateManager.reset()
        
        // Verify back to initial state
        if case .initial = stateManager.currentState {
            // Success
        } else {
            Issue.record("Expected initial state after reset")
        }
        
        #expect(stateManager.startPoint == nil)
        #expect(stateManager.endPoint == nil)
    }
    
    @Test("State Manager: Distance calculation accuracy")
    func testDistanceCalculationAccuracy() async throws {
        let stateManager = MeasurementStateManager()
        
        // Test case 1: Simple horizontal distance
        let distance1 = stateManager.calculateDistance(
            from: SCNVector3(0, 0, 0),
            to: SCNVector3(1, 0, 0)
        )
        #expect(abs(distance1 - 1.0) < 0.001)
        
        // Test case 2: 3D distance (3-4-5 triangle)
        let distance2 = stateManager.calculateDistance(
            from: SCNVector3(0, 0, 0),
            to: SCNVector3(3, 4, 0)
        )
        #expect(abs(distance2 - 5.0) < 0.001)
        
        // Test case 3: Diagonal 3D distance
        let distance3 = stateManager.calculateDistance(
            from: SCNVector3(0, 0, 0),
            to: SCNVector3(1, 1, 1)
        )
        let expected3 = sqrt(3.0)
        #expect(abs(distance3 - Float(expected3)) < 0.001)
    }
    
    // MARK: - Data Model Tests
    
    @Test("MeasurementPoint: Initialization")
    func testMeasurementPointInitialization() async throws {
        let position = SCNVector3(1.0, 2.0, 3.0)
        let point = MeasurementPoint(position: position)
        
        #expect(point.position.x == position.x)
        #expect(point.position.y == position.y)
        #expect(point.position.z == position.z)
        #expect(point.confidence == 1.0)
    }
    
    @Test("MeasurementResult: Distance conversion")
    func testMeasurementResultDistanceConversion() async throws {
        let startPoint = MeasurementPoint(position: SCNVector3(0, 0, 0))
        let endPoint = MeasurementPoint(position: SCNVector3(1, 0, 0))
        let distance: Float = 1.5 // meters
        
        let result = MeasurementResult(
            startPoint: startPoint,
            endPoint: endPoint,
            distance: distance
        )
        
        // Verify conversion to centimeters
        #expect(result.distanceInCm == 150.0)
        
        // Verify formatted string
        #expect(result.formattedDistance == "150.0 cm")
    }
    
    @Test("ManualMeasurementError: Localized descriptions")
    func testErrorLocalizedDescriptions() async throws {
        let errors: [ManualMeasurementError] = [
            .arSessionFailed,
            .hitTestFailed,
            .invalidMeasurementPoint,
            .insufficientTracking
        ]
        
        // Verify all errors have localized descriptions
        for error in errors {
            let description = error.localizedDescription
            #expect(!description.isEmpty)
        }
    }
    
    // MARK: - State Transition Flow Tests
    
    @Test("Complete measurement flow: Initial → Start → End → Reset")
    func testCompleteMeasurementFlow() async throws {
        let stateManager = MeasurementStateManager()
        
        // Step 1: Initial state
        if case .initial = stateManager.currentState {
            // Success
        } else {
            Issue.record("Should start in initial state")
        }
        
        // Step 2: Record start point
        let startPos = SCNVector3(0, 0, 0)
        stateManager.recordStartPoint(startPos)
        
        if case .startPointRecorded = stateManager.currentState {
            // Success
        } else {
            Issue.record("Should transition to startPointRecorded")
        }
        
        // Step 3: Record end point
        let endPos = SCNVector3(1, 0, 0)
        stateManager.recordEndPoint(endPos)
        
        if case .measurementComplete(let start, let end, let distance) = stateManager.currentState {
            #expect(start.x == startPos.x)
            #expect(end.x == endPos.x)
            #expect(abs(distance - 1.0) < 0.001)
        } else {
            Issue.record("Should transition to measurementComplete")
        }
        
        // Step 4: Reset
        stateManager.reset()
        
        if case .initial = stateManager.currentState {
            // Success
        } else {
            Issue.record("Should return to initial state after reset")
        }
    }
    
    @Test("State transition: Cannot record end point without start point")
    func testCannotRecordEndPointWithoutStart() async throws {
        let stateManager = MeasurementStateManager()
        
        // Try to record end point without start point
        stateManager.recordEndPoint(SCNVector3(1, 0, 0))
        
        // Should remain in initial state
        if case .initial = stateManager.currentState {
            // Success - state didn't change
        } else {
            Issue.record("Should remain in initial state")
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Distance calculation: Zero distance")
    func testZeroDistance() async throws {
        let stateManager = MeasurementStateManager()
        let position = SCNVector3(1, 2, 3)
        
        let distance = stateManager.calculateDistance(from: position, to: position)
        #expect(distance == 0.0)
    }
    
    @Test("Distance calculation: Negative coordinates")
    func testNegativeCoordinates() async throws {
        let stateManager = MeasurementStateManager()
        
        let distance = stateManager.calculateDistance(
            from: SCNVector3(-1, -1, -1),
            to: SCNVector3(1, 1, 1)
        )
        
        // Distance from (-1,-1,-1) to (1,1,1) is sqrt(12) ≈ 3.464
        let expected = sqrt(12.0)
        #expect(abs(distance - Float(expected)) < 0.001)
    }
    
    @Test("Distance calculation: Large distances")
    func testLargeDistances() async throws {
        let stateManager = MeasurementStateManager()
        
        let distance = stateManager.calculateDistance(
            from: SCNVector3(0, 0, 0),
            to: SCNVector3(100, 0, 0)
        )
        
        #expect(abs(distance - 100.0) < 0.001)
    }
    
    // MARK: - Component Coordination Tests
    
    @Test("State and distance consistency")
    func testStateAndDistanceConsistency() async throws {
        let stateManager = MeasurementStateManager()
        
        let start = SCNVector3(0, 0, 0)
        let end = SCNVector3(3, 4, 0)
        
        // Record points
        stateManager.recordStartPoint(start)
        stateManager.recordEndPoint(end)
        
        // Calculate distance independently
        let expectedDistance = stateManager.calculateDistance(from: start, to: end)
        
        // Verify state contains same distance
        if case .measurementComplete(_, _, let stateDistance) = stateManager.currentState {
            #expect(abs(stateDistance - expectedDistance) < 0.001)
        } else {
            Issue.record("Expected measurementComplete state")
        }
    }
    
    @Test("Multiple measurement cycles")
    func testMultipleMeasurementCycles() async throws {
        let stateManager = MeasurementStateManager()
        
        // Cycle 1
        stateManager.recordStartPoint(SCNVector3(0, 0, 0))
        stateManager.recordEndPoint(SCNVector3(1, 0, 0))
        
        if case .measurementComplete(_, _, let distance1) = stateManager.currentState {
            #expect(abs(distance1 - 1.0) < 0.001)
        } else {
            Issue.record("First measurement should complete")
        }
        
        // Reset and Cycle 2
        stateManager.reset()
        stateManager.recordStartPoint(SCNVector3(0, 0, 0))
        stateManager.recordEndPoint(SCNVector3(2, 0, 0))
        
        if case .measurementComplete(_, _, let distance2) = stateManager.currentState {
            #expect(abs(distance2 - 2.0) < 0.001)
        } else {
            Issue.record("Second measurement should complete")
        }
    }
    
    // MARK: - Requirements Verification Tests
    
    @Test("Requirement 2.5: Store 3D world coordinates")
    func testStoreWorldCoordinates() async throws {
        let stateManager = MeasurementStateManager()
        let position = SCNVector3(1.5, 2.5, -3.5)
        
        stateManager.recordStartPoint(position)
        
        guard let storedPosition = stateManager.startPoint else {
            Issue.record("Start point should be stored")
            return
        }
        
        #expect(storedPosition.x == position.x)
        #expect(storedPosition.y == position.y)
        #expect(storedPosition.z == position.z)
    }
    
    @Test("Requirement 4.4: Euclidean distance calculation")
    func testEuclideanDistanceFormula() async throws {
        let stateManager = MeasurementStateManager()
        
        // Test the formula: sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)
        let start = SCNVector3(1, 2, 3)
        let end = SCNVector3(4, 6, 8)
        
        let distance = stateManager.calculateDistance(from: start, to: end)
        
        // Manual calculation: sqrt(9 + 16 + 25) = sqrt(50) ≈ 7.071
        let expected = sqrt(9.0 + 16.0 + 25.0)
        #expect(abs(distance - Float(expected)) < 0.001)
    }
    
    @Test("Requirement 4.6: Distance precision (1 decimal place)")
    func testDistancePrecision() async throws {
        let startPoint = MeasurementPoint(position: SCNVector3(0, 0, 0))
        let endPoint = MeasurementPoint(position: SCNVector3(1.234, 0, 0))
        let distance: Float = 1.234
        
        let result = MeasurementResult(
            startPoint: startPoint,
            endPoint: endPoint,
            distance: distance
        )
        
        // Formatted distance should have 1 decimal place
        let formatted = result.formattedDistance
        #expect(formatted == "123.4 cm")
    }
    
    @Test("Requirement 5.3: Reset clears measurement state")
    func testResetClearsState() async throws {
        let stateManager = MeasurementStateManager()
        
        // Create a complete measurement
        stateManager.recordStartPoint(SCNVector3(0, 0, 0))
        stateManager.recordEndPoint(SCNVector3(1, 0, 0))
        
        // Verify measurement exists
        #expect(stateManager.startPoint != nil)
        #expect(stateManager.endPoint != nil)
        
        // Reset
        stateManager.reset()
        
        // Verify state is cleared
        #expect(stateManager.startPoint == nil)
        #expect(stateManager.endPoint == nil)
        
        if case .initial = stateManager.currentState {
            // Success
        } else {
            Issue.record("State should be initial after reset")
        }
    }
}
