//
//  CoordinateTransformUtility.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import ARKit
import SceneKit

/// Utility class for 3D coordinate transformations and conversions
class CoordinateTransformUtility {
    
    // MARK: - Coordinate System Conversions
    
    /// Convert screen coordinates to world coordinates using ARFrame
    /// - Parameters:
    ///   - screenPoint: Point in screen coordinate system (UIKit coordinates)
    ///   - frame: Current ARFrame containing camera and tracking information
    ///   - targetDistance: Optional distance from camera to place the point (default: 1.0 meter)
    /// - Returns: World position as SCNVector3, or nil if conversion fails
    static func screenToWorld(screenPoint: CGPoint, frame: ARFrame, targetDistance: Float = 1.0) -> SCNVector3? {
        // Normalize screen coordinates to NDC (Normalized Device Coordinates)
        let viewportSize = frame.camera.imageResolution
        let normalizedX = Float(screenPoint.x / viewportSize.width)
        let normalizedY = Float(screenPoint.y / viewportSize.height)
        
        // Convert to NDC space (-1 to 1)
        let ndcX = normalizedX * 2.0 - 1.0
        let ndcY = (1.0 - normalizedY) * 2.0 - 1.0
        
        // Get camera transform
        let cameraTransform = frame.camera.transform
        
        // Create ray direction in camera space
        let projectionMatrix = frame.camera.projectionMatrix(for: .portrait, viewportSize: viewportSize, zNear: 0.001, zFar: 1000)
        let inverseProjection = simd_inverse(projectionMatrix)
        
        // Point in clip space
        let clipSpacePoint = simd_float4(ndcX, ndcY, 1.0, 1.0)
        
        // Transform to camera space
        let cameraSpacePoint = inverseProjection * clipSpacePoint
        let normalizedCameraPoint = simd_float3(
            cameraSpacePoint.x / cameraSpacePoint.w,
            cameraSpacePoint.y / cameraSpacePoint.w,
            cameraSpacePoint.z / cameraSpacePoint.w
        )
        
        // Get ray direction in world space
        let rayDirection = simd_normalize(simd_make_float3(cameraTransform * simd_float4(normalizedCameraPoint, 0.0)))
        
        // Get camera position in world space
        let cameraPosition = simd_make_float3(cameraTransform.columns.3)
        
        // Calculate world position at target distance
        let worldPosition = cameraPosition + rayDirection * targetDistance
        
        return SCNVector3(worldPosition.x, worldPosition.y, worldPosition.z)
    }
    
    /// Convert world coordinates to screen coordinates
    /// - Parameters:
    ///   - worldPoint: Point in world coordinate system
    ///   - frame: Current ARFrame containing camera and tracking information
    /// - Returns: Screen position as CGPoint, or nil if point is behind camera
    static func worldToScreen(worldPoint: SCNVector3, frame: ARFrame) -> CGPoint? {
        let viewportSize = frame.camera.imageResolution
        
        // Convert SCNVector3 to simd_float4
        let worldPosition = simd_float4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0)
        
        // Get view and projection matrices
        let viewMatrix = frame.camera.viewMatrix(for: .portrait)
        let projectionMatrix = frame.camera.projectionMatrix(for: .portrait, viewportSize: viewportSize, zNear: 0.001, zFar: 1000)
        
        // Transform to clip space
        let clipSpacePosition = projectionMatrix * viewMatrix * worldPosition
        
        // Check if point is behind camera
        if clipSpacePosition.z < 0 {
            return nil
        }
        
        // Perspective divide to get NDC
        let ndcPosition = simd_float3(
            clipSpacePosition.x / clipSpacePosition.w,
            clipSpacePosition.y / clipSpacePosition.w,
            clipSpacePosition.z / clipSpacePosition.w
        )
        
        // Convert NDC to screen coordinates
        let screenX = (ndcPosition.x + 1.0) * 0.5 * Float(viewportSize.width)
        let screenY = (1.0 - ndcPosition.y) * 0.5 * Float(viewportSize.height)
        
