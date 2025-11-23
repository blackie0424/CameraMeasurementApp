//
//  ARManager.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import ARKit
import SceneKit

class ARManager: NSObject, ARManagerProtocol {
    
    // MARK: - Properties
    
    private var arView: ARSCNView?
    private var session: ARSession?
    private var configuration: ARWorldTrackingConfiguration
    private var detectedPlanes: [UUID: ARPlaneAnchor] = [:]
    private var virtualObjects: [UUID: SCNNode] = [:]
    
    weak var delegate: ARManagerDelegate?
    
    // MARK: - Initialization
    
    override init() {
        self.configuration = ARWorldTrackingConfiguration()
        super.init()
        setupConfiguration()
    }
    
    convenience init(arView: ARSCNView) {
        self.init()
        self.arView = arView
        self.session = arView.session
        arView.delegate = self
        arView.session.delegate = self
    }
    
    // MARK: - Configuration
    
    private func setupConfiguration() {
        // Enable plane detection
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Enable environment texturing for better visual quality
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        // Enable automatic lighting estimation
        configuration.isLightEstimationEnabled = true
        
        // Set world alignment
        configuration.worldAlignment = .gravity
    }
    
    // MARK: - ARManagerProtocol Implementation
    
    func startARSession() {
        guard let session = session else {
            delegate?.arManager(self, didFailWithError: .arSessionFailed)
            return
        }
        
        // Reset tracking and remove existing anchors
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Clear detected planes
        detectedPlanes.removeAll()
        
        delegate?.arManagerDidStartSession(self)
    }
    
    func stopARSession() {
        session?.pause()
        delegate?.arManagerDidStopSession(self)
    }
    
    func measureDistance(from startPoint: SCNVector3, to endPoint: SCNVector3) -> Float {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let dz = endPoint.z - startPoint.z
        
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    func detectPlanes() -> [ARPlaneAnchor] {
        return Array(detectedPlanes.values)
    }
    
    func placeVirtualObject(at position: SCNVector3, object: VirtualObject) {
        guard let arView = arView else { return }
        
        // Create a node for the virtual object
        let node = createNodeForVirtualObject(object)
        node.position = position
        
        // Add to scene
        arView.scene.rootNode.addChildNode(node)
        
        // Store reference
        virtualObjects[object.id] = node
        
        delegate?.arManager(self, didPlaceVirtualObject: object, at: position)
    }
    
    // MARK: - Helper Methods
    
    private func createNodeForVirtualObject(_ object: VirtualObject) -> SCNNode {
        let node = SCNNode()
        
        // Create a simple geometry as placeholder
        // In production, this would load actual 3D models
        let geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        geometry.firstMaterial?.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.7)
        
        node.geometry = geometry
        node.scale = SCNVector3(object.scale, object.scale, object.scale)
        node.name = object.modelName
        
        return node
    }
    
    func removeVirtualObject(withId id: UUID) {
        if let node = virtualObjects[id] {
            node.removeFromParentNode()
            virtualObjects.removeValue(forKey: id)
        }
    }
    
    func removeAllVirtualObjects() {
        virtualObjects.values.forEach { $0.removeFromParentNode() }
        virtualObjects.removeAll()
    }
    
    // MARK: - Raycasting
    
    func raycast(at point: CGPoint) -> ARRaycastResult? {
        guard let arView = arView else { return nil }
        
        // Perform raycast against existing planes
        let query = arView.raycastQuery(from: point, allowing: .existingPlaneGeometry, alignment: .any)
        
        if let query = query {
            let results = arView.session.raycast(query)
            return results.first
        }
        
        return nil
    }
    
    func worldPosition(from screenPoint: CGPoint) -> SCNVector3? {
        guard let arView = arView else { return nil }
        
        // Try raycasting against existing planes first
        if let query = arView.raycastQuery(from: screenPoint, allowing: .existingPlaneGeometry, alignment: .any) {
            let results = arView.session.raycast(query)
            if let result = results.first {
                let transform = result.worldTransform
                return SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            }
        }
        
        // Fallback to estimated plane
        if let query = arView.raycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .horizontal) {
            let results = arView.session.raycast(query)
            if let result = results.first {
                let transform = result.worldTransform
                return SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            }
        }
        
