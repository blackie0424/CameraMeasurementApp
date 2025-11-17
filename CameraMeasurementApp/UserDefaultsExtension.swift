//
//  UserDefaultsExtension.swift
//  CameraMeasurementApp
//
//  Created by Kiro on 2024-11-17.
//

import Foundation

// MARK: - Settings Change Notification
extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
    static let measurementUnitDidChange = Notification.Name("measurementUnitDidChange")
    static let referenceObjectDidChange = Notification.Name("referenceObjectDidChange")
}

// MARK: - Settings Manager
class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    private let notificationCenter = NotificationCenter.default
    
    private init() {
        // Initialize default values on first launch
        registerDefaultValues()
    }
    
    // MARK: - Default Values Registration
    private func registerDefaultValues() {
        let defaultValues: [String: Any] = [
            UserDefaults.Keys.measurementUnit: UserDefaults.MeasurementUnit.centimeters.rawValue,
            UserDefaults.Keys.defaultReferenceIndex: 0,
            UserDefaults.Keys.showGuidance: true,
            UserDefaults.Keys.autoSave: false,
            UserDefaults.Keys.hasLaunchedBefore: false,
            UserDefaults.Keys.hasSeenInitialGuidance: false,
            UserDefaults.Keys.showConfidenceIndicator: true,
            UserDefaults.Keys.enableHapticFeedback: true,
            UserDefaults.Keys.saveLocation: false
        ]
        
        defaults.register(defaults: defaultValues)
    }
    
    // MARK: - Settings Access
    var measurementUnit: UserDefaults.MeasurementUnit {
        get { defaults.measurementUnit }
        set {
            defaults.measurementUnit = newValue
            synchronize()
            notifyChange(.measurementUnitDidChange)
        }
    }
    
    var defaultReferenceIndex: Int {
        get { defaults.defaultReferenceIndex }
        set {
            defaults.defaultReferenceIndex = newValue
            synchronize()
            notifyChange(.referenceObjectDidChange)
        }
    }
    
    var shouldShowGuidance: Bool {
        get { defaults.shouldShowGuidance }
        set {
            defaults.shouldShowGuidance = newValue
            synchronize()
            notifyChange(.settingsDidChange)
        }
    }
    
    var shouldAutoSave: Bool {
        get { defaults.shouldAutoSave }
        set {
            defaults.shouldAutoSave = newValue
            synchronize()
            notifyChange(.settingsDidChange)
        }
    }
    
    var hasLaunchedBefore: Bool {
        get { defaults.hasLaunchedBefore }
        set {
            defaults.hasLaunchedBefore = newValue
            synchronize()
        }
    }
    
    var hasSeenInitialGuidance: Bool {
        get { defaults.hasSeenInitialGuidance }
        set {
            defaults.hasSeenInitialGuidance = newValue
            synchronize()
        }
    }
    
    var showConfidenceIndicator: Bool {
        get { defaults.showConfidenceIndicator }
        set {
            defaults.showConfidenceIndicator = newValue
            synchronize()
            notifyChange(.settingsDidChange)
        }
    }
    
    var enableHapticFeedback: Bool {
        get { defaults.enableHapticFeedback }
        set {
            defaults.enableHapticFeedback = newValue
            synchronize()
            notifyChange(.settingsDidChange)
        }
    }
    
    var saveLocation: Bool {
        get { defaults.saveLocation }
        set {
            defaults.saveLocation = newValue
            synchronize()
            notifyChange(.settingsDidChange)
        }
    }
    
    // MARK: - Synchronization
    private func synchronize() {
        defaults.synchronize()
    }
    
    private func notifyChange(_ notification: Notification.Name) {
        notificationCenter.post(name: notification, object: nil)
        notificationCenter.post(name: .settingsDidChange, object: nil)
    }
    
    // MARK: - Reset Functionality
    func resetToDefaults() {
        defaults.resetToDefaults()
        synchronize()
        notifyChange(.settingsDidChange)
    }
    
    func resetMeasurementSettings() {
        measurementUnit = .centimeters
        defaultReferenceIndex = 0
        synchronize()
        notifyChange(.settingsDidChange)
    }
    
    func resetUISettings() {
        shouldShowGuidance = true
        showConfidenceIndicator = true
        enableHapticFeedback = true
        synchronize()
        notifyChange(.settingsDidChange)
    }
    
    // MARK: - Export/Import Settings
    func exportSettings() -> [String: Any] {
        return [
            "measurementUnit": measurementUnit.rawValue,
            "defaultReferenceIndex": defaultReferenceIndex,
            "showGuidance": shouldShowGuidance,
            "autoSave": shouldAutoSave,
            "showConfidenceIndicator": showConfidenceIndicator,
            "enableHapticFeedback": enableHapticFeedback,
            "saveLocation": saveLocation
        ]
    }
    
    func importSettings(_ settings: [String: Any]) {
        if let unitRaw = settings["measurementUnit"] as? Int,
           let unit = UserDefaults.MeasurementUnit(rawValue: unitRaw) {
            measurementUnit = unit
        }
        
        if let refIndex = settings["defaultReferenceIndex"] as? Int {
            defaultReferenceIndex = refIndex
        }
        
        if let showGuidance = settings["showGuidance"] as? Bool {
            shouldShowGuidance = showGuidance
        }
        
        if let autoSave = settings["autoSave"] as? Bool {
            shouldAutoSave = autoSave
        }
        
        if let showConfidence = settings["showConfidenceIndicator"] as? Bool {
            showConfidenceIndicator = showConfidence
        }
        
        if let haptic = settings["enableHapticFeedback"] as? Bool {
            enableHapticFeedback = haptic
        }
        
        if let location = settings["saveLocation"] as? Bool {
            saveLocation = location
        }
        
        synchronize()
        notifyChange(.settingsDidChange)
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    
    // MARK: - Measurement Settings Keys
    fileprivate enum Keys {
        static let measurementUnit = "measurementUnit"
        static let defaultReferenceIndex = "defaultReferenceIndex"
        static let showGuidance = "showGuidance"
        static let autoSave = "autoSave"
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let hasSeenInitialGuidance = "hasSeenInitialGuidance"
        static let showConfidenceIndicator = "showConfidenceIndicator"
        static let enableHapticFeedback = "enableHapticFeedback"
        static let saveLocation = "saveLocation"
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
        
        func convert(_ value: Float) -> Float {
            switch self {
            case .centimeters:
                return value
            case .inches:
                return value / 2.54
            }
        }
    }
    
    // MARK: - Properties
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
            if object(forKey: Keys.autoSave) == nil {
                return false
            }
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
    
    var showConfidenceIndicator: Bool {
        get {
            if object(forKey: Keys.showConfidenceIndicator) == nil {
                return true
            }
            return bool(forKey: Keys.showConfidenceIndicator)
        }
        set {
            set(newValue, forKey: Keys.showConfidenceIndicator)
        }
    }
    
    var enableHapticFeedback: Bool {
        get {
            if object(forKey: Keys.enableHapticFeedback) == nil {
                return true
            }
            return bool(forKey: Keys.enableHapticFeedback)
        }
        set {
            set(newValue, forKey: Keys.enableHapticFeedback)
        }
    }
    
    var saveLocation: Bool {
        get {
            return bool(forKey: Keys.saveLocation)
        }
        set {
            set(newValue, forKey: Keys.saveLocation)
        }
    }
    
    // MARK: - Helper Methods
    func resetToDefaults() {
        measurementUnit = .centimeters
        defaultReferenceIndex = 0
        shouldShowGuidance = true
        shouldAutoSave = false
        showConfidenceIndicator = true
        enableHapticFeedback = true
        saveLocation = false
        synchronize()
    }
}
