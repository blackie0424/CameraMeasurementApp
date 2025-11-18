//
//  ObjectClassifier.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import Vision

/// Advanced object classification system with confidence scoring and label mapping
class ObjectClassifier {
    
    // MARK: - Properties
    
    /// Minimum confidence threshold for accepting a classification
    private let minimumConfidence: Float = 0.25
    
    /// Label mapping dictionary for common variations
    private let labelMappings: [String: ObjectType] = [
        // Electronics variations
        "cell phone": .phone,
        "mobile phone": .phone,
        "smartphone": .phone,
        "iphone": .phone,
        "android phone": .phone,
        "laptop computer": .laptop,
        "notebook computer": .laptop,
        "macbook": .laptop,
        "tablet computer": .tablet,
        "ipad": .tablet,
        "computer monitor": .monitor,
        "display screen": .monitor,
        "lcd monitor": .monitor,
        "wristwatch": .watch,
        "smartwatch": .watch,
        "apple watch": .watch,
        
        // Everyday items variations
        "cigarette lighter": .lighter,
        "credit card": .creditCard,
        "debit card": .creditCard,
        "bank card": .creditCard,
        "water bottle": .bottle,
        "plastic bottle": .bottle,
        "glass bottle": .bottle,
        "coffee cup": .cup,
        "tea cup": .cup,
        "mug": .cup,
        "cardboard box": .box,
        "package": .box,
        "parcel": .box,
        "door key": .key,
        "car key": .key,
        
        // Currency variations
        "metal coin": .coin,
        "penny": .coin,
        "quarter": .coin,
        "dollar coin": .coin,
        "paper money": .bill,
        "banknote": .bill,
        "dollar bill": .bill,
        "cash": .bill,
        
        // Stationery variations
        "ballpoint pen": .pen,
        "writing pen": .pen,
        "mechanical pencil": .pencil,
        "spiral notebook": .notebook,
        "notepad": .notebook,
        "measuring ruler": .ruler,
        "straightedge": .ruler,
        
        // Furniture variations
        "office chair": .chair,
        "dining chair": .chair,
        "desk chair": .chair,
        "dining table": .table,
        "coffee table": .table,
        "office desk": .desk,
        "writing desk": .desk
    ]
    
    // MARK: - Classification Methods
    
    /// Classify an object based on Vision recognition results
    /// - Parameter labels: Array of VNClassificationObservation from Vision
    /// - Returns: Tuple of (ObjectType, confidence)
    func classify(from labels: [VNClassificationObservation]) -> (type: ObjectType, confidence: Float) {
        // Filter labels by minimum confidence
        let validLabels = labels.filter { $0.confidence >= minimumConfidence }
        
        guard !validLabels.isEmpty else {
            return (.unknown, 0.0)
        }
        
        // Try to find a match in our label mappings
        for label in validLabels {
            let identifier = label.identifier.lowercased()
            
            // Direct mapping match
            if let objectType = labelMappings[identifier] {
                return (objectType, label.confidence)
            }
            
            // Fuzzy matching
            if let objectType = fuzzyMatch(identifier) {
                return (objectType, label.confidence * 0.9) // Slightly reduce confidence for fuzzy matches
            }
        }
        
        // If no match found, return unknown with the highest confidence
        return (.unknown, validLabels[0].confidence)
    }
    
    /// Classify an object based on a single label string
    /// - Parameter label: Label string from detection
    /// - Returns: ObjectType
    func classify(from label: String) -> ObjectType {
        let lowercasedLabel = label.lowercased()
        
        // Check direct mapping
        if let objectType = labelMappings[lowercasedLabel] {
            return objectType
        }
        
        // Fuzzy matching
        if let objectType = fuzzyMatch(lowercasedLabel) {
            return objectType
        }
        
        return .unknown
    }
    
    /// Re-classify an existing detected object with additional context
    /// - Parameters:
    ///   - object: The detected object to re-classify
    ///   - context: Additional context information (e.g., surrounding objects)
    /// - Returns: Updated ObjectType
    func reclassify(_ object: DetectedObject, context: [DetectedObject] = []) -> ObjectType {
        // Start with the current classification
        var classification = object.objectType
        
        // If already classified as something specific, keep it
        if classification != .unknown {
            return classification
        }
        
        // Use context to improve classification
        // For example, if surrounded by stationery items, more likely to be stationery
        if !context.isEmpty {
            let categories = context.map { $0.objectType.category }
            let mostCommonCategory = mostFrequent(in: categories)
            
            // If there's a dominant category, use it to inform classification
            if let category = mostCommonCategory {
                classification = inferTypeFromCategory(category, boundingBox: object.boundingBox)
            }
        }
        
        return classification
    }
    
    // MARK: - Helper Methods
    
