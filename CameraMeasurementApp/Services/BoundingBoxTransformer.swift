//
//  BoundingBoxTransformer.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import Vision
import ARKit

/// Utility class for transforming bounding boxes between different coordinate systems
class BoundingBoxTransformer {
    
    // MARK: - Vision to UIKit Coordinate Transformation
    
    /// Convert Vision's normalized bounding box (origin bottom-left) to UIKit coordinates (origin top-left)
    /// - Parameters:
    ///   - visionBox: The bounding box from Vision framework (normalized 0-1, origin bottom-left)
    ///   - imageSize: The size of the image in pixels
    /// - Returns: CGRect in UIKit coordinates (pixels, origin top-left)
    static func visionToUIKit(_ visionBox: CGRect, imageSize: CGSize) -> CGRect {
        // Vision uses normalized coordinates (0-1) with origin at bottom-left
        // UIKit uses pixel coordinates with origin at top-left
        
        let x = visionBox.origin.x * imageSize.width
        let y = (1 - visionBox.origin.y - visionBox.height) * imageSize.height
        let width = visionBox.width * imageSize.width
        let height = visionBox.height * imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// Convert UIKit bounding box to Vision's normalized coordinates
    /// - Parameters:
    ///   - uiKitBox: The bounding box in UIKit coordinates (pixels, origin top-left)
    ///   - imageSize: The size of the image in pixels
    /// - Returns: CGRect in Vision normalized coordinates (0-1, origin bottom-left)
    static func uiKitToVision(_ uiKitBox: CGRect, imageSize: CGSize) -> CGRect {
        let x = uiKitBox.origin.x / imageSize.width
        let y = 1 - (uiKitBox.origin.y / imageSize.height) - (uiKitBox.height / imageSize.height)
        let width = uiKitBox.width / imageSize.width
        let height = uiKitBox.height / imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    // MARK: - Bounding Box Scaling
    
    /// Scale a bounding box to a different image size
    /// - Parameters:
    ///   - box: The original bounding box
    ///   - fromSize: The original image size
    ///   - toSize: The target image size
    /// - Returns: Scaled bounding box
    static func scale(_ box: CGRect, from fromSize: CGSize, to toSize: CGSize) -> CGRect {
        let scaleX = toSize.width / fromSize.width
        let scaleY = toSize.height / fromSize.height
        
        return CGRect(
            x: box.origin.x * scaleX,
            y: box.origin.y * scaleY,
            width: box.width * scaleX,
            height: box.height * scaleY
        )
    }
    
    // MARK: - Bounding Box Validation
    
    /// Validate and clamp a bounding box to ensure it's within image bounds
    /// - Parameters:
    ///   - box: The bounding box to validate
    ///   - imageSize: The image size to clamp to
    /// - Returns: Validated and clamped bounding box
    static func validate(_ box: CGRect, within imageSize: CGSize) -> CGRect {
        var validBox = box
        
        // Clamp origin
        validBox.origin.x = max(0, min(validBox.origin.x, imageSize.width))
        validBox.origin.y = max(0, min(validBox.origin.y, imageSize.height))
        
        // Clamp size
        validBox.size.width = max(0, min(validBox.size.width, imageSize.width - validBox.origin.x))
        validBox.size.height = max(0, min(validBox.size.height, imageSize.height - validBox.origin.y))
        
        return validBox
    }
    
    /// Check if a bounding box is valid (has positive dimensions and is within reasonable bounds)
    /// - Parameter box: The bounding box to check
    /// - Returns: True if the box is valid
    static func isValid(_ box: CGRect) -> Bool {
        return box.width > 0 && box.height > 0 && 
               !box.origin.x.isNaN && !box.origin.y.isNaN &&
               !box.width.isNaN && !box.height.isNaN &&
               !box.origin.x.isInfinite && !box.origin.y.isInfinite &&
               !box.width.isInfinite && !box.height.isInfinite
    }
    
    // MARK: - Bounding Box Utilities
    
    /// Get the center point of a bounding box
    /// - Parameter box: The bounding box
    /// - Returns: Center point as CGPoint
    static func center(of box: CGRect) -> CGPoint {
        return CGPoint(
            x: box.origin.x + box.width / 2,
            y: box.origin.y + box.height / 2
        )
    }
    
    /// Calculate the area of a bounding box
    /// - Parameter box: The bounding box
    /// - Returns: Area in square pixels
    static func area(of box: CGRect) -> CGFloat {
        return box.width * box.height
    }
    
    /// Calculate the Intersection over Union (IoU) between two bounding boxes
    /// - Parameters:
    ///   - box1: First bounding box
    ///   - box2: Second bounding box
    /// - Returns: IoU value between 0 and 1
    static func iou(between box1: CGRect, and box2: CGRect) -> CGFloat {
        let intersection = box1.intersection(box2)
        
        if intersection.isNull {
            return 0
        }
        
        let intersectionArea = area(of: intersection)
        let unionArea = area(of: box1) + area(of: box2) - intersectionArea
        
        guard unionArea > 0 else { return 0 }
        
        return intersectionArea / unionArea
    }
    
    /// Expand a bounding box by a given margin (percentage)
    /// - Parameters:
    ///   - box: The original bounding box
    ///   - margin: Margin as a percentage (e.g., 0.1 for 10%)
    /// - Returns: Expanded bounding box
    static func expand(_ box: CGRect, by margin: CGFloat) -> CGRect {
        let widthMargin = box.width * margin
        let heightMargin = box.height * margin
        
        return CGRect(
            x: box.origin.x - widthMargin / 2,
            y: box.origin.y - heightMargin / 2,
            width: box.width + widthMargin,
            height: box.height + heightMargin
        )
    }
    
    // MARK: - AR Coordinate Transformation
    
    /// Convert a 2D bounding box point to a 3D world position using AR frame
    /// - Parameters:
    ///   - point: 2D point in image coordinates
    ///   - frame: ARFrame containing camera and depth information
    ///   - viewportSize: Size of the AR view
    /// - Returns: 3D world position as SCNVector3, or nil if conversion fails
    static func imagePointToWorldPosition(
        _ point: CGPoint,
        in frame: ARFrame,
        viewportSize: CGSize
    ) -> SCNVector3? {
        // Normalize the point to viewport coordinates (0-1)
        let normalizedPoint = CGPoint(
            x: point.x / viewportSize.width,
            y: point.y / viewportSize.height
        )
        
        // Perform hit test to get world position
        let hitTestResults = frame.hitTest(normalizedPoint, types: [.featurePoint, .estimatedHorizontalPlane])
        
        if let result = hitTestResults.first {
            let position = result.worldTransform.columns.3
            return SCNVector3(position.x, position.y, position.z)
        }
        
        return nil
    }
    
    /// Get the 3D world positions for all corners of a bounding box
    /// - Parameters:
    ///   - box: The 2D bounding box
    ///   - frame: ARFrame containing camera and depth information
    ///   - viewportSize: Size of the AR view
    /// - Returns: Array of corner positions (top-left, top-right, bottom-right, bottom-left)
    static func boundingBoxCorners(
        _ box: CGRect,
        in frame: ARFrame,
        viewportSize: CGSize
    ) -> [SCNVector3?] {
        let topLeft = CGPoint(x: box.minX, y: box.minY)
        let topRight = CGPoint(x: box.maxX, y: box.minY)
        let bottomRight = CGPoint(x: box.maxX, y: box.maxY)
        let bottomLeft = CGPoint(x: box.minX, y: box.maxY)
        
        return [
            imagePointToWorldPosition(topLeft, in: frame, viewportSize: viewportSize),
            imagePointToWorldPosition(topRight, in: frame, viewportSize: viewportSize),
            imagePointToWorldPosition(bottomRight, in: frame, viewportSize: viewportSize),
            imagePointToWorldPosition(bottomLeft, in: frame, viewportSize: viewportSize)
        ]
    }
}

// MARK: - CGRect Extensions

extension CGRect {
    /// Get all four corners of the rectangle
    var corners: [CGPoint] {
        return [
            CGPoint(x: minX, y: minY), // top-left
            CGPoint(x: maxX, y: minY), // top-right
            CGPoint(x: maxX, y: maxY), // bottom-right
            CGPoint(x: minX, y: maxY)  // bottom-left
        ]
    }
    
    /// Get the aspect ratio (width / height)
    var aspectRatio: CGFloat {
        guard height > 0 else { return 0 }
        return width / height
    }
}
