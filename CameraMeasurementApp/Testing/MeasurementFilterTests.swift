//
//  MeasurementFilterTests.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//  Task 28: 測試測量數值平滑演算法
//

import Foundation

/// Test suite for MeasurementFilter
class MeasurementFilterTests {
    
    // MARK: - Test Moving Average Filter
    
    static func testMovingAverageFilter() {
        print("\n🧪 Testing Moving Average Filter")
        print("=" + String(repeating: "=", count: 50))
        
        var config = MeasurementFilterConfiguration()
        config.filterType = .movingAverage
        config.windowSize = 5
        config.enableOutlierDetection = false
        
        let filter = MeasurementFilter(configuration: config)
        
        // Create test measurements with some noise
        let testMeasurements = [
            ObjectDimensions(length: 10.0, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 10.2, width: 5.1, height: 3.1, accuracy: 0.9),
            ObjectDimensions(length: 9.8, width: 4.9, height: 2.9, accuracy: 0.9),
            ObjectDimensions(length: 10.1, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 9.9, width: 5.2, height: 3.1, accuracy: 0.9),
        ]
        
        print("\n📊 Input measurements:")
        for (index, measurement) in testMeasurements.enumerated() {
            print("   \(index + 1). \(measurement.formattedDimensions())")
        }
        
        print("\n📊 Filtered measurements:")
        for (index, measurement) in testMeasurements.enumerated() {
            let filtered = filter.filter(measurement)
            print("   \(index + 1). \(filtered.formattedDimensions())")
        }
        
        let stats = filter.getStatistics()
        print("\n")
        stats.printSummary()
        
        print("✅ Moving Average Filter test completed\n")
    }
    
    // MARK: - Test Kalman Filter
    
    static func testKalmanFilter() {
        print("\n🧪 Testing Kalman Filter")
        print("=" + String(repeating: "=", count: 50))
        
        var config = MeasurementFilterConfiguration()
        config.filterType = .kalman
        config.kalmanProcessNoise = 0.01
        config.kalmanMeasurementNoise = 0.1
        config.enableOutlierDetection = false
        
        let filter = MeasurementFilter(configuration: config)
        
        // Create test measurements with noise
        let testMeasurements = [
            ObjectDimensions(length: 10.0, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 10.5, width: 5.3, height: 3.2, accuracy: 0.9),
            ObjectDimensions(length: 9.7, width: 4.8, height: 2.9, accuracy: 0.9),
            ObjectDimensions(length: 10.2, width: 5.1, height: 3.1, accuracy: 0.9),
            ObjectDimensions(length: 9.9, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 10.1, width: 5.2, height: 3.1, accuracy: 0.9),
        ]
        
        print("\n📊 Input measurements:")
        for (index, measurement) in testMeasurements.enumerated() {
            print("   \(index + 1). \(measurement.formattedDimensions())")
        }
        
        print("\n📊 Filtered measurements:")
        for (index, measurement) in testMeasurements.enumerated() {
            let filtered = filter.filter(measurement)
            print("   \(index + 1). \(filtered.formattedDimensions())")
        }
        
        let stats = filter.getStatistics()
        print("\n")
        stats.printSummary()
        
        print("✅ Kalman Filter test completed\n")
    }
    
    // MARK: - Test Exponential Moving Average
    
    static func testExponentialMovingAverage() {
        print("\n🧪 Testing Exponential Moving Average Filter")
        print("=" + String(repeating: "=", count: 50))
        
        var config = MeasurementFilterConfiguration()
        config.filterType = .exponentialMovingAverage
        config.emaAlpha = 0.3
        config.enableOutlierDetection = false
        
        let filter = MeasurementFilter(configuration: config)
        
        // Create test measurements with a step change
        let testMeasurements = [
            ObjectDimensions(length: 10.0, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 10.1, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 10.0, width: 5.1, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 15.0, width: 7.0, height: 4.0, accuracy: 0.9), // Step change
            ObjectDimensions(length: 15.1, width: 7.1, height: 4.0, accuracy: 0.9),
            ObjectDimensions(length: 14.9, width: 6.9, height: 4.1, accuracy: 0.9),
        ]
        
        print("\n📊 Input measurements (with step change at #4):")
        for (index, measurement) in testMeasurements.enumerated() {
            print("   \(index + 1). \(measurement.formattedDimensions())")
        }
        
        print("\n📊 Filtered measurements:")
        for (index, measurement) in testMeasurements.enumerated() {
            let filtered = filter.filter(measurement)
            print("   \(index + 1). \(filtered.formattedDimensions())")
        }
        
        let stats = filter.getStatistics()
        print("\n")
        stats.printSummary()
        
        print("✅ Exponential Moving Average test completed\n")
    }
    
    // MARK: - Test Outlier Detection
    
