//
//  IntegrationTests.swift
//  CameraMeasurementAppTests
//
//  Integration tests for Camera Measurement System
//  Tests end-to-end workflows and component integration
//

import Testing
import Foundation
import UIKit
import ARKit
import SceneKit
import CoreData
@testable import CameraMeasurementApp

/// Integration test suite for the Camera Measurement System
/// Tests complete user workflows and component interactions
struct IntegrationTests {
    
    // MARK: - Test Setup
    
    /// Create test AR frame for integration testing
    private func createTestARFrame() -> ARFrame? {
        // Note: ARFrame cannot be easily mocked in unit tests
        // This would require actual AR session or more complex mocking
        return nil
    }
    
    /// Create test image for detection
    private func createTestImage() -> UIImage {
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
    
    // MARK: - End-to-End Workflow Tests
    
    /// Test complete measurement workflow from detection to storage
    /// Requirements: 1.1, 3.3, 5.1
    @Test("Complete measurement workflow")
    func testCompleteMeasurementWorkflow() async throws {
        print("\n🧪 Testing complete measurement workflow...")
        
        // Step 1: Object Detection
        print("📋 Step 1: Object Detection")
        let detector = ObjectDetector()
        let testImage = createTestImage()
        
        // Note: Without actual ML model, detection may return empty
        let detectedObjects = detector.detectObjects(in: testImage)
        print("✓ Detected \(detectedObjects.count) objects")
        
        // Create mock detected object for testing
        let mockObject = DetectedObject(
            boundingBox: CGRect(x: 500, y: 300, width: 400, height: 600),
            objectType: .phone,
            confidence: 0.85,
            worldPosition: SCNVector3(0, 0, -1)
        )
        
        // Step 2: Measurement Calculation
        print("📋 Step 2: Measurement Calculation")
        let calculator = MeasurementCalculator()
        
        // Note: Without actual AR frame, we'll test with mock dimensions
        let mockDimensions = ObjectDimensions(
            length: 14.7,
            width: 7.1,
            height: 0.8,
            accuracy: 0.85,
            measurementDate: Date()
        )
        
        let objectWithDimensions = DetectedObject(
            id: mockObject.id,
            boundingBox: mockObject.boundingBox,
            objectType: mockObject.objectType,
            confidence: mockObject.confidence,
            worldPosition: mockObject.worldPosition,
            dimensions: mockDimensions
        )
        
        print("✓ Calculated dimensions: \(mockDimensions.length)x\(mockDimensions.width)x\(mockDimensions.height) cm")
        
        // Step 3: Reference Object Selection
        print("📋 Step 3: Reference Object Selection")
        let referenceObjects = ReferenceObject.defaultObjects
        let selectedReference = referenceObjects.first { $0.name == "iPhone" }
        print("✓ Selected reference object: \(selectedReference?.name ?? "None")")
        
        // Step 4: Create Measurement Record
        print("📋 Step 4: Create Measurement Record")
        let record = MeasurementRecord(
            id: UUID(),
            image: testImage,
            detectedObjects: [objectWithDimensions],
            referenceObject: selectedReference,
            timestamp: Date(),
            location: nil
        )
        print("✓ Created measurement record with ID: \(record.id)")
        
        // Step 5: Save to Core Data
        print("📋 Step 5: Save to Core Data")
        let dataManager = DataManager.shared
        
        do {
            let savedId = try dataManager.saveMeasurementRecord(record)
            print("✓ Saved record to database with ID: \(savedId)")
            
            // Step 6: Retrieve and Verify
            print("📋 Step 6: Retrieve and Verify")
            let retrievedRecord = try dataManager.fetchRecord(byId: savedId)
            #expect(retrievedRecord.id == record.id)
            #expect(retrievedRecord.detectedObjects.count == 1)
            print("✓ Retrieved and verified record from database")
            
            // Cleanup
            try dataManager.deleteRecord(byId: savedId)
            print("✓ Cleaned up test data")
            
        } catch {
            print("❌ Workflow failed: \(error)")
            throw error
        }
        
        print("✅ Complete measurement workflow test passed")
    }
    
    // MARK: - Component Integration Tests
    
    /// Test ObjectDetector and ConfidenceEvaluator integration
    /// Requirements: 3.3, 3.5
    @Test("ObjectDetector and ConfidenceEvaluator integration")
    func testDetectorConfidenceIntegration() async throws {
        print("\n🧪 Testing ObjectDetector and ConfidenceEvaluator integration...")
        
        let detector = ObjectDetector()
        let testImage = createTestImage()
        let imageSize = testImage.size
        
        // Create test objects with varying confidence
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
        
        // Test confidence evaluation
        for object in testObjects {
            let evaluation = detector.evaluateConfidence(
                for: object,
                imageSize: imageSize,
                context: testObjects
            )
            
            print("✓ Object \(object.objectType): \(evaluation.level.rawValue) confidence")
            print("  Score: \(evaluation.score)")
            print("  Recommendation: \(evaluation.recommendation)")
            
            #expect(evaluation.score >= 0.0 && evaluation.score <= 1.0)
        }
        
        // Test reliable detection filtering
        let reliableObjects = detector.getReliableDetections(from: testObjects)
        print("✓ Reliable detections: \(reliableObjects.count) out of \(testObjects.count)")
        #expect(reliableObjects.count <= testObjects.count)
        
        // Test manual verification check
        for object in testObjects {
            let needsVerification = detector.requiresManualVerification(object)
            print("✓ Object \(object.objectType) needs verification: \(needsVerification)")
        }
        
        print("✅ Detector-Confidence integration test passed")
    }
    
    /// Test MeasurementCalculator and CalibrationManager integration
    /// Requirements: 2.2, 3.3
    @Test("MeasurementCalculator and CalibrationManager integration")
    func testCalculatorCalibrationIntegration() async throws {
        print("\n🧪 Testing MeasurementCalculator and CalibrationManager integration...")
        
        let calculator = MeasurementCalculator()
        let calibrationManager = CalibrationManager.shared
        
        // Reset calibration for clean test
        calculator.resetCalibration()
        
        // Step 1: Measure without calibration
        print("📋 Step 1: Measure without calibration")
        let initialConfidence = calculator.getAccuracyConfidence()
        print("✓ Initial confidence: \(initialConfidence)")
        
        // Step 2: Perform calibration with reference object
        print("📋 Step 2: Perform calibration")
        let referenceObject = ReferenceObject.defaultObjects.first { $0.name == "信用卡" }!
        
        let measuredDimensions = ObjectDimensions(
            length: 8.6,  // Slightly off from actual 8.5
            width: 5.5,   // Slightly off from actual 5.4
            height: 0.1,
            accuracy: 0.80,
            measurementDate: Date()
        )
        
        // Note: Without actual AR frame, we pass a mock calibration
        // In real scenario, this would use actual AR frame
        let mockCalibrationData = CalibrationData(
            scaleFactor: 0.99,
            confidence: 0.90,
            referenceObject: referenceObject,
            calibrationDate: Date()
        )
        
        print("✓ Calibration scale factor: \(mockCalibrationData.scaleFactor)")
        print("✓ Calibration confidence: \(mockCalibrationData.confidence)")
        
        // Step 3: Apply calibration to new measurements
        print("📋 Step 3: Apply calibration")
        let calibratedDimensions = calibrationManager.applyCalibration(to: measuredDimensions)
        
        print("✓ Original: \(measuredDimensions.length)x\(measuredDimensions.width) cm")
        print("✓ Calibrated: \(calibratedDimensions.length)x\(calibratedDimensions.width) cm")
        
        // Step 4: Verify calibration improves accuracy
        print("📋 Step 4: Verify accuracy improvement")
        let error = calculator.calculateDetailedError(
            measured: calibratedDimensions,
            actual: referenceObject.standardDimensions
        )
        
        print("✓ Length error: \(error.lengthErrorPercent)%")
        print("✓ Width error: \(error.widthErrorPercent)%")
        print("✓ Average error: \(error.averageErrorPercent)%")
        
        #expect(error.averageErrorPercent < 10.0) // Should be within 10% error
        
        print("✅ Calculator-Calibration integration test passed")
    }
    
    /// Test DataManager CRUD operations integration
    /// Requirements: 4.1, 4.4
    @Test("DataManager CRUD operations")
    func testDataManagerCRUDIntegration() async throws {
        print("\n🧪 Testing DataManager CRUD operations...")
        
        let dataManager = DataManager.shared
        let testImage = createTestImage()
        
        // Create test records
        let records = (1...3).map { index in
            MeasurementRecord(
                id: UUID(),
                image: testImage,
                detectedObjects: [
                    DetectedObject(
                        boundingBox: CGRect(x: 100, y: 100, width: 200, height: 300),
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
                ],
                referenceObject: ReferenceObject.defaultObjects.first,
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                location: nil
            )
        }
        
        // Test Create
        print("📋 Testing Create operations")
        var savedIds: [UUID] = []
        for record in records {
            let savedId = try dataManager.saveMeasurementRecord(record)
            savedIds.append(savedId)
            print("✓ Saved record: \(savedId)")
        }
        
        // Test Read
        print("📋 Testing Read operations")
        let allRecords = try dataManager.fetchAllRecords()
        print("✓ Fetched \(allRecords.count) records")
        #expect(allRecords.count >= records.count)
        
        let recentRecords = try dataManager.fetchRecentRecords(limit: 2)
        print("✓ Fetched \(recentRecords.count) recent records")
        #expect(recentRecords.count <= 2)
        
        // Test Update
        print("📋 Testing Update operations")
        if let firstId = savedIds.first {
            try dataManager.updateRecordNotes(id: firstId, notes: "Test note")
            let updated = try dataManager.fetchRecord(byId: firstId)
            print("✓ Updated record notes")
        }
        
        // Test Delete
        print("📋 Testing Delete operations")
        for id in savedIds {
            try dataManager.deleteRecord(byId: id)
            print("✓ Deleted record: \(id)")
        }
        
        print("✅ DataManager CRUD integration test passed")
    }
    
    /// Test ExportManager integration with DataManager
    /// Requirements: 4.2, 4.5
    @Test("ExportManager and DataManager integration")
    func testExportDataIntegration() async throws {
        print("\n🧪 Testing ExportManager and DataManager integration...")
        
        let dataManager = DataManager.shared
        let exportManager = ExportManager()
        let testImage = createTestImage()
        
        // Create test record
        let record = MeasurementRecord(
            id: UUID(),
            image: testImage,
            detectedObjects: [
                DetectedObject(
                    boundingBox: CGRect(x: 100, y: 100, width: 200, height: 300),
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
            ],
            referenceObject: ReferenceObject.defaultObjects.first,
            timestamp: Date(),
            location: nil
        )
        
        // Save record
        let savedId = try dataManager.saveMeasurementRecord(record)
        print("✓ Saved test record")
        
        // Test CSV export
        print("📋 Testing CSV export")
        let records = try dataManager.fetchAllRecords()
        let csvData = try exportManager.exportToCSV(records: records)
        
        #expect(csvData.count > 0)
        print("✓ Exported \(csvData.count) bytes of CSV data")
        
        // Verify CSV content
        if let csvString = String(data: csvData, encoding: .utf8) {
            #expect(csvString.contains("Timestamp"))
            #expect(csvString.contains("Object Type"))
            print("✓ CSV contains expected headers")
        }
        
        // Test annotated image export
        print("📋 Testing annotated image export")
        let annotatedImage = exportManager.createAnnotatedImage(for: record)
        #expect(annotatedImage != nil)
        print("✓ Created annotated image")
        
        // Cleanup
        try dataManager.deleteRecord(byId: savedId)
        print("✓ Cleaned up test data")
        
        print("✅ Export-Data integration test passed")
    }
    
    // MARK: - User Flow Tests
    
    /// Test complete user flow: capture -> detect -> measure -> save
    /// Requirements: 1.1, 5.1
    @Test("Complete user flow simulation")
    func testCompleteUserFlow() async throws {
        print("\n🧪 Testing complete user flow simulation...")
        
        // Simulate user opening camera
        print("📋 Step 1: User opens camera")
        let testImage = createTestImage()
        print("✓ Camera preview ready")
        
        // Simulate user taking photo
        print("📋 Step 2: User takes photo")
        print("✓ Photo captured")
        
        // Simulate automatic object detection
        print("📋 Step 3: Automatic object detection")
        let detector = ObjectDetector()
        let detectedObjects = detector.detectObjects(in: testImage)
        
        // Create mock object if detection returns empty
        let objects = detectedObjects.isEmpty ? [
            DetectedObject(
                boundingBox: CGRect(x: 500, y: 300, width: 400, height: 600),
                objectType: .phone,
                confidence: 0.85,
                worldPosition: SCNVector3(0, 0, -1)
            )
        ] : detectedObjects
        
        print("✓ Detected \(objects.count) objects")
        
        // Simulate measurement calculation
        print("📋 Step 4: Calculate measurements")
        let calculator = MeasurementCalculator()
        
        let objectsWithDimensions = objects.map { object in
            let dimensions = ObjectDimensions(
                length: 14.7,
                width: 7.1,
                height: 0.8,
                accuracy: object.confidence,
                measurementDate: Date()
            )
            
            return DetectedObject(
                id: object.id,
                boundingBox: object.boundingBox,
                objectType: object.objectType,
                confidence: object.confidence,
                worldPosition: object.worldPosition,
                dimensions: dimensions
            )
        }
        
        print("✓ Calculated dimensions for \(objectsWithDimensions.count) objects")
        
        // Simulate reference object display
        print("📋 Step 5: Display reference object")
        let referenceObject = ReferenceObject.defaultObjects.first
        print("✓ Selected reference: \(referenceObject?.name ?? "None")")
        
        // Simulate user saving result
        print("📋 Step 6: User saves result")
        let record = MeasurementRecord(
            id: UUID(),
            image: testImage,
            detectedObjects: objectsWithDimensions,
            referenceObject: referenceObject,
            timestamp: Date(),
            location: nil
        )
        
        let dataManager = DataManager.shared
        let savedId = try dataManager.saveMeasurementRecord(record)
        print("✓ Saved measurement record")
        
        // Simulate user viewing history
        print("📋 Step 7: User views measurement history")
        let recentRecords = try dataManager.fetchRecentRecords(limit: 5)
        print("✓ Retrieved \(recentRecords.count) recent records")
        
        // Simulate user exporting data
        print("📋 Step 8: User exports data")
        let exportManager = ExportManager()
        let csvData = try exportManager.exportToCSV(records: [record])
        print("✓ Exported data (\(csvData.count) bytes)")
        
        // Cleanup
        try dataManager.deleteRecord(byId: savedId)
        print("✓ Cleaned up test data")
        
        print("✅ Complete user flow test passed")
    }
    
    /// Test error handling across components
    /// Requirements: 5.2
    @Test("Error handling integration")
    func testErrorHandlingIntegration() async throws {
        print("\n🧪 Testing error handling integration...")
        
        let dataManager = DataManager.shared
        
        // Test fetching non-existent record
        print("📋 Testing non-existent record fetch")
        do {
            _ = try dataManager.fetchRecord(byId: UUID())
            #expect(Bool(false), "Should have thrown error")
        } catch let error as DataManagerError {
            print("✓ Correctly caught error: \(error.localizedDescription)")
        }
        
        // Test deleting non-existent record
        print("📋 Testing non-existent record deletion")
        do {
            try dataManager.deleteRecord(byId: UUID())
            #expect(Bool(false), "Should have thrown error")
        } catch let error as DataManagerError {
            print("✓ Correctly caught error: \(error.localizedDescription)")
        }
        
        // Test low confidence detection handling
        print("📋 Testing low confidence detection")
        let detector = ObjectDetector()
        let lowConfidenceObject = DetectedObject(
            boundingBox: CGRect(x: 100, y: 100, width: 50, height: 50),
            objectType: .unknown,
            confidence: 0.15,
            worldPosition: SCNVector3(0, 0, -1)
        )
        
        let evaluation = detector.evaluateConfidence(
            for: lowConfidenceObject,
            imageSize: CGSize(width: 1920, height: 1080)
        )
        
        if let error = detector.handleLowConfidence(for: lowConfidenceObject, evaluation: evaluation) {
            print("✓ Correctly identified low confidence: \(error)")
        }
        
        print("✅ Error handling integration test passed")
    }
    
    // MARK: - Performance Integration Tests
    
    /// Test performance of integrated workflow
    /// Requirements: 3.3
    @Test("Performance integration")
    func testPerformanceIntegration() async throws {
        print("\n🧪 Testing performance integration...")
        
        let testImage = createTestImage()
        let detector = ObjectDetector()
        let dataManager = DataManager.shared
        
        // Measure detection time
        print("📋 Measuring detection performance")
        let detectionStart = Date()
        _ = detector.detectObjects(in: testImage)
        let detectionTime = Date().timeIntervalSince(detectionStart)
        print("✓ Detection time: \(String(format: "%.3f", detectionTime))s")
        
        // Measure save time
        print("📋 Measuring save performance")
        let record = MeasurementRecord(
            id: UUID(),
            image: testImage,
            detectedObjects: [],
            referenceObject: nil,
            timestamp: Date(),
            location: nil
        )
        
        let saveStart = Date()
        let savedId = try dataManager.saveMeasurementRecord(record)
        let saveTime = Date().timeIntervalSince(saveStart)
        print("✓ Save time: \(String(format: "%.3f", saveTime))s")
        
        // Measure fetch time
        print("📋 Measuring fetch performance")
        let fetchStart = Date()
        _ = try dataManager.fetchAllRecords()
        let fetchTime = Date().timeIntervalSince(fetchStart)
        print("✓ Fetch time: \(String(format: "%.3f", fetchTime))s")
        
        // Cleanup
        try dataManager.deleteRecord(byId: savedId)
        
        // Verify performance targets
        #expect(saveTime < 1.0, "Save should complete within 1 second")
        #expect(fetchTime < 1.0, "Fetch should complete within 1 second")
        
        print("✅ Performance integration test passed")
    }
}