        return CGPoint(x: CGFloat(screenX), y: CGFloat(screenY))
    }
    
    /// Convert camera coordinates to world coordinates
    /// - Parameters:
    ///   - cameraPoint: Point in camera coordinate system
    ///   - cameraTransform: Camera's world transform matrix
    /// - Returns: World position as SCNVector3
    static func cameraToWorld(cameraPoint: SCNVector3, cameraTransform: simd_float4x4) -> SCNVector3 {
        let cameraPosition = simd_float4(cameraPoint.x, cameraPoint.y, cameraPoint.z, 1.0)
        let worldPosition = cameraTransform * cameraPosition
        return SCNVector3(worldPosition.x, worldPosition.y, worldPosition.z)
    }
    
    /// Convert world coordinates to camera coordinates
    /// - Parameters:
    ///   - worldPoint: Point in world coordinate system
    ///   - cameraTransform: Camera's world transform matrix
    /// - Returns: Camera position as SCNVector3
    static func worldToCamera(worldPoint: SCNVector3, cameraTransform: simd_float4x4) -> SCNVector3 {
        let inverseCameraTransform = simd_inverse(cameraTransform)
        let worldPosition = simd_float4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0)
        let cameraPosition = inverseCameraTransform * worldPosition
        return SCNVector3(cameraPosition.x, cameraPosition.y, cameraPosition.z)
    }
    
    // MARK: - Distance Calculations
    
    /// Calculate Euclidean distance between two 3D points
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Distance in meters
    static func distance(from point1: SCNVector3, to point2: SCNVector3) -> Float {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        let dz = point2.z - point1.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    /// Calculate distance along a specific axis
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    ///   - axis: Axis to measure along (.x, .y, or .z)
    /// - Returns: Distance along the specified axis
    static func distance(from point1: SCNVector3, to point2: SCNVector3, along axis: Axis) -> Float {
        switch axis {
        case .x:
            return abs(point2.x - point1.x)
        case .y:
            return abs(point2.y - point1.y)
        case .z:
            return abs(point2.z - point1.z)
        }
    }
    
    /// Calculate horizontal distance (ignoring Y axis)
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Horizontal distance in meters
    static func horizontalDistance(from point1: SCNVector3, to point2: SCNVector3) -> Float {
        let dx = point2.x - point1.x
        let dz = point2.z - point1.z
        return sqrt(dx * dx + dz * dz)
    }
    
    /// Calculate vertical distance (Y axis only)
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Vertical distance in meters
    static func verticalDistance(from point1: SCNVector3, to point2: SCNVector3) -> Float {
        return abs(point2.y - point1.y)
    }
    
    // MARK: - Depth Information Integration
    
    /// Extract depth value at screen point from ARFrame
    /// - Parameters:
    ///   - screenPoint: Point in screen coordinates
    ///   - frame: Current ARFrame with depth data
    /// - Returns: Depth value in meters, or nil if depth data unavailable
    static func depth(at screenPoint: CGPoint, in frame: ARFrame) -> Float? {
        guard let depthData = frame.sceneDepth?.depthMap else {
            return nil
        }
        
        // Get depth map dimensions
        let depthWidth = CVPixelBufferGetWidth(depthData)
        let depthHeight = CVPixelBufferGetHeight(depthData)
        
        // Convert screen point to depth map coordinates
        let imageResolution = frame.camera.imageResolution
        let scaleX = CGFloat(depthWidth) / imageResolution.width
        let scaleY = CGFloat(depthHeight) / imageResolution.height
        
        let depthX = Int(screenPoint.x * scaleX)
        let depthY = Int(screenPoint.y * scaleY)
        
        // Bounds check
        guard depthX >= 0 && depthX < depthWidth && depthY >= 0 && depthY < depthHeight else {
            return nil
        }
        
        // Lock pixel buffer and read depth value
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthData) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthData)
        let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
        let index = depthY * (bytesPerRow / MemoryLayout<Float32>.stride) + depthX
        
        let depthValue = buffer[index]
        
        // Validate depth value
        guard depthValue.isFinite && depthValue > 0 else {
            return nil
        }
        
        return depthValue
    }
    
    /// Get world position using depth data
    /// - Parameters:
    ///   - screenPoint: Point in screen coordinates
    ///   - frame: Current ARFrame with depth data
    /// - Returns: World position as SCNVector3, or nil if depth unavailable
    static func worldPosition(at screenPoint: CGPoint, using frame: ARFrame) -> SCNVector3? {
        guard let depthValue = depth(at: screenPoint, in: frame) else {
            return nil
        }
        
        return screenToWorld(screenPoint: screenPoint, frame: frame, targetDistance: depthValue)
    }
    
    /// Calculate average depth in a region
    /// - Parameters:
    ///   - rect: Rectangle in screen coordinates
    ///   - frame: Current ARFrame with depth data
    /// - Returns: Average depth value in meters, or nil if unavailable
    static func averageDepth(in rect: CGRect, frame: ARFrame) -> Float? {
        guard let depthData = frame.sceneDepth?.depthMap else {
            return nil
        }
        
        let depthWidth = CVPixelBufferGetWidth(depthData)
        let depthHeight = CVPixelBufferGetHeight(depthData)
        let imageResolution = frame.camera.imageResolution
        
        let scaleX = CGFloat(depthWidth) / imageResolution.width
        let scaleY = CGFloat(depthHeight) / imageResolution.height
        
        let depthRect = CGRect(
            x: rect.origin.x * scaleX,
            y: rect.origin.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )
        
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthData) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthData)
        let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        var sum: Float = 0
        var count: Int = 0
        
        let minX = max(0, Int(depthRect.minX))
        let maxX = min(depthWidth - 1, Int(depthRect.maxX))
        let minY = max(0, Int(depthRect.minY))
        let maxY = min(depthHeight - 1, Int(depthRect.maxY))
        
        for y in minY...maxY {
            for x in minX...maxX {
                let index = y * (bytesPerRow / MemoryLayout<Float32>.stride) + x
                let depthValue = buffer[index]
                
                if depthValue.isFinite && depthValue > 0 {
                    sum += depthValue
                    count += 1
                }
            }
        }
        
        return count > 0 ? sum / Float(count) : nil
    }
    
    // MARK: - Vector Operations
    
    /// Calculate midpoint between two points
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Midpoint as SCNVector3
    static func midpoint(between point1: SCNVector3, and point2: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            (point1.x + point2.x) / 2,
            (point1.y + point2.y) / 2,
            (point1.z + point2.z) / 2
        )
    }
    
    /// Calculate direction vector from one point to another
    /// - Parameters:
    ///   - from: Starting point
    ///   - to: Ending point
    /// - Returns: Normalized direction vector
    static func direction(from: SCNVector3, to: SCNVector3) -> SCNVector3 {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let dz = to.z - from.z
        let length = sqrt(dx * dx + dy * dy + dz * dz)
        
        guard length > 0 else {
            return SCNVector3(0, 0, 0)
        }
        
        return SCNVector3(dx / length, dy / length, dz / length)
    }
    
    /// Calculate dot product of two vectors
    /// - Parameters:
    ///   - vector1: First vector
    ///   - vector2: Second vector
    /// - Returns: Dot product value
    static func dotProduct(_ vector1: SCNVector3, _ vector2: SCNVector3) -> Float {
        return vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z
    }
    
    /// Calculate cross product of two vectors
    /// - Parameters:
    ///   - vector1: First vector
    ///   - vector2: Second vector
    /// - Returns: Cross product vector
    static func crossProduct(_ vector1: SCNVector3, _ vector2: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            vector1.y * vector2.z - vector1.z * vector2.y,
            vector1.z * vector2.x - vector1.x * vector2.z,
            vector1.x * vector2.y - vector1.y * vector2.x
        )
    }
    
    // MARK: - Supporting Types
    
    enum Axis {
        case x, y, z
    }
}

// MARK: - SCNVector3 Extensions

extension SCNVector3 {
    /// Calculate length (magnitude) of the vector
    var length: Float {
        return sqrt(x * x + y * y + z * z)
    }
    
    /// Get normalized version of the vector
    var normalized: SCNVector3 {
        let len = length
        guard len > 0 else { return SCNVector3(0, 0, 0) }
        return SCNVector3(x / len, y / len, z / len)
    }
    
    /// Add two vectors
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    /// Subtract two vectors
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    /// Multiply vector by scalar
    static func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
    
    /// Divide vector by scalar
    static func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3(vector.x / scalar, vector.y / scalar, vector.z / scalar)
    }
}
