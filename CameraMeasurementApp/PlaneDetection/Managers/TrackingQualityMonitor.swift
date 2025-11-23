//
//  TrackingQualityMonitor.swift
//  CameraMeasurementApp
//
//  Created for AR Plane Detection Accuracy feature
//

import Foundation
import ARKit

/// 追蹤品質等級
enum TrackingQuality {
    case normal
    case limited(ARCamera.TrackingState.Reason)
    case notAvailable
}

/// 監控 AR 追蹤品質並提供警告
/// 負責判斷是否允許測量並生成適當的警告訊息
class TrackingQualityMonitor {
    
    // MARK: - Properties
    
    /// 當前追蹤品質
    private(set) var currentQuality: TrackingQuality = .notAvailable
    
    /// 品質變更回調
    var onQualityChanged: ((TrackingQuality) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        self.currentQuality = .notAvailable
    }
    
    // MARK: - Tracking State Management
    
    /// 更新追蹤狀態
    /// - Parameter camera: ARCamera 實例
    func updateTrackingState(_ camera: ARCamera) {
        let newQuality = mapTrackingStateToQuality(camera.trackingState)
        
        // 只在品質改變時觸發回調
        if !areQualitiesEqual(currentQuality, newQuality) {
            currentQuality = newQuality
            onQualityChanged?(newQuality)
        }
    }
    
    /// 將 ARCamera.TrackingState 映射到 TrackingQuality
    /// - Parameter trackingState: ARCamera 的追蹤狀態
    /// - Returns: 對應的追蹤品質等級
    private func mapTrackingStateToQuality(_ trackingState: ARCamera.TrackingState) -> TrackingQuality {
        switch trackingState {
        case .normal:
            return .normal
        case .limited(let reason):
            return .limited(reason)
        case .notAvailable:
            return .notAvailable
        }
    }
    
    /// 比較兩個 TrackingQuality 是否相等
    /// - Parameters:
    ///   - lhs: 左側品質
    ///   - rhs: 右側品質
    /// - Returns: 是否相等
    private func areQualitiesEqual(_ lhs: TrackingQuality, _ rhs: TrackingQuality) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal):
            return true
        case (.notAvailable, .notAvailable):
            return true
        case (.limited(let reason1), .limited(let reason2)):
            return reason1 == reason2
        default:
            return false
        }
    }
    
    // MARK: - Measurement Permission
    
    /// 判斷是否允許測量
    /// 只有在追蹤品質為 normal 時才允許測量
    /// - Returns: 是否允許測量
    func isMeasurementAllowed() -> Bool {
        switch currentQuality {
        case .normal:
            return true
        case .limited, .notAvailable:
            return false
        }
    }
    
    // MARK: - Warning Messages
    
    /// 獲取警告訊息
    /// 根據當前追蹤品質生成適當的警告訊息
    /// - Returns: 警告訊息，如果品質正常則返回 nil
    func getWarningMessage() -> String? {
        switch currentQuality {
        case .normal:
            return nil
            
        case .limited(let reason):
            return getMessageForLimitedReason(reason)
            
        case .notAvailable:
            return "追蹤不可用，請重新啟動 AR Session"
        }
    }
    
    /// 根據 limited 原因生成具體的警告訊息
    /// - Parameter reason: 追蹤受限的原因
    /// - Returns: 對應的警告訊息
    private func getMessageForLimitedReason(_ reason: ARCamera.TrackingState.Reason) -> String {
        switch reason {
        case .excessiveMotion:
            return "追蹤品質不佳，請減慢移動速度"
            
        case .insufficientFeatures:
            return "追蹤品質不佳，請移動到特徵豐富的環境"
            
        case .initializing:
            return "正在初始化追蹤，請稍候"
            
        case .relocalizing:
            return "正在重新定位，請稍候"
            
        @unknown default:
            return "追蹤品質不佳，請改善光線或移動到特徵豐富的環境"
        }
    }
}
