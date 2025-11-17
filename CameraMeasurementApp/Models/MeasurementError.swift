//
//  MeasurementError.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation

enum MeasurementError: Error {
    case arSessionFailed
    case insufficientLighting
    case objectTooFar
    case objectTooClose
    case noPlaneDetected
    case lowConfidenceDetection
    case calibrationRequired
    case cameraPermissionDenied
    case modelLoadingFailed
    case invalidImageData
    case networkError
    
    var localizedDescription: String {
        switch self {
        case .arSessionFailed:
            return "AR 會話初始化失敗，請重新啟動應用程式"
        case .insufficientLighting:
            return "光線不足，請移至光線充足的環境"
        case .objectTooFar:
            return "物體距離太遠，請靠近一些"
        case .objectTooClose:
            return "物體距離太近，請稍微遠離"
        case .noPlaneDetected:
            return "未檢測到平面，請移動裝置尋找平面"
        case .lowConfidenceDetection:
            return "物體識別信心度較低，建議手動校準"
        case .calibrationRequired:
            return "需要校準，請選擇參考物件"
        case .cameraPermissionDenied:
            return "需要相機權限才能使用測量功能"
        case .modelLoadingFailed:
            return "模型載入失敗，請檢查應用程式完整性"
        case .invalidImageData:
            return "無效的影像資料"
        case .networkError:
            return "網路連接錯誤"
        }
    }
    
    var recoveryAction: String {
        switch self {
        case .arSessionFailed:
            return "重新啟動"
        case .insufficientLighting:
            return "改善照明"
        case .objectTooFar:
            return "靠近物體"
        case .objectTooClose:
            return "遠離物體"
        case .noPlaneDetected:
            return "尋找平面"
        case .lowConfidenceDetection:
            return "手動校準"
        case .calibrationRequired:
            return "選擇參考物件"
        case .cameraPermissionDenied:
            return "開啟權限"
        case .modelLoadingFailed:
            return "重新安裝"
        case .invalidImageData:
            return "重新拍攝"
        case .networkError:
            return "檢查網路"
        }
    }
}