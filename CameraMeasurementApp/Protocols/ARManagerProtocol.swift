//
//  ARManagerProtocol.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import ARKit
import SceneKit

protocol ARManagerProtocol {
    func startARSession()
    func stopARSession()
    func measureDistance(from: SCNVector3, to: SCNVector3) -> Float
    func detectPlanes() -> [ARPlaneAnchor]
    func placeVirtualObject(at: SCNVector3, object: VirtualObject)
}

// Supporting types for AR functionality
struct VirtualObject {
    let id: UUID
    let modelName: String
    let scale: Float
    let position: SCNVector3
    
    init(id: UUID = UUID(), modelName: String, scale: Float = 1.0, position: SCNVector3) {
        self.id = id
        self.modelName = modelName
        self.scale = scale
        self.position = position
    }
}