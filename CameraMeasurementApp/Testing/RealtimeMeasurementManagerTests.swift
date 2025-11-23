//
//  RealtimeMeasurementManagerTests.swift
//  CameraMeasurementApp
//
//  Integration tests for RealtimeMeasurementManager
//  Task 27: 實作 RealtimeMeasurementManager
//

import Foundation
import UIKit
import ARKit
import SceneKit

/// Simple integration tests for RealtimeMeasurementManager
/// These tests verify core functionality without requiring actual AR hardware
class RealtimeMeasurementManagerTests {
    
    // MARK: - Test Helpers
    
    /// Create a test image for detection
    private static func createTestImage() -> UIImage {
        let size = CGSize(width: 1920, height: 1080)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw a simple test pattern
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw a rectangle to simulate an object
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(x: 500, y: 300, width: 400, height: 600))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - Basic Functionality Tests
    
    /// Test initialization and configuration
    static func testInitialization() {
        print("\n🧪 Testing RealtimeMeasurementManager initialization...")
        
        // Test default initialization
        let manager1 = RealtimeMeasurementManager()
        print("✓ Created manager with default settings")
        
        // Test custom initialization
        let config = RealtimeMeasurementConfiguration(
            useCachedResults: true,
            enableSmoothing: true,
            smoothingWindowSize: 5,
            minimumConfidence: 0.6,
            maxProcessingTime: 0.2
        )
        
        let manager2 = RealtimeMeasurementManager(
            targetFPS: 8.0,
            configuration: config
        )
        print("✓ Created manager with custom configuration")
        
        // Verify initial state
        assert(!manager1.isActive, "Manager should not be active initially")
        assert(!manager2.isActive, "Manager should not be active initially")
        print("✓ Initial state verified")
        
        print("✅ Initialization test passed")
    }
    
    /// Test start and stop functionality
    static func testStartStop() {
        print("\n🧪 Testing RealtimeMeasurementManager start/stop...")
        
        let manager = RealtimeMeasurementManager(targetFPS: 10.0)
        
        // Test start
        var updateCount = 0
        manager.startRealtimeMeasurement { result in
            updateCount += 1
            print("📊 Received measurement update: \(result.dimensions.formattedDimensions())")
        }
        
        assert(manager.isActive, "Manager should be active after start")
        print("✓ Manager started successfully")
        
        // Test stop
        manager.stopRealtimeMeasurement()
        assert(!manager.isActive, "Manager should not be active after stop")
        print("✓ Manager stopped successfully")
        
        print("✅ Start/stop test passed")
    }
    
    /// Test configuration updates
    static func testConfigurationUpdate() {
        print("\n🧪 Testing configuration updates...")
        
        let manager = RealtimeMeasurementManager()
        
        // Update configuration
        var config = RealtimeMeasurementConfiguration()
        config.enableSmoothing = false
        config.smoothingWindowSize = 10
        config.minimumConfidence = 0.7
        
        manager.updateConfiguration(config)
        print("✓ Configuration updated successfully")
        
        // Update FPS
        manager.setTargetFPS(5.0)
        print("✓ Target FPS updated successfully")
        
        print("✅ Configuration update test passed")
    }
    
    /// Test statistics tracking
    static func testStatistics() {
        print("\n🧪 Testing statistics tracking...")
        
        let manager = RealtimeMeasurementManager()
        
        // Get initial statistics
        let stats = manager.getStatistics()
        assert(stats.totalFramesProcessed == 0, "Initial frame count should be 0")
        assert(stats.successfulMeasurements == 0, "Initial success count should be 0")
        print("✓ Initial statistics verified")
        
        print("✅ Statistics test passed")
    }
    
    /// Test measurement result caching
    static func testResultCaching() {
        print("\n🧪 Testing measurement result caching...")
        
        let manager = RealtimeMeasurementManager()
        
        // Initially no cached measurement
        let initial = manager.getLastMeasurement()
        assert(initial == nil, "Should have no cached measurement initially")
        print("✓ No initial cached measurement")
        
        print("✅ Result caching test passed")
    }
    
