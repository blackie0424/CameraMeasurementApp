//
//  ObjectDetectorProtocol.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import Vision

protocol ObjectDetectorProtocol {
    func detectObjects(in image: UIImage) -> [DetectedObject]
    func classifyObject(_ object: DetectedObject) -> ObjectType
    func getBoundingBox(for object: DetectedObject) -> CGRect
}