    static func testOutlierDetection() {
        print("\n🧪 Testing Outlier Detection")
        print("=" + String(repeating: "=", count: 50))
        
        var config = MeasurementFilterConfiguration()
        config.filterType = .movingAverage
        config.windowSize = 5
        config.enableOutlierDetection = true
        config.outlierThreshold = 2.5
        
        let filter = MeasurementFilter(configuration: config)
        
        // Create test measurements with outliers
        let testMeasurements = [
            ObjectDimensions(length: 10.0, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 10.1, width: 5.1, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 10.0, width: 5.0, height: 3.1, accuracy: 0.9),
            ObjectDimensions(length: 50.0, width: 25.0, height: 15.0, accuracy: 0.9), // Outlier!
            ObjectDimensions(length: 10.2, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 9.9, width: 5.1, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 2.0, width: 1.0, height: 0.5, accuracy: 0.9), // Outlier!
            ObjectDimensions(length: 10.0, width: 5.0, height: 3.0, accuracy: 0.9),
        ]
        
        print("\n📊 Input measurements (with outliers at #4 and #7):")
        for (index, measurement) in testMeasurements.enumerated() {
            print("   \(index + 1). \(measurement.formattedDimensions())")
        }
        
        print("\n📊 Filtered measurements (outliers should be rejected):")
        for (index, measurement) in testMeasurements.enumerated() {
            let filtered = filter.filter(measurement)
            print("   \(index + 1). \(filtered.formattedDimensions())")
        }
        
        let stats = filter.getStatistics()
        print("\n")
        stats.printSummary()
        
        print("✅ Outlier Detection test completed\n")
    }
    
    // MARK: - Test Invalid Measurement Handling
    
    static func testInvalidMeasurementHandling() {
        print("\n🧪 Testing Invalid Measurement Handling")
        print("=" + String(repeating: "=", count: 50))
        
        var config = MeasurementFilterConfiguration()
        config.filterType = .movingAverage
        config.windowSize = 3
        
        let filter = MeasurementFilter(configuration: config)
        
        // Add some valid measurements first
        let validMeasurements = [
            ObjectDimensions(length: 10.0, width: 5.0, height: 3.0, accuracy: 0.9),
            ObjectDimensions(length: 10.1, width: 5.1, height: 3.0, accuracy: 0.9),
        ]
        
        print("\n📊 Adding valid measurements:")
        for (index, measurement) in validMeasurements.enumerated() {
            let filtered = filter.filter(measurement)
            print("   \(index + 1). \(filtered.formattedDimensions())")
        }
        
        // Try invalid measurements
        print("\n📊 Testing invalid measurements:")
        
        // Negative value
        let invalid1 = ObjectDimensions(length: -10.0, width: 5.0, height: 3.0, accuracy: 0.9)
        let filtered1 = filter.filter(invalid1)
        print("   Negative value: \(filtered1.formattedDimensions()) (should use last valid)")
        
        // NaN value
        let invalid2 = ObjectDimensions(length: Float.nan, width: 5.0, height: 3.0, accuracy: 0.9)
        let filtered2 = filter.filter(invalid2)
        print("   NaN value: \(filtered2.formattedDimensions()) (should use last valid)")
        
        // Unreasonably large value
        let invalid3 = ObjectDimensions(length: 2000.0, width: 1000.0, height: 500.0, accuracy: 0.9)
        let filtered3 = filter.filter(invalid3)
        print("   Too large: \(filtered3.formattedDimensions()) (should use last valid)")
        
        let stats = filter.getStatistics()
        print("\n")
        stats.printSummary()
        
        print("✅ Invalid Measurement Handling test completed\n")
    }
    
    // MARK: - Test Filter Reset
    
    static func testFilterReset() {
        print("\n🧪 Testing Filter Reset")
        print("=" + String(repeating: "=", count: 50))
        
        let filter = MeasurementFilter()
        
        // Add some measurements
        print("\n📊 Adding measurements:")
        for i in 1...5 {
            let measurement = ObjectDimensions(
                length: Float(10 + i),
                width: Float(5 + i),
                height: Float(3 + i),
                accuracy: 0.9
            )
            let filtered = filter.filter(measurement)
            print("   \(i). \(filtered.formattedDimensions())")
        }
        
        var stats = filter.getStatistics()
        print("\n📊 Before reset:")
        print("   Measurement count: \(stats.measurementCount)")
        print("   Buffer size: \(stats.bufferSize)")
        
        // Reset filter
        filter.reset()
        print("\n🔄 Filter reset")
        
        stats = filter.getStatistics()
        print("\n📊 After reset:")
        print("   Measurement count: \(stats.measurementCount)")
        print("   Buffer size: \(stats.bufferSize)")
        
        print("\n✅ Filter Reset test completed\n")
    }
    
    // MARK: - Run All Tests
    
    static func runAllTests() {
        print("\n" + String(repeating: "=", count: 60))
        print("🧪 MeasurementFilter Test Suite")
        print(String(repeating: "=", count: 60))
        
        testMovingAverageFilter()
        testKalmanFilter()
        testExponentialMovingAverage()
        testOutlierDetection()
        testInvalidMeasurementHandling()
        testFilterReset()
        
        print(String(repeating: "=", count: 60))
        print("✅ All tests completed!")
        print(String(repeating: "=", count: 60) + "\n")
    }
}
