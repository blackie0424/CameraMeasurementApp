//
//  MeasurementRecord.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import CoreLocation

struct MeasurementRecord {
    let id: UUID
    let image: UIImage
    let detectedObjects: [DetectedObject]
    let referenceObject: ReferenceObject?
    let timestamp: Date
    let location: CLLocation?
    
    init(id: UUID = UUID(),
         image: UIImage,
         detectedObjects: [DetectedObject],
         referenceObject: ReferenceObject? = nil,
         timestamp: Date = Date(),
         location: CLLocation? = nil) {
        self.id = id
        self.image = image
        self.detectedObjects = detectedObjects
        self.referenceObject = referenceObject
        self.timestamp = timestamp
        self.location = location
    }
}

extension MeasurementRecord {
    // Computed properties for convenience
    var hasValidMeasurements: Bool {
        return !detectedObjects.isEmpty && detectedObjects.contains { $0.dimensions != nil }
    }
    
    var averageAccuracy: Float {
        let validDimensions = detectedObjects.compactMap { $0.dimensions }
        guard !validDimensions.isEmpty else { return 0.0 }
        
        let totalAccuracy = validDimensions.reduce(0.0) { $0 + $1.accuracy }
        return totalAccuracy / Float(validDimensions.count)
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}