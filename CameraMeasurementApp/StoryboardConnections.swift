//
//  StoryboardConnections.swift
//  CameraMeasurementApp
//
//  此檔案記錄所有 Storyboard 連接的識別碼，方便程式化導航時使用
//

import Foundation

/// Storyboard Segue 識別碼
enum SegueIdentifier {
    /// 從主畫面到測量結果頁面
    static let showResults = "showResults"
    
    /// 從主畫面到設定頁面
    static let showSettings = "showSettings"
}

/// Storyboard 識別碼
enum StoryboardID {
    /// 主要 Storyboard
    static let main = "Main"
    
    /// 視圖控制器識別碼
    enum ViewController {
        /// 測量結果視圖控制器
        static let results = "ResultsViewController"
        
        /// 設定視圖控制器
        static let settings = "SettingsViewController"
    }
}

/// IBOutlet 連接驗證
/// 此擴展提供編譯時期的連接驗證
extension ViewController {
    /// 驗證所有 IBOutlet 是否正確連接
    func validateOutlets() -> Bool {
        return arSceneView != nil &&
               captureButton != nil &&
               settingsButton != nil &&
               statusLabel != nil &&
               measurementOverlayView != nil &&
               guidanceLabel != nil
    }
}

extension ResultsViewController {
    /// 驗證所有 IBOutlet 是否正確連接
    func validateOutlets() -> Bool {
        return resultImageView != nil &&
               measurementOverlayView != nil &&
               referenceObjectView != nil &&
               measurementInfoView != nil &&
               objectNameLabel != nil &&
               dimensionsLabel != nil &&
               accuracyLabel != nil &&
               referenceObjectLabel != nil &&
               changeReferenceButton != nil &&
               saveButton != nil &&
               shareButton != nil &&
               retakeButton != nil
    }
}

extension SettingsViewController {
    /// 驗證所有 IBOutlet 是否正確連接
    func validateOutlets() -> Bool {
        return unitSegmentedControl != nil &&
               defaultReferenceTableView != nil &&
               showGuidanceSwitch != nil &&
               autoSaveSwitch != nil
    }
}
