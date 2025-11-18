//
//  IntegrationTestRunner.swift
//  CameraMeasurementApp
//
//  Manual test runner for integration tests
//  Use this to run integration tests without Xcode test framework
//

import Foundation
import UIKit
import ARKit
import SceneKit
import CoreData

/// Manual integration test runner
/// This provides a way to run integration tests programmatically
class IntegrationTestRunner {
    
    static let shared = IntegrationTestRunner()
    
    private init() {}
    
    /// Run all integration tests
    func runAllTests() {
        print("\n" + String(repeating: "=", count: 60))
        print("🧪 CAMERA MEASUREMENT SYSTEM - INTEGRATION TESTS")
        print(String(repeating: "=", count: 60) + "\n")
        
        var passedTests = 0
        var failedTests = 0
        
        // Test 1: Complete Measurement Workflow
        if testCompleteMeasurementWorkflow() {
            passedTests += 1
        } else {
            failedTests += 1
        }
        
        // Test 2: Detector-Confidence Integration
        if testDetectorConfidenceIntegration() {
            passedTests += 1
        } else {
            failedTests += 1
        }
        
        // Test 3: Calculator-Calibration Integration
        if testCalculatorCalibrationIntegration() {
            passedTests += 1
        } else {
            failedTests += 1
        }
        
        // Test 4: DataManager CRUD Operations
        if testDataManagerCRUD() {
            passedTests += 1
        } else {
            failedTests += 1
        }
        
        // Test 5: Export-Data Integration
        if testExportDataIntegration() {
            passedTests += 1
        } else {
            failedTests += 1
        }
        
        // Test 6: Complete User Flow
        if testCompleteUserFlow() {
            passedTests += 1
        } else {
            failedTests += 1
        }
        
        // Test 7: Error Handling
        if testErrorHandling() {
            passedTests += 1
        } else {
            failedTests += 1
        }
        
        // Test 8: Mock Data Generator
        if testMockDataGenerator() {
            passedTests += 1
        } else {
            failedTests += 1
        }
        
        // Print summary
        print("\n" + String(repeating: "=", count: 60))
        print("📊 TEST SUMMARY")
        print(String(repeating: "=", count: 60))
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("📈 Total: \(passedTests + failedTests)")
        print("🎯 Success Rate: \(String(format: "%.1f", Double(passedTests) / Double(passedTests + failedTests) * 100))%")
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    // MARK: - Individual Test Methods
    
    private func testCompleteMeasurementWorkflow() -> Bool {
        print("\n🧪 Test 1: Complete Measurement Workflow")
        print(String(repeating: "-", count: 60))
        
        do {
            let testImage = createTestImage()
            let detector = ObjectDetector()
            let calculator = MeasurementCalculator()
            let dataManager = DataManager.shared
            
            // Create mock detected object
            let mockObject = DetectedObject(
                boundingBox: CGRect(x: 500, y: 300, width: 400, height: 600),
                objectType: .phone,
                confidence: 0.85,
                worldPosition: SCNVector3(0, 0, -1),
                dimensions: ObjectDimensions(
                    length: 14.7,
                    width: 7.1,
                    height: 0.8,
                    accuracy: 0.85,
                    measurementDate: Date()
                )
            )
            
            let record = MeasurementRecord(
                id: UUID(),
                image: testImage,
                detectedObjects: [mockObject],
                referenceObject: ReferenceObject.defaultObjects.first,
                timestamp: Date(),
                location: nil
            )
            
            let savedId = try dataManager.saveMeasurementRecord(record)
            let retrieved = try dataManager.fetchRecord(byId: savedId)
            
            assert(retrieved.id == record.id, "Record ID mismatch")
            assert(retrieved.detectedObjects.count == 1, "Object count mismatch")
            
            try dataManager.deleteRecord(byId: savedId)
            
            print("✅ Test 1 PASSED")
            return true
            
        } catch {
            print("❌ Test 1 FAILED: \(error)")
            return false
        }
    }
    
    private func testDetectorConfidenceIntegration() -> Bool {
        print("\n🧪 Test 2: Detector-Confidence Integration")
        print(String(repeating: "-", count: 60))
        
        do {
            let detector = ObjectDetector()
            let testImage = createTestImage()
            
            let testObjects = [
                DetectedObject(
                    boundingBox: CGRect(x: 100, y: 100, width: 300, height: 400),
                    objectType: .phone,
                    confidence: 0.90,
                    worldPosition: SCNVector3(0, 0, -1)
                ),
                DetectedObject(
                    boundingBox: CGRect(x: 500, y: 500, width: 200, height: 200),
                    objectType: .cup,
                    confidence: 0.45,
                    worldPosition: SCNVector3(0.5, 0, -1.5)
                )
            ]
            
            for object in testObjects {
                let evaluation = detector.evaluateConfidence(
                    for: object,
                    imageSize: testImage.size,
                    context: testObjects
                )
                
                assert(evaluation.score >= 0.0 && evaluation.score <= 1.0, "Invalid confidence score")
            }
            
            let reliableObjects = detector.getReliableDetections(from: testObjects)
            assert(reliableObjects.count <= testObjects.count, "Invalid filtering")
            
            print("✅ Test 2 PASSED")
            return true
            
        } catch {
            print("❌ Test 2 FAILED: \(error)")
            return false
        }
    }
    
    private func testCalculatorCalibrationIntegration() -> Bool {
        print("\n🧪 Test 3: Calculator-Calibration Integration")
        print(String(repeating: "-", count: 60))
        
        do {
            let calculator = MeasurementCalculator()
            let calibrationManager = CalibrationManager.shared
            
            calculator.resetCalibration()
            
            let referenceObject = ReferenceObject.defaultObjects.first { $0.name == "信用卡" }!
            
            let measuredDimensions = ObjectDimensions(
                length: 8.6,
                width: 5.5,
                height: 0.1,
                accuracy: 0.80,
                measurementDate: Date()
            )
            
            let calibratedDimensions = calibrationManager.applyCalibration(to: measuredDimensions)
            
            let error = calculator.calculateDetailedError(
                measured: calibratedDimensions,
                actual: referenceObject.standardDimensions
            )
            
            assert(error.averageErrorPercent < 20.0, "Error too high")
            
            print("✅ Test 3 PASSED")
            return true
            
        } catch {
            print("❌ Test 3 FAILED: \(error)")
            return false
        }
    }
    
    private func testDataManagerCRUD() -> Bool {
        print("\n🧪 Test 4: DataManager CRUD Operations")
        print(String(repeating: "-", count: 60))
        
        do {
            let dataManager = DataManager.shared
            let testImage = createTestImage()
            
            let record = MeasurementRecord(
                id: UUID(),
                image: testImage,
                detectedObjects: [],
                referenceObject: nil,
                timestamp: Date(),
                location: nil
            )
            
            // Create
            let savedId = try dataManager.saveMeasurementRecord(record)
            
            // Read
            let retrieved = try dataManager.fetchRecord(byId: savedId)
            assert(retrieved.id == savedId, "ID mismatch")
            
            // Update
            try dataManager.updateRecordNotes(id: savedId, notes: "Test note")
            let updated = try dataManager.fetchRecord(byId: savedId)
            
            // Delete
            try dataManager.deleteRecord(byId: savedId)
            
            print("✅ Test 4 PASSED")
            return true
            
        } catch {
            print("❌ Test 4 FAILED: \(error)")
            return false
        }
    }
    
    private func testExportDataIntegration() -> Bool {
        print("\n🧪 Test 5: Export-Data Integration")
        print(String(repeating: "-", count: 60))
        
        do {
            let dataManager = DataManager.shared
            let exportManager = ExportManager.shared
            let testImage = createTestImage()
            
            let record = MeasurementRecord(
                id: UUID(),
                image: testImage,
                detectedObjects: [],
                referenceObject: nil,
                timestamp: Date(),
                location: nil
            )
            
            let savedId = try dataManager.saveMeasurementRecord(record)
            
            let records = try dataManager.fetchAllRecords()
            let csvData = try exportManager.exportToCSV(records: records)
            
            assert(csvData.count > 0, "CSV data empty")
            
            let annotatedImage = try exportManager.createAnnotatedImage(from: record)
            assert(annotatedImage.size.width > 0, "Annotated image creation failed")
            
            try dataManager.deleteRecord(byId: savedId)
            
            print("✅ Test 5 PASSED")
            return true
            
        } catch {
            print("❌ Test 5 FAILED: \(error)")
            return false
        }
    }
    
    private func testCompleteUserFlow() -> Bool {
        print("\n🧪 Test 6: Complete User Flow")
        print(String(repeating: "-", count: 60))
        
        do {
            let testImage = createTestImage()
            let detector = ObjectDetector()
            let dataManager = DataManager.shared
            let exportManager = ExportManager.shared
            
            let mockObject = DetectedObject(
                boundingBox: CGRect(x: 500, y: 300, width: 400, height: 600),
                objectType: .phone,
                confidence: 0.85,
                worldPosition: SCNVector3(0, 0, -1),
                dimensions: ObjectDimensions(
                    length: 14.7,
                    width: 7.1,
                    height: 0.8,
                    accuracy: 0.85,
                    measurementDate: Date()
                )
            )
            
            let record = MeasurementRecord(
                id: UUID(),
                image: testImage,
                detectedObjects: [mockObject],
                referenceObject: ReferenceObject.defaultObjects.first,
                timestamp: Date(),
                location: nil
            )
            
            let savedId = try dataManager.saveMeasurementRecord(record)
            _ = try dataManager.fetchRecentRecords(limit: 5)
            _ = try exportManager.exportToCSV(records: [record])
            
            try dataManager.deleteRecord(byId: savedId)
            
            print("✅ Test 6 PASSED")
            return true
            
        } catch {
            print("❌ Test 6 FAILED: \(error)")
            return false
        }
    }
    
    private func testErrorHandling() -> Bool {
        print("\n🧪 Test 7: Error Handling")
        print(String(repeating: "-", count: 60))
        
        let dataManager = DataManager.shared
        
        // Test non-existent record fetch
        do {
            _ = try dataManager.fetchRecord(byId: UUID())
            print("❌ Test 7 FAILED: Should have thrown error")
            return false
        } catch {
            // Expected error
        }
        
        // Test non-existent record deletion
        do {
            try dataManager.deleteRecord(byId: UUID())
            print("❌ Test 7 FAILED: Should have thrown error")
            return false
        } catch {
            // Expected error
        }
        
        print("✅ Test 7 PASSED")
        return true
    }
    
    private func testMockDataGenerator() -> Bool {
        print("\n🧪 Test 8: Mock Data Generator")
        print(String(repeating: "-", count: 60))
        
        do {
            let mockGen = MockDataGenerator.shared
            
            // Test single object generation
            let singleObject = mockGen.generateMockDetectedObject(
                objectType: .phone,
                confidence: 0.85,
                withDimensions: true
            )
            assert(singleObject.objectType == .phone, "Object type mismatch")
            assert(singleObject.confidence == 0.85, "Confidence mismatch")
            assert(singleObject.dimensions != nil, "Dimensions should exist")
            
            // Test multiple objects generation
            let multipleObjects = mockGen.generateMockDetectedObjects(count: 5)
            assert(multipleObjects.count == 5, "Object count mismatch")
            
            // Test measurement record generation
            let record = mockGen.generateMockMeasurementRecord(
                withObjects: 3,
                includeReferenceObject: true
            )
            assert(record.detectedObjects.count == 3, "Object count mismatch")
            assert(record.referenceObject != nil, "Reference object should exist")
            
            // Test preset scenarios
            let highAccuracy = mockGen.generateHighAccuracyScenario()
            assert(highAccuracy.averageAccuracy >= 0.9, "High accuracy scenario failed")
            
            let lowConfidence = mockGen.generateLowConfidenceScenario()
            assert(lowConfidence.detectedObjects.first?.confidence ?? 1.0 < 0.5, "Low confidence scenario failed")
            
            let multiObject = mockGen.generateMultiObjectScenario()
            assert(multiObject.detectedObjects.count >= 3, "Multi-object scenario failed")
            
            // Test historical records
            let historicalRecords = mockGen.generateHistoricalRecords(count: 10, daysBack: 30)
            assert(historicalRecords.count == 10, "Historical records count mismatch")
            
            // Test all object types
            let allTypes = mockGen.generateAllObjectTypes()
            assert(allTypes.count > 0, "All object types generation failed")
            
            print("  ✓ Single object generation: OK")
            print("  ✓ Multiple objects generation: OK")
            print("  ✓ Measurement record generation: OK")
            print("  ✓ High accuracy scenario: OK")
            print("  ✓ Low confidence scenario: OK")
            print("  ✓ Multi-object scenario: OK")
            print("  ✓ Historical records: OK")
            print("  ✓ All object types: OK")
            
            print("✅ Test 8 PASSED")
            return true
            
        } catch {
            print("❌ Test 8 FAILED: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 1920, height: 1080)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(x: 500, y: 300, width: 400, height: 600))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}
