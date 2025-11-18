//
//  MockDataGenerator.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//  Purpose: Generate mock measurement data for UI and integration testing
//

import Foundation
import UIKit
import SceneKit
import CoreLocation

/// Mock data generator for testing purposes
class MockDataGenerator {
    
    // MARK: - Singleton
    static let shared = MockDataGenerator()
    
    private init() {}
    
    // MARK: - Mock DetectedObject Generation
    
    /// Generate a single mock detected object
    func generateMockDetectedObject(
        objectType: ObjectType = .phone,
        confidence: Float = 0.85,
        withDimensions: Bool = true
    ) -> DetectedObject {
        let boundingBox = generateRandomBoundingBox()
        let worldPosition = generateRandomWorldPosition()
        let dimensions = withDimensions ? generateMockDimensions(for: objectType) : nil
        
        return DetectedObject(
            id: UUID(),
            boundingBox: boundingBox,
            objectType: objectType,
            confidence: confidence,
            worldPosition: worldPosition,
            dimensions: dimensions
        )
    }
    
    /// Generate multiple mock detected objects
    func generateMockDetectedObjects(count: Int = 3) -> [DetectedObject] {
        let objectTypes: [ObjectType] = [.phone, .book, .cup, .pen, .bottle]
        var objects: [DetectedObject] = []
        
        for i in 0..<count {
            let objectType = objectTypes[i % objectTypes.count]
            let confidence = Float.random(in: 0.7...0.95)
            objects.append(generateMockDetectedObject(
                objectType: objectType,
                confidence: confidence,
                withDimensions: true
            ))
        }
        
        return objects
    }
    
    // MARK: - Mock ObjectDimensions Generation
    
    /// Generate mock dimensions for a specific object type
    func generateMockDimensions(for objectType: ObjectType) -> ObjectDimensions {
        let (length, width, height) = getStandardDimensions(for: objectType)
        let accuracy = Float.random(in: 0.80...0.95)
        
        // Add slight variation to simulate real measurements
        let variation: Float = 0.1
        let variedLength = length * Float.random(in: (1.0 - variation)...(1.0 + variation))
        let variedWidth = width * Float.random(in: (1.0 - variation)...(1.0 + variation))
        let variedHeight = height * Float.random(in: (1.0 - variation)...(1.0 + variation))
        
        return ObjectDimensions(
            length: variedLength,
            width: variedWidth,
            height: variedHeight,
            accuracy: accuracy,
            measurementDate: Date()
        )
    }
    
    /// Get standard dimensions for object types
    private func getStandardDimensions(for objectType: ObjectType) -> (Float, Float, Float) {
        switch objectType {
        case .phone: return (14.7, 7.1, 0.8)
        case .laptop: return (30.0, 21.0, 1.5)
        case .tablet: return (24.0, 17.0, 0.7)
        case .book: return (21.0, 14.8, 2.0)
        case .bottle: return (20.0, 6.5, 6.5)
        case .cup: return (10.0, 8.0, 8.0)
        case .pen: return (14.0, 1.0, 1.0)
        case .lighter: return (7.5, 2.5, 1.2)
        case .creditCard: return (8.5, 5.4, 0.08)
        case .coin: return (2.4, 2.4, 0.2)
        case .box: return (15.0, 10.0, 8.0)
        case .key: return (5.0, 2.0, 0.3)
        default: return (10.0, 10.0, 10.0)
        }
    }
    
    // MARK: - Mock MeasurementRecord Generation
    
    /// Generate a single mock measurement record
    func generateMockMeasurementRecord(
        withObjects count: Int = 2,
        includeReferenceObject: Bool = true
    ) -> MeasurementRecord {
        let image = generateMockImage()
        let detectedObjects = generateMockDetectedObjects(count: count)
        let referenceObject = includeReferenceObject ? ReferenceObject.defaultObjects.randomElement() : nil
        let location = generateMockLocation()
        
        return MeasurementRecord(
            id: UUID(),
            image: image,
            detectedObjects: detectedObjects,
            referenceObject: referenceObject,
            timestamp: Date(),
            location: location
        )
    }
    
    /// Generate multiple mock measurement records
    func generateMockMeasurementRecords(count: Int = 5) -> [MeasurementRecord] {
        var records: [MeasurementRecord] = []
        
        for i in 0..<count {
            let objectCount = Int.random(in: 1...4)
            let includeReference = i % 2 == 0 // Alternate with/without reference
            let record = generateMockMeasurementRecord(
                withObjects: objectCount,
                includeReferenceObject: includeReference
            )
            records.append(record)
        }
        
        return records
    }
    
    // MARK: - Helper Methods
    
