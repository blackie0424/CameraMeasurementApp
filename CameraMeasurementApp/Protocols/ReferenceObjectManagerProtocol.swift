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

// Object category for grouping reference objects
enum ObjectCategory: String, CaseIterable {
    case electronics = "electronics"
    case everyday = "everyday"
    case currency = "currency"
    case stationery = "stationery"
    case furniture = "furniture"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .electronics: return "電子產品"
        case .everyday: return "日常用品"
        case .currency: return "貨幣"
        case .stationery: return "文具"
        case .furniture: return "家具"
        case .unknown: return "未知"
        }
    }
}