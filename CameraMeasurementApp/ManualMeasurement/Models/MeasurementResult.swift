//
//  MeasurementResult.swift
//  CameraMeasurementApp
//
//  Manual AR Measurement - Measurement Result Model
//

import Foundation

/// 測量結果資料結構，包含起點、終點和計算的距離
struct MeasurementResult {
    /// 測量起點
    let startPoint: MeasurementPoint
    
    /// 測量終點
    let endPoint: MeasurementPoint
    
    /// 距離（單位：公尺）
    let distance: Float
    
    /// 距離（單位：公分）
    var distanceInCm: Float {
        return distance * 100
    }
    
    /// 格式化的距離字串（公分，保留一位小數）
    var formattedDistance: String {
        return String(format: "%.1f cm", distanceInCm)
    }
}
