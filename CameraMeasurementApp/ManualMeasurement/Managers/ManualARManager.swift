//
//  ManualARManager.swift
//  CameraMeasurementApp
//
//  Created for Manual AR Measurement Feature
//

import Foundation
import ARKit
import SceneKit

/// Manages ARKit functionality for manual measurement feature
/// Handles AR session configuration, hit testing, and coordinate transformations
class ManualARManager {
    
    // MARK: - Properties
    
    var arSession: ARSession
    private weak var sceneView: ARSCNView?
    
    // MARK: - Initialization
    
    /// Initialize the AR manager with an AR session and scene view
    /// - Parameters:
    ///   - session: The ARSession to manage
    ///   - sceneView: The ARSCNView for rendering
    init(session: ARSession, sceneView: ARSCNView) {
        print("🔧 ManualARManager: Initializing...")
        self.arSession = session
        self.sceneView = sceneView
        print("✅ ManualARManager: Initialized with session and scene view")
    }
    
    // MARK: - AR Session Management
    
    /// Start the AR session with world tracking configuration
    /// Enables horizontal and vertical plane detection
    /// 需求: 2.1, 2.2
    func startSession() {
        print("🚀 ManualARManager: Starting AR session...")
        
        // Check if ARWorldTrackingConfiguration is supported
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ ManualARManager: ARWorldTrackingConfiguration not supported on this device")
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = true
        
        // Enable additional features for better tracking
        if #available(iOS 13.0, *) {
            configuration.frameSemantics = .sceneDepth
        }
        
