//
//  MockDataExamples.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//  Purpose: Example usage of MockDataGenerator for testing
//

import Foundation
import UIKit

/// Example usage patterns for MockDataGenerator
class MockDataExamples {
    
    // MARK: - Basic Usage Examples
    
    /// Example 1: Generate a single object for quick testing
    static func example1_SingleObject() -> DetectedObject {
        return MockDataGenerator.shared.generateMockDetectedObject(
            objectType: .phone,
            confidence: 0.90,
            withDimensions: true
        )
    }
    
    /// Example 2: Generate multiple objects for list testing
    static func example2_MultipleObjects() -> [DetectedObject] {
        return MockDataGenerator.shared.generateMockDetectedObjects(count: 5)
    }
    
    /// Example 3: Generate a complete measurement record
    static func example3_MeasurementRecord() -> MeasurementRecord {
        return MockDataGenerator.shared.generateMockMeasurementRecord(
            withObjects: 3,
            includeReferenceObject: true
        )
    }
    
    // MARK: - Scenario-Based Examples
    
    /// Example 4: Test high-accuracy detection scenario
    static func example4_HighAccuracyTest() -> MeasurementRecord {
        let record = MockDataGenerator.shared.generateHighAccuracyScenario()
        
        print("High Accuracy Test:")
        print("- Objects detected: \(record.detectedObjects.count)")
        print("- Average accuracy: \(record.averageAccuracy)")
        print("- Has reference: \(record.referenceObject != nil)")
        
        return record
    }
    
    /// Example 5: Test low-confidence detection handling
    static func example5_LowConfidenceTest() -> MeasurementRecord {
        let record = MockDataGenerator.shared.generateLowConfidenceScenario()
        
        print("Low Confidence Test:")
        for object in record.detectedObjects {
            print("- \(object.objectType.displayName): \(object.confidence)")
        }
        
        return record
    }
    
    /// Example 6: Test multi-object detection
    static func example6_MultiObjectTest() -> MeasurementRecord {
        let record = MockDataGenerator.shared.generateMultiObjectScenario()
        
        print("Multi-Object Test:")
        for object in record.detectedObjects {
            if let dims = object.dimensions {
                print("- \(object.objectType.displayName): \(dims.formattedDimensions())")
            }
        }
        
        return record
    }
    
    // MARK: - UI Testing Examples
    
    /// Example 7: Generate data for testing results view
    static func example7_ResultsViewData() -> MeasurementRecord {
        // Create a realistic scenario with 2 objects and a reference
        let phone = MockDataGenerator.shared.generateMockDetectedObject(
            objectType: .phone,
            confidence: 0.92,
            withDimensions: true
        )
        
        let book = MockDataGenerator.shared.generateMockDetectedObject(
            objectType: .book,
            confidence: 0.88,
            withDimensions: true
        )
        
        return MeasurementRecord(
            image: UIImage(systemName: "camera.fill") ?? UIImage(),
            detectedObjects: [phone, book],
            referenceObject: ReferenceObject.creditCard,
            timestamp: Date()
        )
    }
    
    /// Example 8: Generate historical data for testing list views
    static func example8_HistoricalData() -> [MeasurementRecord] {
        return MockDataGenerator.shared.generateHistoricalRecords(
            count: 15,
            daysBack: 30
        )
    }
    
    /// Example 9: Generate data for all object types (comprehensive test)
    static func example9_AllObjectTypes() -> [DetectedObject] {
        return MockDataGenerator.shared.generateAllObjectTypes()
    }
    
    // MARK: - Integration Testing Examples
    
    /// Example 10: Test data export functionality
    static func example10_ExportTest() -> [MeasurementRecord] {
        // Generate diverse records for export testing
        let records = MockDataGenerator.shared.generateMockMeasurementRecords(count: 10)
        
        print("Export Test Data:")
        print("- Total records: \(records.count)")
        print("- Total objects: \(records.flatMap { $0.detectedObjects }.count)")
        
        return records
    }
    
    /// Example 11: Test specific object type combinations
    static func example11_CustomObjectCombination() -> MeasurementRecord {
        let objectTypes: [ObjectType] = [.phone, .pen, .creditCard]
        return MockDataGenerator.shared.generateMeasurementRecord(withObjectTypes: objectTypes)
    }
    
    /// Example 12: Stress test with many objects
    static func example12_StressTest() -> [MeasurementRecord] {
        var records: [MeasurementRecord] = []
        
        // Generate 50 records with varying object counts
        for i in 1...50 {
            let objectCount = (i % 4) + 1 // 1-4 objects per record
            let record = MockDataGenerator.shared.generateMockMeasurementRecord(
                withObjects: objectCount,
                includeReferenceObject: i % 2 == 0
            )
            records.append(record)
        }
        
        print("Stress Test:")
        print("- Total records: \(records.count)")
        print("- Average objects per record: \(Double(records.flatMap { $0.detectedObjects }.count) / Double(records.count))")
        
        return records
    }
}

// MARK: - Quick Test Helper

extension MockDataExamples {
    
    /// Run all examples and print results
    static func runAllExamples() {
        print("=== Mock Data Generator Examples ===\n")
        
        print("Example 1: Single Object")
        let obj1 = example1_SingleObject()
        print("Generated: \(obj1.objectType.displayName)\n")
        
        print("Example 2: Multiple Objects")
        let objs2 = example2_MultipleObjects()
        print("Generated \(objs2.count) objects\n")
        
        print("Example 3: Measurement Record")
        let record3 = example3_MeasurementRecord()
        print("Record with \(record3.detectedObjects.count) objects\n")
        
        _ = example4_HighAccuracyTest()
        print("")
        
        _ = example5_LowConfidenceTest()
        print("")
        
        _ = example6_MultiObjectTest()
        print("")
        
        print("Example 7: Results View Data")
        let record7 = example7_ResultsViewData()
        print("Generated record for UI testing\n")
        
        print("Example 8: Historical Data")
        let records8 = example8_HistoricalData()
        print("Generated \(records8.count) historical records\n")
        
        print("Example 9: All Object Types")
        let objs9 = example9_AllObjectTypes()
        print("Generated \(objs9.count) different object types\n")
        
        _ = example10_ExportTest()
        print("")
        
        print("Example 11: Custom Object Combination")
        let record11 = example11_CustomObjectCombination()
        print("Generated record with custom objects\n")
        
        _ = example12_StressTest()
        print("")
        
        print("=== All Examples Completed ===")
    }
}