        return nil
    }
    
    // MARK: - Session State
    
    var isSessionRunning: Bool {
        return session?.currentFrame != nil
    }
    
    func getCurrentFrame() -> ARFrame? {
        return session?.currentFrame
    }
    
    func resetTracking() {
        guard let session = session else { return }
        session.run(configuration, options: [.resetTracking])
    }
    
    // MARK: - Coordinate Transformation Methods
    
    /// Convert screen point to world coordinates using current AR frame
    /// - Parameters:
    ///   - screenPoint: Point in screen coordinate system
    ///   - useDepth: Whether to use depth data if available (default: true)
    /// - Returns: World position as SCNVector3, or nil if conversion fails
    func worldPosition(from screenPoint: CGPoint, useDepth: Bool = true) -> SCNVector3? {
        guard let frame = getCurrentFrame() else { return nil }
        
        // Try using depth data first if available and requested
        if useDepth, let worldPos = CoordinateTransformUtility.worldPosition(at: screenPoint, using: frame) {
            return worldPos
        }
        
        // Fallback to raycast-based positioning
        return worldPosition(from: screenPoint)
    }
    
    /// Convert world point to screen coordinates
    /// - Parameter worldPoint: Point in world coordinate system
    /// - Returns: Screen position as CGPoint, or nil if point is behind camera
    func screenPosition(from worldPoint: SCNVector3) -> CGPoint? {
        guard let frame = getCurrentFrame() else { return nil }
        return CoordinateTransformUtility.worldToScreen(worldPoint: worldPoint, frame: frame)
    }
    
    /// Get depth value at screen point
    /// - Parameter screenPoint: Point in screen coordinates
    /// - Returns: Depth value in meters, or nil if unavailable
    func depth(at screenPoint: CGPoint) -> Float? {
        guard let frame = getCurrentFrame() else { return nil }
        return CoordinateTransformUtility.depth(at: screenPoint, in: frame)
    }
    
    /// Get average depth in a rectangular region
    /// - Parameter rect: Rectangle in screen coordinates
    /// - Returns: Average depth value in meters, or nil if unavailable
    func averageDepth(in rect: CGRect) -> Float? {
        guard let frame = getCurrentFrame() else { return nil }
        return CoordinateTransformUtility.averageDepth(in: rect, frame: frame)
    }
    
    // MARK: - Advanced Distance Measurements
    
    /// Measure distance between two screen points using depth data
    /// - Parameters:
    ///   - point1: First screen point
    ///   - point2: Second screen point
    /// - Returns: Distance in meters, or nil if measurement fails
    func measureDistance(from point1: CGPoint, to point2: CGPoint) -> Float? {
        guard let worldPos1 = worldPosition(from: point1, useDepth: true),
              let worldPos2 = worldPosition(from: point2, useDepth: true) else {
            return nil
        }
        
        return measureDistance(from: worldPos1, to: worldPos2)
    }
    
    /// Measure horizontal distance between two points (ignoring height)
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Horizontal distance in meters
    func measureHorizontalDistance(from point1: SCNVector3, to point2: SCNVector3) -> Float {
        return CoordinateTransformUtility.horizontalDistance(from: point1, to: point2)
    }
    
    /// Measure vertical distance between two points (height only)
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Vertical distance in meters
    func measureVerticalDistance(from point1: SCNVector3, to point2: SCNVector3) -> Float {
        return CoordinateTransformUtility.verticalDistance(from: point1, to: point2)
    }
    
    /// Measure distance along a specific axis
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    ///   - axis: Axis to measure along
    /// - Returns: Distance along the specified axis
    func measureDistance(from point1: SCNVector3, to point2: SCNVector3, along axis: CoordinateTransformUtility.Axis) -> Float {
        return CoordinateTransformUtility.distance(from: point1, to: point2, along: axis)
    }
    
    /// Calculate midpoint between two 3D points
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Midpoint as SCNVector3
    func midpoint(between point1: SCNVector3, and point2: SCNVector3) -> SCNVector3 {
        return CoordinateTransformUtility.midpoint(between: point1, and: point2)
    }
    
    /// Get direction vector from one point to another
    /// - Parameters:
    ///   - from: Starting point
    ///   - to: Ending point
    /// - Returns: Normalized direction vector
    func direction(from: SCNVector3, to: SCNVector3) -> SCNVector3 {
        return CoordinateTransformUtility.direction(from: from, to: to)
    }
    
    // MARK: - Bounding Box Measurements
    
    /// Calculate dimensions of a bounding box in 3D space
    /// - Parameter boundingBox: Array of corner points defining the bounding box
    /// - Returns: Tuple containing width, height, and depth in meters
    func measureBoundingBox(_ boundingBox: [SCNVector3]) -> (width: Float, height: Float, depth: Float)? {
        guard boundingBox.count >= 2 else { return nil }
        
        var minX: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var minY: Float = .greatestFiniteMagnitude
        var maxY: Float = -.greatestFiniteMagnitude
        var minZ: Float = .greatestFiniteMagnitude
        var maxZ: Float = -.greatestFiniteMagnitude
        
        for point in boundingBox {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
            minZ = min(minZ, point.z)
            maxZ = max(maxZ, point.z)
        }
        
        let width = maxX - minX
        let height = maxY - minY
        let depth = maxZ - minZ
        
        return (width: width, height: height, depth: depth)
    }
    
    /// Measure dimensions of a rectangular region on screen using depth data
    /// - Parameter rect: Rectangle in screen coordinates
    /// - Returns: Estimated dimensions (width, height) in meters, or nil if measurement fails
    func measureScreenRegion(_ rect: CGRect) -> (width: Float, height: Float)? {
        guard let avgDepth = averageDepth(in: rect) else {
            return nil
        }
        
        // Get corner points
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        guard let worldTopLeft = CoordinateTransformUtility.screenToWorld(screenPoint: topLeft, frame: getCurrentFrame()!, targetDistance: avgDepth),
              let worldTopRight = CoordinateTransformUtility.screenToWorld(screenPoint: topRight, frame: getCurrentFrame()!, targetDistance: avgDepth),
              let worldBottomLeft = CoordinateTransformUtility.screenToWorld(screenPoint: bottomLeft, frame: getCurrentFrame()!, targetDistance: avgDepth) else {
            return nil
        }
        
        let width = CoordinateTransformUtility.distance(from: worldTopLeft, to: worldTopRight)
        let height = CoordinateTransformUtility.distance(from: worldTopLeft, to: worldBottomLeft)
        
        return (width: width, height: height)
    }
    
    // MARK: - Camera Information
    
    /// Get current camera position in world coordinates
    /// - Returns: Camera position as SCNVector3, or nil if unavailable
    func getCameraPosition() -> SCNVector3? {
        guard let frame = getCurrentFrame() else { return nil }
        let transform = frame.camera.transform
        return SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    /// Get current camera orientation (forward direction)
    /// - Returns: Forward direction vector, or nil if unavailable
    func getCameraDirection() -> SCNVector3? {
        guard let frame = getCurrentFrame() else { return nil }
        let transform = frame.camera.transform
        // Camera looks down negative Z axis
        let forward = simd_make_float3(transform * simd_float4(0, 0, -1, 0))
        return SCNVector3(forward.x, forward.y, forward.z)
    }
    
    /// Calculate distance from camera to a world point
    /// - Parameter worldPoint: Point in world coordinates
    /// - Returns: Distance in meters, or nil if camera position unavailable
    func distanceFromCamera(to worldPoint: SCNVector3) -> Float? {
        guard let cameraPos = getCameraPosition() else { return nil }
        return measureDistance(from: cameraPos, to: worldPoint)
    }
}

