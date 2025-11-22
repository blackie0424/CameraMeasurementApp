//
//  AnchoredMeasurementPoint.swift
//  CameraMeasurementApp
//
//  Created for AR Plane Detection Accuracy feature
//

import Foundation
import ARKit
import SceneKit

/// 錨定測量點結構
/// 包含平面錨點引用和局部座標，確保測量點穩定性
/// 需求：4.1, 4.2, 4.3
struct AnchoredMeasurementPoint {
    let id: UUID
    let planeAnchor: ARPlaneAnchor
    let localPosition: simd_float3    // 相對於平面的局部座標
    let timestamp: Date
    
    /// 計算測量點的世界座標
    /// 使用平面錨點的 transform 矩陣將局部座標轉換為世界座標
    /// 這確保了當相機角度改變時，測量點保持在正確的 3D 位置
    /// 需求：4.2 - 相機角度改變時保持位置穩定
    /// 需求：4.3 - 使用 Plane Anchor 的座標系統計算位置
    func worldPosition() -> SCNVector3 {
        // 獲取平面錨點的世界座標變換矩陣
        let worldTransform = planeAnchor.transform
        
        // 將局部座標轉換為齊次座標（添加 w=1.0）
        let localPoint = simd_float4(localPosition.x, localPosition.y, localPosition.z, 1.0)
        
        // 使用變換矩陣計算世界座標
        let worldPoint = worldTransform * localPoint
        
        // 轉換為 SCNVector3 格式
        return SCNVector3(worldPoint.x, worldPoint.y, worldPoint.z)
    }
}
