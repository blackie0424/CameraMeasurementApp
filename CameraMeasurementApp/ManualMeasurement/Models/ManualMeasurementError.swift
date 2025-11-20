//
//  ManualMeasurementError.swift
//  CameraMeasurementApp
//
//  Error types for manual AR measurement functionality
//

import Foundation

/// Errors that can occur during manual AR measurement operations
enum ManualMeasurementError: Error {
    /// AR Session failed to start or encountered a critical error
    case arSessionFailed
    
    /// Hit test failed to detect a valid surface or feature point
    case hitTestFailed
    
    /// Measurement point is invalid (e.g., too close, too far, or unreliable)
    case invalidMeasurementPoint
    
    /// AR tracking quality is insufficient for accurate measurements
    case insufficientTracking
}

extension ManualMeasurementError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .arSessionFailed:
            return "無法啟動 AR 功能，請檢查相機權限"
        case .hitTestFailed:
            return "請移動裝置以偵測表面"
        case .invalidMeasurementPoint:
            return "測量點無效，請確保距離在合理範圍內（1 公分 - 10 公尺）"
        case .insufficientTracking:
            return "追蹤品質不足，請改善光線或移動到特徵豐富的環境"
        }
    }
}
