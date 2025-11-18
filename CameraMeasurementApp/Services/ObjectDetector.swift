//
//  ObjectDetector.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import Vision
import CoreML
import SceneKit

/// ObjectDetector integrates Core ML and Vision frameworks to detect and classify objects in images
class ObjectDetector: ObjectDetectorProtocol {
    
    // MARK: - Properties
    
    private var visionModel: VNCoreMLModel?
    private let confidenceThreshold: Float = 0.25
    private var detectionCache: [String: [DetectedObject]] = [:]
    private let classifier = ObjectClassifier()
    private let boundingBoxTransformer = BoundingBoxTransformer.self
    private let confidenceEvaluator = ConfidenceEvaluator()
    
    // MARK: - Initialization
    
    init() {
        setupModel()
    }
    
    // MARK: - Model Setup
    
    private func setupModel() {
        // Try to load YOLOv5 model
        // Note: The actual .mlmodel file needs to be added to the project
        // For now, we'll handle the case where the model might not exist yet
        
        do {
            // Attempt to load a YOLOv5 model if it exists in the bundle
            if let modelURL = Bundle.main.url(forResource: "YOLOv5", withExtension: "mlmodelc") {
                let mlModel = try MLModel(contentsOf: modelURL)
                visionModel = try VNCoreMLModel(for: mlModel)
                print("✅ YOLOv5 model loaded successfully")
            } else {
                print("⚠️ YOLOv5 model not found in bundle. Object detection will use fallback mode.")
            }
        } catch {
            print("❌ Failed to load Core ML model: \(error.localizedDescription)")
            visionModel = nil
        }
    }
    
    // MARK: - ObjectDetectorProtocol Implementation
    
    func detectObjects(in image: UIImage) -> [DetectedObject] {
        guard let cgImage = image.cgImage else {
            print("❌ Failed to convert UIImage to CGImage")
            return []
        }
        
        // Check cache first
        let cacheKey = generateCacheKey(for: image)
        if let cachedResults = detectionCache[cacheKey] {
            return cachedResults
        }
        
        var detectedObjects: [DetectedObject] = []
        
        if let model = visionModel {
            // Use Core ML model for detection
            detectedObjects = performMLDetection(on: cgImage)
        } else {
            // Fallback: Use Vision's built-in object detection
            detectedObjects = performVisionDetection(on: cgImage)
        }
        
        // Filter objects based on confidence evaluation
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        detectedObjects = filterByConfidenceEvaluation(detectedObjects, imageSize: imageSize)
        
        // Update detection history for temporal consistency
        confidenceEvaluator.updateHistory(with: detectedObjects)
        
        // Cache results
        detectionCache[cacheKey] = detectedObjects
        
        // Limit cache size
        if detectionCache.count > 10 {
            detectionCache.removeAll()
        }
        
        return detectedObjects
    }
    
    func classifyObject(_ object: DetectedObject) -> ObjectType {
        // The object type is already determined during detection
        // This method allows for re-classification if needed
        return object.objectType
    }
    
    func getBoundingBox(for object: DetectedObject) -> CGRect {
        return object.boundingBox
    }
    
    // MARK: - Core ML Detection
    
    private func performMLDetection(on cgImage: CGImage) -> [DetectedObject] {
        guard visionModel != nil else { return [] }
        
        var detectedObjects: [DetectedObject] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        let request = VNCoreMLRequest(model: visionModel!) { [weak self] request, error in
            guard let self = self else {
                semaphore.signal()
                return
            }
            
            if let error = error {
                print("❌ Core ML request error: \(error.localizedDescription)")
                semaphore.signal()
                return
            }
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                semaphore.signal()
                return
            }
            
            // Process each detection
            for observation in results {
                guard observation.confidence >= self.confidenceThreshold else { continue }
                
                // Get the bounding box in image coordinates using BoundingBoxTransformer
                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                let boundingBox = BoundingBoxTransformer.visionToUIKit(observation.boundingBox, imageSize: imageSize)
                
                // Validate the bounding box
                guard BoundingBoxTransformer.isValid(boundingBox) else {
                    print("⚠️ Invalid bounding box detected, skipping")
                    continue
                }
                
                // Classify the object using the advanced classifier
                let (objectType, classificationConfidence) = self.classifier.classify(from: observation.labels)
                
                // Calculate composite confidence
                let compositeConfidence = self.classifier.compositeConfidence(
                    detection: observation.confidence,
                    classification: classificationConfidence
                )
                
                // Create detected object (worldPosition will be set later by ARManager)
                let detectedObject = DetectedObject(
                    boundingBox: boundingBox,
                    objectType: objectType,
                    confidence: compositeConfidence,
                    worldPosition: SCNVector3Zero
                )
                
                detectedObjects.append(detectedObject)
            }
            
            semaphore.signal()
        }
        
