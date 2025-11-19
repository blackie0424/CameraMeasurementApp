//
//  MeasurementFilter.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//  Task 28: 實作測量數值平滑演算法
//

import Foundation

/// Filter type for measurement smoothing
enum FilterType {
    case movingAverage
    case kalman
    case exponentialMovingAverage
}

/// Configuration for measurement filtering
struct MeasurementFilterConfiguration {
    /// Type of filter to use
    var filterType: FilterType = .movingAverage
    
    /// Window size for moving average (number of samples)
    var windowSize: Int = 5
    
    /// Alpha value for exponential moving average (0.0-1.0)
    /// Higher values give more weight to recent measurements
    var emaAlpha: Float = 0.3
    
    /// Process noise for Kalman filter
    var kalmanProcessNoise: Float = 0.01
    
    /// Measurement noise for Kalman filter
    var kalmanMeasurementNoise: Float = 0.1
    
    /// Outlier detection threshold (standard deviations)
    var outlierThreshold: Float = 2.5
    
    /// Whether to enable outlier detection
    var enableOutlierDetection: Bool = true
    
    /// Minimum number of samples before applying filter
    var minimumSamples: Int = 2
}

/// Measurement filter for smoothing dimension values and reducing jitter
class MeasurementFilter {
    
    // MARK: - Properties
    
    /// Filter configuration
    private var configuration: MeasurementFilterConfiguration
    
    /// Buffer of recent measurements
    private var measurementBuffer: [ObjectDimensions] = []
    
    /// Kalman filter states for each dimension
    private var kalmanFilters: DimensionKalmanFilters?
    
    /// Exponential moving average states
    private var emaStates: DimensionEMAStates?
    
    /// Statistics for outlier detection
    private var statistics: MeasurementStatistics = MeasurementStatistics()
    
    /// Number of measurements processed
    private(set) var measurementCount: Int = 0
    
    /// Number of outliers detected
    private(set) var outlierCount: Int = 0
    
    // MARK: - Initialization
    
    /// Initialize measurement filter
    /// - Parameter configuration: Filter configuration
    init(configuration: MeasurementFilterConfiguration = MeasurementFilterConfiguration()) {
        self.configuration = configuration
        
        // Initialize filter-specific states
        switch configuration.filterType {
        case .kalman:
            kalmanFilters = DimensionKalmanFilters(
                processNoise: configuration.kalmanProcessNoise,
                measurementNoise: configuration.kalmanMeasurementNoise
            )
        case .exponentialMovingAverage:
            emaStates = DimensionEMAStates()
        case .movingAverage:
            break // No special initialization needed
        }
    }
    
    // MARK: - Public Methods
    
    /// Add a new measurement and get filtered result
    /// - Parameter measurement: Raw measurement to filter
    /// - Returns: Filtered measurement, or original if insufficient data
    func filter(_ measurement: ObjectDimensions) -> ObjectDimensions {
        measurementCount += 1
        
        // Check for invalid measurement
        guard isValidMeasurement(measurement) else {
            print("⚠️ Invalid measurement detected, using last valid measurement")
            return getLastValidMeasurement() ?? measurement
        }
        
        // Detect and handle outliers
        if configuration.enableOutlierDetection && measurementBuffer.count >= configuration.minimumSamples {
            if isOutlier(measurement) {
                outlierCount += 1
                print("⚠️ Outlier detected: \(measurement.formattedDimensions())")
                
                // Return last valid measurement instead of outlier
                return getLastValidMeasurement() ?? measurement
            }
        }
        
        // Add to buffer
        measurementBuffer.append(measurement)
        
        // Trim buffer to window size
        if measurementBuffer.count > configuration.windowSize {
            measurementBuffer.removeFirst()
        }
        
        // Update statistics
        statistics.update(with: measurement)
        
        // Apply filter based on type
        let filtered: ObjectDimensions
        
        switch configuration.filterType {
        case .movingAverage:
            filtered = applyMovingAverage()
        case .kalman:
            filtered = applyKalmanFilter(measurement)
        case .exponentialMovingAverage:
            filtered = applyExponentialMovingAverage(measurement)
        }
        
        return filtered
    }
    
    /// Reset the filter state
    func reset() {
        measurementBuffer.removeAll()
        statistics = MeasurementStatistics()
        measurementCount = 0
        outlierCount = 0
        
        // Reset filter-specific states
        kalmanFilters?.reset()
        emaStates?.reset()
    }
    
    /// Update filter configuration
    /// - Parameter configuration: New configuration
    func updateConfiguration(_ configuration: MeasurementFilterConfiguration) {
        let typeChanged = self.configuration.filterType != configuration.filterType
        self.configuration = configuration
        
        // Reinitialize if filter type changed
        if typeChanged {
            reset()
            
            switch configuration.filterType {
            case .kalman:
                kalmanFilters = DimensionKalmanFilters(
                    processNoise: configuration.kalmanProcessNoise,
                    measurementNoise: configuration.kalmanMeasurementNoise
                )
            case .exponentialMovingAverage:
                emaStates = DimensionEMAStates()
            case .movingAverage:
                kalmanFilters = nil
                emaStates = nil
            }
        }
    }
    
