//
//  PlaneInfo.swift
//  CameraMeasurementApp
//
//  Created for AR Plane Detection Accuracy feature
//

import Foundation
import ARKit

/// 平面類型枚舉
enum PlaneType {
    case horizontal
    case vertical
}

/// 平面資訊結構
/// 包含平面錨點和相關元數據
struct PlaneInfo {
    let anchor: ARPlaneAnchor
    let area: Float               // 平面面積（平方公尺）
    let type: PlaneType           // 水平或垂直
    let detectionTime: Date
    
    /// 判斷是否為水平平面
    var isHorizontal: Bool {
        return anchor.alignment == .horizontal
    }
    
    /// 判斷是否為垂直平面
    var isVertical: Bool {
        return anchor.alignment == .vertical
    }
}