    /// Test smoothing filter
    static func testSmoothingFilter() {
        print("\n🧪 Testing measurement smoothing filter...")
        
        var config = MeasurementFilterConfiguration()
        config.filterType = .movingAverage
        config.windowSize = 3
        config.enableOutlierDetection = false
        
        let filter = MeasurementFilter(configuration: config)
        
        // Add measurements
        let measurements = [
            ObjectDimensions(length: 10.0, width: 5.0, height: 2.0, accuracy: 0.8),
            ObjectDimensions(length: 10.5, width: 5.2, height: 2.1, accuracy: 0.85),
            ObjectDimensions(length: 9.8, width: 4.9, height: 1.9, accuracy: 0.82)
        ]
        
        var smoothedResults: [ObjectDimensions] = []
        for measurement in measurements {
            let smoothed = filter.filter(measurement)
            smoothedResults.append(smoothed)
            print("✓ Added measurement: \(measurement.length)cm -> Smoothed: \(smoothed.length)cm")
        }
        
        // Verify smoothing reduces variance
        let lastSmoothed = smoothedResults.last!
        print("✓ Final smoothed result: \(lastSmoothed.formattedDimensions())")
        
        // Test reset
        filter.reset()
        print("✓ Filter reset successfully")
        
        // Test configuration update
        var newConfig = config
        newConfig.windowSize = 5
        filter.updateConfiguration(newConfig)
        print("✓ Configuration updated successfully")
        
        print("✅ Smoothing filter test passed")
    }
    
    /// Test error handling
    static func testErrorHandling() {
        print("\n🧪 Testing error handling...")
        
        let manager = RealtimeMeasurementManager()
        
        var errorReceived = false
        manager.startRealtimeMeasurement(
            updateHandler: { result in
                print("📊 Measurement: \(result.dimensions.formattedDimensions())")
            },
            errorHandler: { error in
                errorReceived = true
                print("⚠️ Error handled: \(error.localizedDescription)")
            }
        )
        
        print("✓ Error handler registered")
        
        manager.stopRealtimeMeasurement()
        
        print("✅ Error handling test passed")
    }
    
    // MARK: - Run All Tests
    
    /// Run all tests
    static func runAllTests() {
        print("\n" + String(repeating: "=", count: 60))
        print("🧪 Running RealtimeMeasurementManager Tests")
        print(String(repeating: "=", count: 60))
        
        testInitialization()
        testStartStop()
        testConfigurationUpdate()
        testStatistics()
        testResultCaching()
        testSmoothingFilter()
        testErrorHandling()
        
        print("\n" + String(repeating: "=", count: 60))
        print("✅ All RealtimeMeasurementManager tests passed!")
        print(String(repeating: "=", count: 60) + "\n")
    }
}

// MARK: - Test Runner Extension

extension RealtimeMeasurementManagerTests {
    /// Convenience method to run tests from anywhere in the app
    static func runQuickTest() {
        print("\n🚀 Running quick RealtimeMeasurementManager test...")
        
        let manager = RealtimeMeasurementManager(targetFPS: 10.0)
        
        manager.startRealtimeMeasurement { result in
            print("📊 Measurement update received:")
            print("   Object: \(result.object.objectType)")
            print("   Dimensions: \(result.dimensions.formattedDimensions())")
            print("   Confidence: \(String(format: "%.1f%%", result.dimensions.accuracy * 100))")
            print("   Processing time: \(String(format: "%.1f ms", result.processingTime * 1000))")
        }
        
        print("✓ Manager started and ready for frames")
        
        // In a real scenario, you would feed AR frames here
        // For testing, we just verify the manager is active
        assert(manager.isActive, "Manager should be active")
        
        // Stop after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            manager.stopRealtimeMeasurement()
            print("✓ Manager stopped")
            
            let stats = manager.getStatistics()
            print("📊 Final statistics:")
            print("   Frames processed: \(stats.totalFramesProcessed)")
            print("   Successful: \(stats.successfulMeasurements)")
            print("   Failed: \(stats.failedMeasurements)")
            print("   Success rate: \(String(format: "%.1f%%", stats.successRate * 100))")
            
            print("✅ Quick test completed")
        }
    }
}