    /// Get filter statistics
    /// - Returns: Current filter statistics
    func getStatistics() -> FilterStatistics {
        return FilterStatistics(
            measurementCount: measurementCount,
            outlierCount: outlierCount,
            outlierRate: measurementCount > 0 ? Float(outlierCount) / Float(measurementCount) : 0,
            bufferSize: measurementBuffer.count,
            averageDimensions: statistics.mean
        )
    }
    
    // MARK: - Private Methods - Validation
    
    /// Check if measurement is valid
    /// - Parameter measurement: Measurement to validate
    /// - Returns: True if valid, false otherwise
    private func isValidMeasurement(_ measurement: ObjectDimensions) -> Bool {
        // Check for NaN or infinite values
        guard measurement.length.isFinite && measurement.length > 0,
              measurement.width.isFinite && measurement.width > 0,
              measurement.height.isFinite && measurement.height > 0 else {
            return false
        }
        
        // Check for unreasonable values (e.g., > 10 meters)
        let maxDimension: Float = 1000.0 // 10 meters in cm
        guard measurement.length < maxDimension,
              measurement.width < maxDimension,
              measurement.height < maxDimension else {
            return false
        }
        
        return true
    }
    
    /// Check if measurement is an outlier
    /// - Parameter measurement: Measurement to check
    /// - Returns: True if outlier, false otherwise
    private func isOutlier(_ measurement: ObjectDimensions) -> Bool {
        guard let mean = statistics.mean,
              let stdDev = statistics.standardDeviation else {
            return false
        }
        
        // Check each dimension
        let lengthZScore = abs(measurement.length - mean.length) / stdDev.length
        let widthZScore = abs(measurement.width - mean.width) / stdDev.width
        let heightZScore = abs(measurement.height - mean.height) / stdDev.height
        
        // Consider outlier if any dimension exceeds threshold
        let threshold = configuration.outlierThreshold
        return lengthZScore > threshold || widthZScore > threshold || heightZScore > threshold
    }
    
    /// Get last valid measurement from buffer
    /// - Returns: Last valid measurement, or nil if buffer is empty
    private func getLastValidMeasurement() -> ObjectDimensions? {
        return measurementBuffer.last
    }
    
    // MARK: - Private Methods - Filtering Algorithms
    
    /// Apply moving average filter
    /// - Returns: Averaged measurement
    private func applyMovingAverage() -> ObjectDimensions {
        guard !measurementBuffer.isEmpty else {
            return ObjectDimensions(length: 0, width: 0, height: 0, accuracy: 0)
        }
        
        let count = Float(measurementBuffer.count)
        
        let avgLength = measurementBuffer.reduce(0) { $0 + $1.length } / count
        let avgWidth = measurementBuffer.reduce(0) { $0 + $1.width } / count
        let avgHeight = measurementBuffer.reduce(0) { $0 + $1.height } / count
        let avgAccuracy = measurementBuffer.reduce(0) { $0 + $1.accuracy } / count
        
        return ObjectDimensions(
            length: avgLength,
            width: avgWidth,
            height: avgHeight,
            accuracy: avgAccuracy,
            measurementDate: Date()
        )
    }
    
    /// Apply Kalman filter
    /// - Parameter measurement: New measurement
    /// - Returns: Filtered measurement
    private func applyKalmanFilter(_ measurement: ObjectDimensions) -> ObjectDimensions {
        guard let filters = kalmanFilters else {
            return measurement
        }
        
        let filteredLength = filters.lengthFilter.update(measurement: measurement.length)
        let filteredWidth = filters.widthFilter.update(measurement: measurement.width)
        let filteredHeight = filters.heightFilter.update(measurement: measurement.height)
        
        return ObjectDimensions(
            length: filteredLength,
            width: filteredWidth,
            height: filteredHeight,
            accuracy: measurement.accuracy,
            measurementDate: Date()
        )
    }
    
    /// Apply exponential moving average filter
    /// - Parameter measurement: New measurement
    /// - Returns: Filtered measurement
    private func applyExponentialMovingAverage(_ measurement: ObjectDimensions) -> ObjectDimensions {
        guard let states = emaStates else {
            return measurement
        }
        
        let alpha = configuration.emaAlpha
        
        // Initialize if first measurement
        if !states.isInitialized {
            states.length = measurement.length
            states.width = measurement.width
            states.height = measurement.height
            states.isInitialized = true
            return measurement
        }
        
        // Apply EMA: S_t = α * Y_t + (1 - α) * S_{t-1}
        states.length = alpha * measurement.length + (1 - alpha) * states.length
        states.width = alpha * measurement.width + (1 - alpha) * states.width
        states.height = alpha * measurement.height + (1 - alpha) * states.height
        
        return ObjectDimensions(
            length: states.length,
            width: states.width,
            height: states.height,
            accuracy: measurement.accuracy,
            measurementDate: Date()
        )
    }
}