// MARK: - ARSCNViewDelegate

extension ARManager: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Store detected plane
        detectedPlanes[planeAnchor.identifier] = planeAnchor
        
        // Create visualization for the plane
        let planeNode = createPlaneNode(from: planeAnchor)
        node.addChildNode(planeNode)
        
        DispatchQueue.main.async {
            self.delegate?.arManager(self, didDetectPlane: planeAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Update stored plane
        detectedPlanes[planeAnchor.identifier] = planeAnchor
        
        // Update plane visualization
        if let planeNode = node.childNodes.first {
            updatePlaneNode(planeNode, from: planeAnchor)
        }
        
        DispatchQueue.main.async {
            self.delegate?.arManager(self, didUpdatePlane: planeAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Remove from storage
        detectedPlanes.removeValue(forKey: planeAnchor.identifier)
        
        DispatchQueue.main.async {
            self.delegate?.arManager(self, didRemovePlane: planeAnchor)
        }
    }
    
    private func createPlaneNode(from planeAnchor: ARPlaneAnchor) -> SCNNode {
        // Use planeGeometry for better representation
        let planeGeometry = planeAnchor.geometry
        let vertices = planeGeometry.vertices
        
        // Calculate dimensions from vertices
        var minX: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var minZ: Float = .greatestFiniteMagnitude
        var maxZ: Float = -.greatestFiniteMagnitude
        
        for i in 0..<vertices.count {
            let vertex = vertices[i]
            minX = min(minX, vertex.x)
            maxX = max(maxX, vertex.x)
            minZ = min(minZ, vertex.z)
            maxZ = max(maxZ, vertex.z)
        }
        
        let width = maxX - minX
        let height = maxZ - minZ
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        
        // Create semi-transparent material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.3)
        material.isDoubleSided = true
        plane.materials = [material]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Rotate to match horizontal plane
        planeNode.eulerAngles.x = -.pi / 2
        
        return planeNode
    }
    
    private func updatePlaneNode(_ node: SCNNode, from planeAnchor: ARPlaneAnchor) {
        guard let plane = node.geometry as? SCNPlane else { return }
        
        // Update plane dimensions using geometry
        let planeGeometry = planeAnchor.geometry
        let vertices = planeGeometry.vertices
        
        // Calculate dimensions from vertices
        var minX: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var minZ: Float = .greatestFiniteMagnitude
        var maxZ: Float = -.greatestFiniteMagnitude
        
        for i in 0..<vertices.count {
            let vertex = vertices[i]
            minX = min(minX, vertex.x)
            maxX = max(maxX, vertex.x)
            minZ = min(minZ, vertex.z)
            maxZ = max(maxZ, vertex.z)
        }
        
        let width = maxX - minX
        let height = maxZ - minZ
        
        plane.width = CGFloat(width)
        plane.height = CGFloat(height)
        
        // Update position
        node.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
    }
}

// MARK: - ARSessionDelegate

extension ARManager: ARSessionDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        delegate?.arManager(self, didFailWithError: .arSessionFailed)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        delegate?.arManagerSessionWasInterrupted(self)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        delegate?.arManagerSessionInterruptionEnded(self)
        
        // Restart session after interruption
        startARSession()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var trackingState: ARTrackingState
        
        switch camera.trackingState {
        case .normal:
            trackingState = .normal
        case .notAvailable:
            trackingState = .notAvailable
        case .limited(let reason):
            switch reason {
            case .initializing:
                trackingState = .limited(.initializing)
            case .excessiveMotion:
                trackingState = .limited(.excessiveMotion)
            case .insufficientFeatures:
                trackingState = .limited(.insufficientFeatures)
            case .relocalizing:
                trackingState = .limited(.relocalizing)
            @unknown default:
                trackingState = .limited(.insufficientFeatures)
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.arManager(self, didChangeTrackingState: trackingState)
        }
    }
}

// MARK: - ARManagerDelegate Protocol

protocol ARManagerDelegate: AnyObject {
    func arManagerDidStartSession(_ manager: ARManager)
    func arManagerDidStopSession(_ manager: ARManager)
    func arManager(_ manager: ARManager, didDetectPlane plane: ARPlaneAnchor)
    func arManager(_ manager: ARManager, didUpdatePlane plane: ARPlaneAnchor)
    func arManager(_ manager: ARManager, didRemovePlane plane: ARPlaneAnchor)
    func arManager(_ manager: ARManager, didPlaceVirtualObject object: VirtualObject, at position: SCNVector3)
    func arManager(_ manager: ARManager, didFailWithError error: MeasurementError)
    func arManager(_ manager: ARManager, didChangeTrackingState state: ARTrackingState)
    func arManagerSessionWasInterrupted(_ manager: ARManager)
    func arManagerSessionInterruptionEnded(_ manager: ARManager)
}

// MARK: - ARTrackingState

enum ARTrackingState {
    case normal
    case notAvailable
    case limited(ARTrackingLimitedReason)
}

enum ARTrackingLimitedReason {
    case initializing
    case excessiveMotion
    case insufficientFeatures
    case relocalizing
}
