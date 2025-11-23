//
//  MeasurementState.swift
//  CameraMeasurementApp
//
//  Manual AR Measurement - Core State Model
//

import Foundation
import SceneKit

/// 測量狀態枚舉，管理測量流程的不同階段
enum MeasurementState {
    /// 初始狀態：等待使用者記錄起點
    case initial
    
    /// 起點已記錄：等待使用者確認終點，同時顯示即時預覽
    case startPointRecorded(SCNVector3)
    
    /// 測量完成：顯示最終測量結果
    case measurementComplete(start: SCNVector3, end: SCNVector3, distance: Float)
}