    /// Perform fuzzy matching on a label string
    /// - Parameter label: Label string to match
    /// - Returns: Matched ObjectType or nil
    private func fuzzyMatch(_ label: String) -> ObjectType? {
        // Check if label contains any of our known keywords
        for (key, objectType) in labelMappings {
            if label.contains(key) || key.contains(label) {
                return objectType
            }
        }
        
        // Check against ObjectType raw values
        for objectType in ObjectType.allCases {
            if label.contains(objectType.rawValue) || objectType.rawValue.contains(label) {
                return objectType
            }
        }
        
        return nil
    }
    
    /// Find the most frequent element in an array
    /// - Parameter array: Array of elements
    /// - Returns: Most frequent element or nil
    private func mostFrequent<T: Hashable>(in array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        
        var counts: [T: Int] = [:]
        for element in array {
            counts[element, default: 0] += 1
        }
        
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Infer object type from category and bounding box characteristics
    /// - Parameters:
    ///   - category: The object category
    ///   - boundingBox: The bounding box of the object
    /// - Returns: Inferred ObjectType
    private func inferTypeFromCategory(_ category: ObjectCategory, boundingBox: CGRect) -> ObjectType {
        let aspectRatio: CGFloat = boundingBox.width / (boundingBox.height > 0 ? boundingBox.height : 1)
        
        switch category {
        case .electronics:
            // Tall and narrow -> phone
            if aspectRatio < 0.7 {
                return .phone
            }
            // Wide -> laptop or monitor
            if aspectRatio > 1.3 {
                return .laptop
            }
            return .tablet
            
        case .stationery:
            // Very narrow -> pen or pencil
            if aspectRatio < 0.3 {
                return .pen
            }
            // Square-ish -> notebook
            if aspectRatio > 0.7 && aspectRatio < 1.3 {
                return .notebook
            }
            return .ruler
            
        case .furniture:
            // Tall -> chair
            if aspectRatio < 0.8 {
                return .chair
            }
            return .table
            
        case .everyday:
            // Small and square -> lighter or card
            if boundingBox.width < 100 && boundingBox.height < 100 {
                return aspectRatio > 1.3 ? .creditCard : .lighter
            }
            return .box
            
        case .currency:
            // Circular or square -> coin
            if abs(aspectRatio - 1.0) < 0.2 {
                return .coin
            }
            return .bill
            
        case .unknown:
            return .unknown
        }
    }
    
    // MARK: - Confidence Scoring
    
    /// Calculate a composite confidence score based on multiple factors
    /// - Parameters:
    ///   - detectionConfidence: Confidence from object detection
    ///   - classificationConfidence: Confidence from classification
    ///   - contextScore: Score based on surrounding context (0-1)
    /// - Returns: Composite confidence score (0-1)
    func compositeConfidence(
        detection: Float,
        classification: Float,
        context: Float = 0.5
    ) -> Float {
        // Weighted average: detection 40%, classification 40%, context 20%
        return (detection * 0.4) + (classification * 0.4) + (context * 0.2)
    }
    
    /// Evaluate if a classification is reliable
    /// - Parameter confidence: Confidence score
    /// - Returns: True if classification is reliable
    func isReliable(confidence: Float) -> Bool {
        return confidence >= 0.6
    }
    
    /// Get a human-readable confidence level
    /// - Parameter confidence: Confidence score
    /// - Returns: Confidence level description
    func confidenceLevel(for confidence: Float) -> String {
        switch confidence {
        case 0.8...1.0:
            return "高"
        case 0.6..<0.8:
            return "中"
        case 0.4..<0.6:
            return "低"
        default:
            return "很低"
        }
    }
}

// MARK: - ObjectType Extensions

extension ObjectType {
    /// Get typical dimensions for known object types (in centimeters)
    var typicalDimensions: (length: Float, width: Float, height: Float)? {
        switch self {
        case .phone:
            return (14.7, 7.1, 0.8)
        case .laptop:
            return (30.0, 21.0, 2.0)
        case .tablet:
            return (24.0, 17.0, 0.7)
        case .monitor:
            return (60.0, 35.0, 5.0)
        case .watch:
            return (4.0, 3.5, 1.0)
        case .lighter:
            return (7.5, 2.5, 1.2)
        case .creditCard:
            return (8.5, 5.4, 0.1)
        case .book:
            return (20.0, 15.0, 2.0)
        case .bottle:
            return (20.0, 6.0, 6.0)
        case .cup:
            return (10.0, 8.0, 8.0)
        case .coin:
            return (2.4, 2.4, 0.2)
        case .bill:
            return (15.6, 6.6, 0.01)
        case .pen:
            return (14.0, 1.0, 1.0)
        case .pencil:
            return (19.0, 0.7, 0.7)
        case .ruler:
            return (30.0, 3.0, 0.2)
        default:
            return nil
        }
    }
    
    /// Check if this object type can be used as a reference
    var canBeReference: Bool {
        switch self {
        case .lighter, .creditCard, .coin, .bill, .pen, .ruler:
            return true
        default:
            return false
        }
    }
}