    /// Generate a random bounding box
    private func generateRandomBoundingBox() -> CGRect {
        let x = CGFloat.random(in: 0.1...0.7)
        let y = CGFloat.random(in: 0.1...0.7)
        let width = CGFloat.random(in: 0.1...0.3)
        let height = CGFloat.random(in: 0.1...0.3)
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// Generate a random world position
    private func generateRandomWorldPosition() -> SCNVector3 {
        let x = Float.random(in: -0.5...0.5)
        let y = Float.random(in: -0.3...0.3)
        let z = Float.random(in: -1.0...(-0.3))
        
        return SCNVector3(x: x, y: y, z: z)
    }
    
    /// Generate a mock image for testing
    private func generateMockImage() -> UIImage {
        let size = CGSize(width: 1920, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Create a gradient background
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0.0, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient,
                                                start: CGPoint(x: 0, y: 0),
                                                end: CGPoint(x: size.width, y: size.height),
                                                options: [])
            
            // Add some text to simulate a captured scene
            let text = "Mock Measurement Scene"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return image
    }
    
    /// Generate a mock location
    private func generateMockLocation() -> CLLocation {
        // Mock location in Taipei, Taiwan
        let latitude = 25.0330 + Double.random(in: -0.01...0.01)
        let longitude = 121.5654 + Double.random(in: -0.01...0.01)
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Preset Mock Scenarios
    
    /// Generate a high-accuracy measurement scenario
    func generateHighAccuracyScenario() -> MeasurementRecord {
        let phone = DetectedObject(
            id: UUID(),
            boundingBox: CGRect(x: 0.3, y: 0.4, width: 0.4, height: 0.2),
            objectType: .phone,
            confidence: 0.95,
            worldPosition: SCNVector3(0, 0, -0.5),
            dimensions: ObjectDimensions(length: 14.7, width: 7.1, height: 0.8, accuracy: 0.95)
        )
        
        return MeasurementRecord(
            image: generateMockImage(),
            detectedObjects: [phone],
            referenceObject: ReferenceObject.creditCard,
            timestamp: Date()
        )
    }
    
    /// Generate a low-confidence detection scenario
    func generateLowConfidenceScenario() -> MeasurementRecord {
        let unknownObject = DetectedObject(
            id: UUID(),
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.3, height: 0.3),
            objectType: .unknown,
            confidence: 0.45,
            worldPosition: SCNVector3(0.1, -0.1, -0.8),
            dimensions: ObjectDimensions(length: 12.0, width: 8.0, height: 5.0, accuracy: 0.60)
        )
        
        return MeasurementRecord(
            image: generateMockImage(),
            detectedObjects: [unknownObject],
            referenceObject: nil,
            timestamp: Date()
        )
    }
    
    /// Generate a multi-object scenario
    func generateMultiObjectScenario() -> MeasurementRecord {
        let objects = [
            DetectedObject(
                id: UUID(),
                boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.2),
                objectType: .phone,
                confidence: 0.88,
                worldPosition: SCNVector3(-0.2, 0, -0.6),
                dimensions: ObjectDimensions(length: 14.5, width: 7.0, height: 0.8, accuracy: 0.87)
            ),
            DetectedObject(
                id: UUID(),
                boundingBox: CGRect(x: 0.5, y: 0.3, width: 0.2, height: 0.3),
                objectType: .cup,
                confidence: 0.82,
                worldPosition: SCNVector3(0.3, 0, -0.7),
                dimensions: ObjectDimensions(length: 10.2, width: 8.1, height: 8.0, accuracy: 0.80)
            ),
            DetectedObject(
                id: UUID(),
                boundingBox: CGRect(x: 0.3, y: 0.6, width: 0.15, height: 0.1),
                objectType: .pen,
                confidence: 0.91,
                worldPosition: SCNVector3(0, -0.2, -0.5),
                dimensions: ObjectDimensions(length: 14.1, width: 1.0, height: 1.0, accuracy: 0.89)
            )
        ]
        
        return MeasurementRecord(
            image: generateMockImage(),
            detectedObjects: objects,
            referenceObject: ReferenceObject.lighter,
            timestamp: Date()
        )
    }
}

// MARK: - Convenience Extensions for Testing

extension MockDataGenerator {
    
    /// Generate mock data for all supported object types
    func generateAllObjectTypes() -> [DetectedObject] {
        return ObjectType.allCases.filter { $0 != .unknown }.map { objectType in
            generateMockDetectedObject(objectType: objectType, confidence: 0.85, withDimensions: true)
        }
    }
    
    /// Generate a measurement record with specific object types
    func generateMeasurementRecord(withObjectTypes types: [ObjectType]) -> MeasurementRecord {
        let objects = types.map { objectType in
            generateMockDetectedObject(objectType: objectType, confidence: Float.random(in: 0.75...0.95), withDimensions: true)
        }
        
        return MeasurementRecord(
            image: generateMockImage(),
            detectedObjects: objects,
            referenceObject: ReferenceObject.defaultObjects.randomElement(),
            timestamp: Date()
        )
    }
    
    /// Generate historical measurement records with timestamps spread over days
    func generateHistoricalRecords(count: Int = 10, daysBack: Int = 30) -> [MeasurementRecord] {
        var records: [MeasurementRecord] = []
        
        for i in 0..<count {
            let daysAgo = Double.random(in: 0...Double(daysBack))
            let timestamp = Date().addingTimeInterval(-daysAgo * 24 * 60 * 60)
            
            let objectCount = Int.random(in: 1...3)
            let objects = generateMockDetectedObjects(count: objectCount)
            
            let record = MeasurementRecord(
                id: UUID(),
                image: generateMockImage(),
                detectedObjects: objects,
                referenceObject: i % 3 == 0 ? ReferenceObject.defaultObjects.randomElement() : nil,
                timestamp: timestamp,
                location: generateMockLocation()
            )
            
            records.append(record)
        }
        
        return records.sorted { $0.timestamp > $1.timestamp }
    }
}