// MARK: - Supporting Types

/// Kalman filter for a single dimension
class KalmanFilter {
    
    // State variables
    private var estimate: Float = 0.0
    private var errorCovariance: Float = 1.0
    
    // Configuration
    private let processNoise: Float
    private let measurementNoise: Float
    
    // Initialization flag
    private var isInitialized: Bool = false
    
    init(processNoise: Float, measurementNoise: Float) {
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
    }
    
    func update(measurement: Float) -> Float {
        if !isInitialized {
            estimate = measurement
            isInitialized = true
            return measurement
        }
        
        // Prediction step
        let predictedEstimate = estimate
        let predictedErrorCovariance = errorCovariance + processNoise
        
        // Update step
        let kalmanGain = predictedErrorCovariance / (predictedErrorCovariance + measurementNoise)
        estimate = predictedEstimate + kalmanGain * (measurement - predictedEstimate)
        errorCovariance = (1 - kalmanGain) * predictedErrorCovariance
        
        return estimate
    }
    
    func reset() {
        estimate = 0.0
        errorCovariance = 1.0
        isInitialized = false
    }
}

/// Kalman filters for all three dimensions
class DimensionKalmanFilters {
    let lengthFilter: KalmanFilter
    let widthFilter: KalmanFilter
    let heightFilter: KalmanFilter
    
    init(processNoise: Float, measurementNoise: Float) {
        lengthFilter = KalmanFilter(processNoise: processNoise, measurementNoise: measurementNoise)
        widthFilter = KalmanFilter(processNoise: processNoise, measurementNoise: measurementNoise)
        heightFilter = KalmanFilter(processNoise: processNoise, measurementNoise: measurementNoise)
    }
    
    func reset() {
        lengthFilter.reset()
        widthFilter.reset()
        heightFilter.reset()
    }
}

/// EMA states for all three dimensions
class DimensionEMAStates {
    var length: Float = 0.0
    var width: Float = 0.0
    var height: Float = 0.0
    var isInitialized: Bool = false
    
    func reset() {
        length = 0.0
        width = 0.0
        height = 0.0
        isInitialized = false
    }
}

/// Statistics for measurements
struct MeasurementStatistics {
    private var sumLength: Float = 0.0
    private var sumWidth: Float = 0.0
    private var sumHeight: Float = 0.0
    
    private var sumSquaredLength: Float = 0.0
    private var sumSquaredWidth: Float = 0.0
    private var sumSquaredHeight: Float = 0.0
    
    private var count: Int = 0
    
    var mean: ObjectDimensions? {
        guard count > 0 else { return nil }
        let n = Float(count)
        return ObjectDimensions(
            length: sumLength / n,
            width: sumWidth / n,
            height: sumHeight / n,
            accuracy: 1.0
        )
    }
    
    var standardDeviation: ObjectDimensions? {
        guard count > 1 else { return nil }
        let n = Float(count)
        
        let meanLength = sumLength / n
        let meanWidth = sumWidth / n
        let meanHeight = sumHeight / n
        
        let varianceLength = (sumSquaredLength / n) - (meanLength * meanLength)
        let varianceWidth = (sumSquaredWidth / n) - (meanWidth * meanWidth)
        let varianceHeight = (sumSquaredHeight / n) - (meanHeight * meanHeight)
        
        return ObjectDimensions(
            length: sqrt(max(0, varianceLength)),
            width: sqrt(max(0, varianceWidth)),
            height: sqrt(max(0, varianceHeight)),
            accuracy: 1.0
        )
    }
    
    mutating func update(with measurement: ObjectDimensions) {
        sumLength += measurement.length
        sumWidth += measurement.width
        sumHeight += measurement.height
        
        sumSquaredLength += measurement.length * measurement.length
        sumSquaredWidth += measurement.width * measurement.width
        sumSquaredHeight += measurement.height * measurement.height
        
        count += 1
    }
}

/// Statistics about filter performance
struct FilterStatistics {
    let measurementCount: Int
    let outlierCount: Int
    let outlierRate: Float
    let bufferSize: Int
    let averageDimensions: ObjectDimensions?
    
    func printSummary() {
        print("📊 Filter Statistics:")
        print("   Measurements processed: \(measurementCount)")
        print("   Outliers detected: \(outlierCount)")
        print("   Outlier rate: \(String(format: "%.1f%%", outlierRate * 100))")
        print("   Buffer size: \(bufferSize)")
        if let avg = averageDimensions {
            print("   Average dimensions: \(avg.formattedDimensions())")
        }
    }
}