        // Configure request
        request.imageCropAndScaleOption = .scaleFit
        
        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            semaphore.wait()
        } catch {
            print("❌ Failed to perform detection: \(error.localizedDescription)")
        }
        
        return detectedObjects
    }
    
    // MARK: - Vision Framework Detection (Fallback)
    
    private func performVisionDetection(on cgImage: CGImage) -> [DetectedObject] {
        print("⚠️ Fallback detection mode: Using Vision framework built-in detection")
        
        var detectedObjects: [DetectedObject] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        // Use Vision's built-in object recognition
        let request = VNRecognizeAnimalsRequest { [weak self] request, error in
            guard let self = self else {
                semaphore.signal()
                return
            }
            
            if let error = error {
                print("❌ Vision detection error: \(error.localizedDescription)")
            }
            
            // Process animal detections
            if let results = request.results as? [VNRecognizedObjectObservation] {
                for observation in results {
                    guard observation.confidence >= self.confidenceThreshold else { continue }
                    
                    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                    let boundingBox = BoundingBoxTransformer.visionToUIKit(observation.boundingBox, imageSize: imageSize)
                    
                    guard BoundingBoxTransformer.isValid(boundingBox) else { continue }
                    
                    // Classify based on labels
                    let (objectType, classificationConfidence) = self.classifier.classify(from: observation.labels)
                    
                    let detectedObject = DetectedObject(
                        boundingBox: boundingBox,
                        objectType: objectType,
                        confidence: observation.confidence,
                        worldPosition: SCNVector3Zero
                    )
                    
                    detectedObjects.append(detectedObject)
                }
            }
            
            semaphore.signal()
        }
        
        // Also try to detect rectangles (for objects like phones, books, cards)
        let rectangleRequest = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Rectangle detection error: \(error.localizedDescription)")
                return
            }
            
            if let results = request.results as? [VNRectangleObservation] {
                for observation in results.prefix(5) { // Limit to top 5 rectangles
                    guard observation.confidence >= self.confidenceThreshold else { continue }
                    
                    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                    let boundingBox = BoundingBoxTransformer.visionToUIKit(observation.boundingBox, imageSize: imageSize)
                    
                    guard BoundingBoxTransformer.isValid(boundingBox) else { continue }
                    
                    // Infer object type based on aspect ratio
                    let aspectRatio = boundingBox.width / boundingBox.height
                    let objectType = self.inferObjectTypeFromAspectRatio(aspectRatio)
                    
                    let detectedObject = DetectedObject(
                        boundingBox: boundingBox,
                        objectType: objectType,
                        confidence: observation.confidence,
                        worldPosition: SCNVector3Zero
                    )
                    
                    detectedObjects.append(detectedObject)
                }
            }
        }
        
        // Configure rectangle detection
        rectangleRequest.minimumAspectRatio = 0.3
        rectangleRequest.maximumAspectRatio = 3.0
        rectangleRequest.minimumSize = 0.1
        rectangleRequest.maximumObservations = 5
        
        // Perform both requests
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request, rectangleRequest])
            semaphore.wait()
        } catch {
            print("❌ Failed to perform fallback detection: \(error.localizedDescription)")
        }
        
        print("✅ Fallback detection found \(detectedObjects.count) objects")
        return detectedObjects
    }
    
    /// Infer object type based on aspect ratio
    private func inferObjectTypeFromAspectRatio(_ aspectRatio: CGFloat) -> ObjectType {
        switch aspectRatio {
        case 0.4...0.6:
            return .phone // Typical phone aspect ratio
        case 1.4...1.8:
            return .creditCard // Credit card-like
        case 0.6...0.8:
            return .book // Book-like
        case 0.8...1.2:
            return .box // Square-ish objects
        default:
            return .unknown
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generate cache key for image
    private func generateCacheKey(for image: UIImage) -> String {
        // Use image size and scale as a simple cache key
        return "\(image.size.width)x\(image.size.height)@\(image.scale)x"
    }
    
    // MARK: - Public Utility Methods
    
    /// Check if the model is loaded and ready
    func isModelLoaded() -> Bool {
        return visionModel != nil
    }
    
    /// Get the current confidence threshold
    func getConfidenceThreshold() -> Float {
        return confidenceThreshold
    }
    
    /// Clear detection cache
    func clearCache() {
        detectionCache.removeAll()
    }
    
    /// Reload the Core ML model
    func reloadModel() {
        setupModel()
    }
}

// MARK: - Extensions

extension ObjectDetector {
    /// Detect objects asynchronously
    func detectObjectsAsync(in image: UIImage, completion: @escaping ([DetectedObject]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let objects = self.detectObjects(in: image)
            
            DispatchQueue.main.async {
                completion(objects)
            }
        }
    }
    
    /// Filter detected objects by confidence threshold
    func filterByConfidence(_ objects: [DetectedObject], threshold: Float) -> [DetectedObject] {
        return objects.filter { $0.confidence >= threshold }
    }
    
    /// Get the most confident detection
    func getMostConfidentObject(from objects: [DetectedObject]) -> DetectedObject? {
        return objects.max(by: { $0.confidence < $1.confidence })
    }
    
    /// Group detected objects by category
    func groupByCategory(_ objects: [DetectedObject]) -> [ObjectCategory: [DetectedObject]] {
        var grouped: [ObjectCategory: [DetectedObject]] = [:]
        
        for object in objects {
            let category = object.objectType.category
            grouped[category, default: []].append(object)
        }
        
        return grouped
    }
    
    /// Filter objects by type
    func filter(_ objects: [DetectedObject], byType type: ObjectType) -> [DetectedObject] {
        return objects.filter { $0.objectType == type }
    }
    
    /// Filter objects by category
    func filter(_ objects: [DetectedObject], byCategory category: ObjectCategory) -> [DetectedObject] {
        return objects.filter { $0.objectType.category == category }
    }
    
    /// Remove overlapping detections using Non-Maximum Suppression (NMS)
    func removeOverlaps(from objects: [DetectedObject], iouThreshold: CGFloat = 0.5) -> [DetectedObject] {
        guard objects.count > 1 else { return objects }
        
        // Sort by confidence (highest first)
        var sortedObjects = objects.sorted { $0.confidence > $1.confidence }
        var result: [DetectedObject] = []
        
        while !sortedObjects.isEmpty {
            // Take the most confident detection
            let current = sortedObjects.removeFirst()
            result.append(current)
            
            // Remove overlapping detections
            sortedObjects = sortedObjects.filter { candidate in
                let iou = BoundingBoxTransformer.iou(between: current.boundingBox, and: candidate.boundingBox)
                return iou < iouThreshold
            }
        }
        
        return result
    }
    
    /// Validate bounding boxes and remove invalid ones
    func validateBoundingBoxes(_ objects: [DetectedObject], imageSize: CGSize) -> [DetectedObject] {
        return objects.filter { object in
            let validBox = BoundingBoxTransformer.validate(object.boundingBox, within: imageSize)
            return BoundingBoxTransformer.isValid(validBox) && 
                   BoundingBoxTransformer.area(of: validBox) > 100 // Minimum area threshold
        }
    }
    
    /// Re-classify objects with context awareness
    func reclassifyWithContext(_ objects: [DetectedObject]) -> [DetectedObject] {
        return objects.map { object in
            let newType = classifier.reclassify(object, context: objects)
            
            // If classification changed, create a new object with updated type
            if newType != object.objectType {
                return DetectedObject(
                    id: object.id,
                    boundingBox: object.boundingBox,
                    objectType: newType,
                    confidence: object.confidence * 0.95, // Slightly reduce confidence for re-classification
                    worldPosition: object.worldPosition,
                    dimensions: object.dimensions
                )
            }
            
            return object
        }
    }
    
    /// Get objects that can be used as reference objects
    func getReferenceObjects(from objects: [DetectedObject]) -> [DetectedObject] {
        return objects.filter { $0.objectType.canBeReference }
    }
    
    /// Calculate the center point of a detected object
    func centerPoint(of object: DetectedObject) -> CGPoint {
        return BoundingBoxTransformer.center(of: object.boundingBox)
    }
    
    /// Get confidence level description
    func confidenceDescription(for object: DetectedObject) -> String {
        return classifier.confidenceLevel(for: object.confidence)
    }
    
    // MARK: - Confidence Evaluation Methods
    
    /// Evaluate confidence for a detected object
    /// - Parameters:
    ///   - object: The detected object to evaluate
    ///   - imageSize: Size of the source image
    ///   - context: Other detected objects in the same frame
    /// - Returns: Confidence evaluation result
    func evaluateConfidence(
        for object: DetectedObject,
        imageSize: CGSize,
        context: [DetectedObject] = []
    ) -> ConfidenceEvaluation {
        return confidenceEvaluator.evaluate(object, imageSize: imageSize, context: context)
    }
    
    /// Evaluate confidence for all detected objects
    /// - Parameters:
    ///   - objects: Array of detected objects
    ///   - imageSize: Size of the source image
    /// - Returns: Array of confidence evaluations
    func evaluateAllConfidence(
        for objects: [DetectedObject],
        imageSize: CGSize
    ) -> [ConfidenceEvaluation] {
        return confidenceEvaluator.evaluateAll(objects, imageSize: imageSize)
    }
    
    /// Filter objects based on confidence evaluation
    /// - Parameters:
    ///   - objects: Array of detected objects
    ///   - imageSize: Size of the source image
    /// - Returns: Filtered array of objects
    private func filterByConfidenceEvaluation(
        _ objects: [DetectedObject],
        imageSize: CGSize
    ) -> [DetectedObject] {
        let evaluations = confidenceEvaluator.evaluateAll(objects, imageSize: imageSize)
        
        // Filter out objects that should be removed
        let filtered = evaluations.filter { !$0.shouldFilter }.map { $0.object }
        
        // Log filtering results
        let filteredCount = objects.count - filtered.count
        if filteredCount > 0 {
            print("🔍 Filtered out \(filteredCount) low-confidence detections")
        }
        
        return filtered
    }
    
    /// Check if an object is reliable for measurement
    /// - Parameter object: The detected object to check
    /// - Returns: True if object is reliable
    func isReliableForMeasurement(_ object: DetectedObject) -> Bool {
        return confidenceEvaluator.isReliableForMeasurement(object)
    }
    
    /// Check if an object requires manual verification
    /// - Parameter object: The detected object to check
    /// - Returns: True if manual verification is recommended
    func requiresManualVerification(_ object: DetectedObject) -> Bool {
        return confidenceEvaluator.requiresManualVerification(object)
    }
    
    /// Get only reliable detections
    /// - Parameter objects: Array of detected objects
    /// - Returns: Filtered array of reliable objects
    func getReliableDetections(from objects: [DetectedObject]) -> [DetectedObject] {
        return confidenceEvaluator.filterReliable(objects)
    }
    
    /// Get confidence statistics
    /// - Returns: Confidence statistics
    func getConfidenceStatistics() -> ConfidenceStatistics {
        return confidenceEvaluator.getStatistics()
    }
    
    /// Reset confidence statistics and history
    func resetConfidenceTracking() {
        confidenceEvaluator.clearHistory()
        confidenceEvaluator.resetStatistics()
    }
    
    /// Handle low confidence detection
    /// - Parameters:
    ///   - object: The low confidence object
    ///   - evaluation: The confidence evaluation result
    /// - Returns: MeasurementError if action is needed
    func handleLowConfidence(
        for object: DetectedObject,
        evaluation: ConfidenceEvaluation
    ) -> MeasurementError? {
        if evaluation.level == .veryLow || evaluation.level == .low {
            print("⚠️ Low confidence detection: \(evaluation.recommendation)")
            return .lowConfidenceDetection
        }
        return nil
    }
}