        print("✅ ManualARManager: Configuration created")
        print("   - Plane detection: horizontal, vertical")
        print("   - Light estimation: enabled")
        
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("✅ ManualARManager: AR session started")
    }
    
    /// Start the AR session with a custom configuration
    /// - Parameter configuration: The ARWorldTrackingConfiguration to use
    func startSession(with configuration: ARWorldTrackingConfiguration) {
        print("🚀 ManualARManager: Starting AR session with custom configuration...")
        
        // Check if ARWorldTrackingConfiguration is supported
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ ManualARManager: ARWorldTrackingConfiguration not supported on this device")
            return
        }
        
        print("✅ ManualARManager: Running session with custom configuration")
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("✅ ManualARManager: AR session started")
    }
    
    /// Pause the AR session
    func pauseSession() {
        print("⏸️ ManualARManager: Pausing AR session")
        arSession.pause()
    }
    
    /// Reset the AR session (clear all tracking data)
    func resetSession() {
        print("🔄 ManualARManager: Resetting AR session")
        
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ ManualARManager: Cannot reset - ARWorldTrackingConfiguration not supported")
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = true
        
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("✅ ManualARManager: AR session reset complete")
    }
    
    // MARK: - Hit Testing
    
    /// Perform hit test from screen point to 3D world using raycast (iOS 13+)
    /// Priority: existingPlaneGeometry > estimatedPlane > featurePoint
    /// - Parameter point: Screen coordinate point (typically screen center)
    /// - Returns: ARHitTestResult if successful, nil otherwise
    /// 需求: 2.1, 2.2, 3.1, 4.1
    func performHitTest(at point: CGPoint) -> ARHitTestResult? {
        guard let sceneView = sceneView else { return nil }
        guard let currentFrame = arSession.currentFrame else { return nil }
        
        // Use raycast for iOS 13+ (more accurate and recommended)
        if #available(iOS 13.0, *) {
            // Try raycast against existing planes first
            let raycastQuery = sceneView.raycastQuery(from: point, allowing: .existingPlaneGeometry, alignment: .any)
            if let query = raycastQuery {
                let results = arSession.raycast(query)
                if let firstResult = results.first {
                    // Convert ARRaycastResult to ARHitTestResult format
                    return convertRaycastToHitTest(firstResult)
                }
            }
            
            // Fallback to estimated plane
            let estimatedQuery = sceneView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .any)
            if let query = estimatedQuery {
                let results = arSession.raycast(query)
                if let firstResult = results.first {
                    return convertRaycastToHitTest(firstResult)
                }
            }
        }
        
        // Fallback to legacy hit test for older iOS or if raycast fails
        let planeHitTestResults = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
        if let planeResult = planeHitTestResults.first {
            return planeResult
        }
        
        // Last resort: feature points
        let featurePointResults = sceneView.hitTest(point, types: .featurePoint)
        return featurePointResults.first
    }
    
    /// Convert ARRaycastResult to ARHitTestResult format (for compatibility)
    @available(iOS 13.0, *)
    private func convertRaycastToHitTest(_ raycastResult: ARRaycastResult) -> ARHitTestResult? {
        // Create a mock ARHitTestResult with the raycast data
        // Note: This is a workaround since we can't directly create ARHitTestResult
        // We'll use the worldTransform from the raycast result
        
        // For now, we'll perform a hit test at the same location to get a proper ARHitTestResult
        // This is a known limitation when mixing raycast and hit test APIs
        guard let sceneView = sceneView else { return nil }
        
        // Get the screen point from the raycast result's world position
        let worldPosition = raycastResult.worldTransform.columns.3
        let scnPosition = SCNVector3(worldPosition.x, worldPosition.y, worldPosition.z)
        let screenPoint = sceneView.projectPoint(scnPosition)
        let point2D = CGPoint(x: CGFloat(screenPoint.x), y: CGFloat(screenPoint.y))
        
        // Perform hit test at that point
        let hitResults = sceneView.hitTest(point2D, types: [.existingPlaneUsingExtent, .featurePoint])
        return hitResults.first
    }
    
    // MARK: - Coordinate Transformation
    
    /// Extract world position from hit test result
    /// - Parameter hitResult: The ARHitTestResult from hit testing
    /// - Returns: 3D world position as SCNVector3
    /// 需求: 2.2, 3.1, 4.1
    func worldPosition(from hitResult: ARHitTestResult) -> SCNVector3 {
        let transform = hitResult.worldTransform
        let position = SCNVector3(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
        return position
    }
    
    /// Check if AR session is ready for measurements
    /// - Returns: true if tracking is normal and session is running
    func isSessionReady() -> Bool {
        guard let frame = arSession.currentFrame else { return false }
        
        switch frame.camera.trackingState {
        case .normal:
            return true
        case .limited, .notAvailable:
            return false
        }
    }
    
    /// Get detailed tracking state information
    /// - Returns: Human-readable tracking state description
    func getTrackingStateDescription() -> String {
        guard let frame = arSession.currentFrame else {
            return "無法取得追蹤狀態"
        }
        
        switch frame.camera.trackingState {
        case .normal:
            return "追蹤正常"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "移動過快"
            case .insufficientFeatures:
                return "特徵點不足"
            case .initializing:
                return "正在初始化"
            case .relocalizing:
                return "正在重新定位"
            @unknown default:
                return "追蹤受限"
            }
        case .notAvailable:
            return "追蹤不可用"
        }
    }
    
    /// Get current tracking state
    /// - Returns: Current ARCamera.TrackingState
    var trackingState: ARCamera.TrackingState? {
        return arSession.currentFrame?.camera.trackingState
    }
    
    // MARK: - Plane-Specific Hit Testing
    
    /// Perform hit test prioritizing detected planes
    /// Only uses existingPlaneUsingExtent type to ensure measurement points are on known planes
    /// - Parameter screenPoint: Screen coordinate point
    /// - Returns: Tuple of hit result and corresponding ARPlaneAnchor, or nil if no plane hit
    /// 需求: 3.1, 3.2
    func performHitTestOnPlanes(at screenPoint: CGPoint) -> (result: ARHitTestResult, anchor: ARPlaneAnchor)? {
        guard let sceneView = sceneView else { return nil }
        
        // Only check for existing planes using extent
        // This ensures we only place measurement points on detected, stable planes
        let results = sceneView.hitTest(screenPoint, types: .existingPlaneUsingExtent)
        
        // Find the first result that has an ARPlaneAnchor
        for result in results {
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                return (result, planeAnchor)
            }
        }
        
        // No plane was hit
        return nil
    }
    
    /// Get plane anchor from a hit test result
    /// - Parameter hitResult: The ARHitTestResult to extract plane anchor from
    /// - Returns: ARPlaneAnchor if the hit result is associated with a plane, nil otherwise
    func getPlaneAnchor(for hitResult: ARHitTestResult) -> ARPlaneAnchor? {
        return hitResult.anchor as? ARPlaneAnchor
    }
    
    // MARK: - Anchored Measurement Points
    
    /// Create an anchored measurement point on a plane
    /// Converts world coordinates to plane local coordinates using inverse transform
    /// - Parameters:
    ///   - anchor: The ARPlaneAnchor to anchor the point to
    ///   - hitResult: The hit test result containing world position
    /// - Returns: AnchoredMeasurementPoint with plane reference and local coordinates
    /// 需求: 4.1, 4.3
    func createAnchoredPoint(on anchor: ARPlaneAnchor, at hitResult: ARHitTestResult) -> AnchoredMeasurementPoint {
        // Get world position from hit test result
        let worldTransform = hitResult.worldTransform
        let worldPosition = simd_float4(
            worldTransform.columns.3.x,
            worldTransform.columns.3.y,
            worldTransform.columns.3.z,
            1.0
        )
        
        // Get plane's transform and calculate inverse
        let planeTransform = anchor.transform
        let planeInverse = simd_inverse(planeTransform)
        
        // Convert world position to plane local coordinates
        let localPosition4 = planeInverse * worldPosition
        let localPosition = simd_float3(localPosition4.x, localPosition4.y, localPosition4.z)
        
        // Create and return anchored measurement point
        return AnchoredMeasurementPoint(
            id: UUID(),
            planeAnchor: anchor,
            localPosition: localPosition,
            timestamp: Date()
        )
    }
    
    /// Calculate world position from a plane anchor and local coordinates
    /// - Parameters:
    ///   - anchor: The ARPlaneAnchor
    ///   - localPoint: Local coordinates relative to the plane
    /// - Returns: World position as SCNVector3
    func worldPosition(from anchor: ARPlaneAnchor, localPoint: simd_float3) -> SCNVector3 {
        // Get plane's world transform
        let worldTransform = anchor.transform
        
        // Convert local coordinates to homogeneous coordinates
        let localPoint4 = simd_float4(localPoint.x, localPoint.y, localPoint.z, 1.0)
        
        // Transform to world coordinates
        let worldPoint = worldTransform * localPoint4
        
        return SCNVector3(worldPoint.x, worldPoint.y, worldPoint.z)
    }
}
