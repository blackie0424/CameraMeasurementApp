//
//  MeasurementPoint.swift
//  CameraMeasurementApp
//
//  Manual AR Measurement - Measurement Point Model
//

import Foundation
import SceneKit

/// 測量點資料結構，記錄 3D 空間中的測量位置
struct MeasurementPoint {
    /// 3D 世界座標
    let position: SCNVector3
    
    /// 記錄時間
    let timestamp: Date
    
    /// Hit test 信心度（0-1）
    let confidence: Float
    
    /// 初始化測量點
    /// - Parameters:
    ///   - position: 3D 世界座標
    ///   - timestamp: 記錄時間，預設為當前時間
    ///   - confidence: Hit test 信心度，預設為 1.0
    init(position: SCNVector3, timestamp: Date = Date(), confidence: Float = 1.0) {
        self.position = position
        self.timestamp = timestamp
        self.confidence = confidence
    }
}
