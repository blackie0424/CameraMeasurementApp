//
//  ReferenceObjectManager.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import SceneKit

/// Manager class for handling reference objects used in measurement calibration
class ReferenceObjectManager: ReferenceObjectManagerProtocol {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = ReferenceObjectManager()
    
    /// All available reference objects
    private var availableObjects: [ReferenceObject]
    
    /// Currently selected reference object
    private(set) var currentReference: ReferenceObject?
    
    /// User preferences for reference object selection
    private let userDefaults = UserDefaults.standard
    private let preferredReferenceKey = "preferredReferenceObject"
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with default reference objects
        self.availableObjects = ReferenceObject.defaultObjects
        
        // Load user's preferred reference object if available
        if let preferredName = userDefaults.string(forKey: preferredReferenceKey),
           let preferred = availableObjects.first(where: { $0.name == preferredName }) {
            self.currentReference = preferred
        } else {
            // Default to credit card as it's most commonly available
            self.currentReference = ReferenceObject.creditCard
        }
    }
    
    // MARK: - ReferenceObjectManagerProtocol Implementation
    
    /// Get all available reference objects
    /// - Returns: Array of available reference objects
    func getAvailableObjects() -> [ReferenceObject] {
        return availableObjects
    }
    
    /// Select the best reference object for a measured object
    /// - Parameter measuredObject: The detected object to find a reference for
    /// - Returns: The most suitable reference object
    func selectBestReference(for measuredObject: DetectedObject) -> ReferenceObject {
        // If object has dimensions, use size-based selection
        if let dimensions = measuredObject.dimensions {
            return selectBySize(dimensions)
        }
        
        // If object type is known, use type-based selection
        if measuredObject.objectType != .unknown {
            return selectByType(measuredObject.objectType)
        }
        
        // If object has bounding box, use aspect ratio
        return selectByBoundingBox(measuredObject.boundingBox)
    }
    
    /// Get the 3D model node for a reference object
    /// - Parameter object: The reference object
    /// - Returns: SCNNode representing the reference object
    func getReferenceModel(for object: ReferenceObject) -> SCNNode {
        // Try to load the model from file
        if let scene = SCNScene(named: object.modelFileName) {
            if let modelNode = scene.rootNode.childNodes.first {
                return modelNode
            }
        }
        
        // If model file doesn't exist, create a simple geometric representation
        return createGeometricModel(for: object)
    }
    
    // MARK: - Selection Logic
    
    /// Select reference object based on measured dimensions
    /// - Parameter dimensions: The measured object dimensions
    /// - Returns: Best matching reference object
    private func selectBySize(_ dimensions: ObjectDimensions) -> ReferenceObject {
        let volume = dimensions.volume
        
        // Calculate volume difference for each reference object
        var bestMatch = ReferenceObject.creditCard
        var smallestDifference: Float = Float.greatestFiniteMagnitude
        
        for reference in availableObjects where reference.isCommonlyUsed {
            let refVolume = reference.standardDimensions.volume
            let difference = abs(volume - refVolume)
            
            if difference < smallestDifference {
                smallestDifference = difference
                bestMatch = reference
            }
        }
        
        return bestMatch
    }
    
    /// Select reference object based on object type
    /// - Parameter objectType: The detected object type
    /// - Returns: Best matching reference object
    private func selectByType(_ objectType: ObjectType) -> ReferenceObject {
        // Map object types to appropriate reference objects
        switch objectType.category {
        case .electronics:
            // For electronics, use credit card or iPhone
            return objectType == .phone ? ReferenceObject.iPhone : ReferenceObject.creditCard
            
        case .stationery:
            // For stationery, use pen or ruler
            return ReferenceObject.pen
            
        case .currency:
            // For currency, use coin or bill reference
            return objectType == .coin ? ReferenceObject.coin : ReferenceObject.creditCard
            
        case .everyday:
            // For everyday items, use lighter or credit card
            return ReferenceObject.lighter
            
        case .furniture:
            // For furniture, use larger reference like iPhone
            return ReferenceObject.iPhone
            
        case .unknown:
            // Default to credit card for unknown objects
            return ReferenceObject.creditCard
        }
    }
    
    /// Select reference object based on bounding box characteristics
    /// - Parameter boundingBox: The bounding box of the detected object
    /// - Returns: Best matching reference object
    private func selectByBoundingBox(_ boundingBox: CGRect) -> ReferenceObject {
        let aspectRatio = boundingBox.width / (boundingBox.height > 0 ? boundingBox.height : 1)
        let area = boundingBox.width * boundingBox.height
        
        // Small and square-ish -> coin
        if area < 5000 && abs(aspectRatio - 1.0) < 0.3 {
            return ReferenceObject.coin
        }
        
        // Small and rectangular -> credit card or lighter
        if area < 10000 {
            return aspectRatio > 1.3 ? ReferenceObject.creditCard : ReferenceObject.lighter
        }
        
        // Medium size and elongated -> pen
        if area < 20000 && aspectRatio < 0.3 {
            return ReferenceObject.pen
        }
        
        // Larger objects -> iPhone
        if area > 20000 {
            return ReferenceObject.iPhone
        }
        
        // Default to credit card
        return ReferenceObject.creditCard
    }
    
    // MARK: - Model Creation
    
    /// Create a simple geometric model for a reference object
    /// - Parameter object: The reference object
    /// - Returns: SCNNode with geometric representation
    private func createGeometricModel(for object: ReferenceObject) -> SCNNode {
        let dims = object.standardDimensions
        
        // Create a box geometry with the object's dimensions
        // Convert from cm to meters for SceneKit (divide by 100)
        let geometry = SCNBox(
            width: CGFloat(dims.width / 100.0),
            height: CGFloat(dims.height / 100.0),
            length: CGFloat(dims.length / 100.0),
            chamferRadius: 0.001
        )
        
        // Set material color based on category
        let material = SCNMaterial()
        material.diffuse.contents = colorForCategory(object.category)
        material.transparency = 0.7
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        node.name = object.name
        
        return node
    }
    
    /// Get color for object category
    /// - Parameter category: The object category
    /// - Returns: UIColor for the category
    private func colorForCategory(_ category: ObjectCategory) -> UIColor {
        switch category {
        case .electronics:
            return UIColor.systemBlue
        case .everyday:
            return UIColor.systemGreen
        case .currency:
            return UIColor.systemYellow
        case .stationery:
            return UIColor.systemPurple
        case .furniture:
            return UIColor.systemBrown
        case .unknown:
            return UIColor.systemGray
        }
    }
    
    // MARK: - User Preferences
    
    /// Set the current reference object
    /// - Parameter reference: The reference object to set as current
    func setCurrentReference(_ reference: ReferenceObject) {
        self.currentReference = reference
        userDefaults.set(reference.name, forKey: preferredReferenceKey)
    }
    
    /// Get commonly used reference objects
    /// - Returns: Array of commonly used reference objects
    func getCommonlyUsedObjects() -> [ReferenceObject] {
        return availableObjects.filter { $0.isCommonlyUsed }
    }
    
    /// Add a custom reference object
    /// - Parameter object: The custom reference object to add
    func addCustomReference(_ object: ReferenceObject) {
        if !availableObjects.contains(where: { $0.name == object.name }) {
            availableObjects.append(object)
        }
    }
    
    /// Remove a custom reference object
    /// - Parameter name: The name of the reference object to remove
    func removeCustomReference(named name: String) {
        // Don't allow removal of default objects
        let defaultNames = ReferenceObject.defaultObjects.map { $0.name }
        guard !defaultNames.contains(name) else { return }
        
        availableObjects.removeAll { $0.name == name }
        
        // If removed object was current, reset to default
        if currentReference?.name == name {
            currentReference = ReferenceObject.creditCard
        }
    }
    
    // MARK: - Comparison and Validation
    
    /// Compare measured dimensions with reference object
    /// - Parameters:
    ///   - measured: The measured dimensions
    ///   - reference: The reference object
    /// - Returns: Tuple of (scale factor, accuracy)
    func compare(measured: ObjectDimensions, with reference: ReferenceObject) -> (scaleFactor: Float, accuracy: Float) {
        let refDims = reference.standardDimensions
        
        // Calculate scale factors for each dimension
        let lengthScale = measured.length / refDims.length
        let widthScale = measured.width / refDims.width
        let heightScale = measured.height / refDims.height
        
        // Average scale factor
        let avgScale = (lengthScale + widthScale + heightScale) / 3.0
        
        // Calculate consistency (how similar are the scale factors)
        let variance = [lengthScale, widthScale, heightScale].map { pow($0 - avgScale, 2) }.reduce(0, +) / 3.0
        let consistency = 1.0 / (1.0 + variance)
        
        // Accuracy is combination of reference accuracy and consistency
        let accuracy = refDims.accuracy * consistency
        
        return (avgScale, accuracy)
    }
    
    /// Validate if a reference object is suitable for calibration
    /// - Parameters:
    ///   - reference: The reference object
    ///   - measuredObject: The detected object
    /// - Returns: True if suitable for calibration
    func isValidForCalibration(reference: ReferenceObject, measuredObject: DetectedObject) -> Bool {
        // Reference should have high accuracy
        guard reference.standardDimensions.accuracy >= 0.9 else {
            return false
        }
        
        // If measured object has dimensions, check size compatibility
        if let dimensions = measuredObject.dimensions {
            let refVolume = reference.standardDimensions.volume
            let measuredVolume = dimensions.volume
            
            // Reference should be similar in size (within 10x range)
            let ratio = max(refVolume, measuredVolume) / min(refVolume, measuredVolume)
            return ratio <= 10.0
        }
        
        return true
    }
}
