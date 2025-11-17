//
//  UserDefaultsExtension.swift
//  CameraMeasurementApp
//
//  Created by Kiro on 2024-11-17.
//

import Foundation

extension UserDefaults {
    
    // MARK: - Measurement Settings Keys
    private enum Keys {
        static let measurementUnit = "measurementUnit"
        static let defaultReferenceIndex = "defaultReferenceIndex"
        static let showGuidance = "showGuidance"
        static let autoSave = "autoSave"
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let hasSeenInitialGuidance = "hasSeenInitialGuidance"
    }
    
    // MARK: - Measurement Unit
    enum MeasurementUnit: Int {
        case centimeters = 0
        case inches = 1
        
        var symbol: String {
            switch self {
            case .centimeters: return "cm"
            case .inches: return "inch"
            }
        }
        
        var name: String {
            switch self {
            case .centimeters: return "公分"
            case .inches: return "英吋"
            }
        }
    }
    
    var measurementUnit: MeasurementUnit {
        get {
            let rawValue = integer(forKey: Keys.measurementUnit)
            return MeasurementUnit(rawValue: rawValue) ?? .centimeters
        }
        set {
            set(newValue.rawValue, forKey: Keys.measurementUnit)
        }
    }
    
    var defaultReferenceIndex: Int {
        get {
            return integer(forKey: Keys.defaultReferenceIndex)
        }
        set {
            set(newValue, forKey: Keys.defaultReferenceIndex)
        }
    }
    
    var shouldShowGuidance: Bool {
        get {
            // Default to true if not set
            if object(forKey: Keys.showGuidance) == nil {
                return true
            }
            return bool(forKey: Keys.showGuidance)
        }
        set {
            set(newValue, forKey: Keys.showGuidance)
        }
    }
    
    var shouldAutoSave: Bool {
        get {
            return bool(forKey: Keys.autoSave)
        }
        set {
            set(newValue, forKey: Keys.autoSave)
        }
    }
    
    var hasLaunchedBefore: Bool {
        get {
            return bool(forKey: Keys.hasLaunchedBefore)
        }
        set {
            set(newValue, forKey: Keys.hasLaunchedBefore)
        }
    }
    
    var hasSeenInitialGuidance: Bool {
        get {
            return bool(forKey: Keys.hasSeenInitialGuidance)
        }
        set {
            set(newValue, forKey: Keys.hasSeenInitialGuidance)
        }
    }
    
    // MARK: - Helper Methods
    func resetToDefaults() {
        measurementUnit = .centimeters
        defaultReferenceIndex = 0
        shouldShowGuidance = true
        shouldAutoSave = false
        synchronize()
    }
}
