//
//  PlaneDetectionMeasurementResult.swift
//  CameraMeasurementApp
//
//  Created for AR Plane Detection Accuracy feature
//  需求：6.1, 6.2, 6.3, 6.4, 6.5
//

import Foundation
import SceneKit

/// 平面偵測測量結果結構
/// 使用錨定測量點確保距離計算基於穩定的 3D 座標
struct PlaneDetectionMeasurementResult {
    let startPoint: AnchoredMeasurementPoint
    let endPoint: AnchoredMeasurementPoint
    let distance: Float           // 單位：公尺
    
    /// 距離（單位：公分）
    /// 需求：6.5 - 轉換為公分單位
    var distanceInCm: Float {
        return distance * 100
    }
    
    /// 格式化的距離字串
    /// 需求：6.5 - 格式化為一位小數（例如 "45.3 cm"）
    var distanceFormatted: String {
        return String(format: "%.1f cm", distanceInCm)
    }
    
    /// 計算兩個錨定測量點之間的 3D 距離
    /// 使用歐幾里得距離公式：sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)
    /// 需求：6.1 - 使用 AR 世界座標系統中的 3D 位置
    /// 需求：6.2 - 使用歐幾里得距離公式
    /// 需求：6.3 - 考慮平面的實際方向和位置
    /// 需求：6.4 - 支援跨平面測量
    static func calculateDistance(from start: AnchoredMeasurementPoint, to end: AnchoredMeasurementPoint) -> Float {
        // 動態獲取當前世界座標
        // 這確保了即使平面更新，距離計算仍然準確
        let startWorld = start.worldPosition()
        let endWorld = end.worldPosition()
        
        // 計算 3D 歐幾里得距離
        let dx = endWorld.x - startWorld.x
        let dy = endWorld.y - startWorld.y
        let dz = endWorld.z - startWorld.z
        
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    /// 初始化測量結果
    /// 自動計算兩點之間的距離
    init(startPoint: AnchoredMeasurementPoint, endPoint: AnchoredMeasurementPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.distance = PlaneDetectionMeasurementResult.calculateDistance(from: startPoint, to: endPoint)
    }
    
    /// 初始化測量結果（用於測試）
    /// 允許指定自訂距離值
    init(startPoint: AnchoredMeasurementPoint, endPoint: AnchoredMeasurementPoint, distance: Float) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.distance = distance
    }
}
