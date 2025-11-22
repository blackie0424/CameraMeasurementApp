//
//  PlaneDetectionState.swift
//  CameraMeasurementApp
//
//  Created for AR Plane Detection Accuracy feature
//

import Foundation

/// 平面偵測狀態枚舉
/// 管理平面偵測流程的不同階段
enum PlaneDetectionState {
    case detecting              // 正在偵測平面
    case ready                  // 已偵測足夠平面，可開始測量
    case measurementMode        // 測量模式，平面已固定
}
