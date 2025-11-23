//
//  ReferenceObjectManagerProtocol.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import SceneKit

protocol ReferenceObjectManagerProtocol {
    func getAvailableObjects() -> [ReferenceObject]
    func selectBestReference(for measuredObject: DetectedObject) -> ReferenceObject
    func getReferenceModel(for object: ReferenceObject) -> SCNNode
}