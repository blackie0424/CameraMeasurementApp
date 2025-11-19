//
//  RealtimeMeasurementManager.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//  Task 27: 實作 RealtimeMeasurementManager
//

import Foundation
import ARKit
import UIKit

/// Manager for real-time measurement processing
/// Integrates ObjectDetector and MeasurementCalculator with frame throttling
/// to provide continuous measurement updates at 5-10 Hz
class RealtimeMeasurementManager {
    
    // MARK: - Properties
    
    /// Frame throttler for controlling processing frequency
    private let frameThrottler: FrameThrottler
    
    /// Object detector for identifying objects in frames
    private let objectDetector: ObjectDetectorProtocol
    
    /// Measurement calculator for computing dimensions
    private let measurementCalculator: MeasurementCalculatorProtocol
    
    /// Queue for asynchronous measurement processing
    private let measurementQueue: DispatchQueue
    
    /// Whether real-time measurement is currently active
    private(set) var isActive: Bool = false
    
    /// Last successful measurement result (cached)
    private var lastMeasurement: RealtimeMeasurementResult?
    
    /// Measurement smoothing filter
    private var measurementFilter: MeasurementFilter?
    
    /// Update handler callback
    private var updateHandler: ((RealtimeMeasurementResult) -> Void)?
    
    /// Error handler callback
    private var errorHandler: ((MeasurementError) -> Void)?
    
    /// Configuration for real-time measurement
    private var configuration: RealtimeMeasurementConfiguration
    
    /// Statistics tracking
    private var statistics = RealtimeMeasurementStatistics()
    
    // MARK: - Initialization
    
    /// Initialize real-time measurement manager
    /// - Parameters:
    ///   - targetFPS: Target frames per second for processing (default: 10)
    ///   - objectDetector: Object detector instance (optional, creates new if nil)
    ///   - measurementCalculator: Measurement calculator instance (optional, creates new if nil)
    ///   - configuration: Configuration for real-time measurement
    init(
        targetFPS: Double = 10.0,
        objectDetector: ObjectDetectorProtocol? = nil,
        measurementCalculator: MeasurementCalculatorProtocol? = nil,
        configuration: RealtimeMeasurementConfiguration = RealtimeMeasurementConfiguration()
    ) {
        self.frameThrottler = FrameThrottler(targetFPS: targetFPS)
        self.objectDetector = objectDetector ?? ObjectDetector()
        self.measurementCalculator = measurementCalculator ?? MeasurementCalculator()
        self.configuration = configuration
        
        // Create high-priority queue for measurement processing
        self.measurementQueue = DispatchQueue(
            label: "com.camerameasurement.realtimeMeasurement",
            qos: .userInitiated
        )
        
        // Initialize measurement filter if enabled
        if configuration.enableSmoothing {
            var filterConfig = MeasurementFilterConfiguration()
            filterConfig.filterType = configuration.filterType
            filterConfig.windowSize = configuration.smoothingWindowSize
            filterConfig.enableOutlierDetection = configuration.enableOutlierDetection
            filterConfig.outlierThreshold = configuration.outlierThreshold
            
            self.measurementFilter = MeasurementFilter(configuration: filterConfig)
        }
    }
    
    // MARK: - Public Methods
    
    /// Start real-time measurement
    /// - Parameters:
    ///   - updateHandler: Callback for measurement updates
    ///   - errorHandler: Callback for errors (optional)
    func startRealtimeMeasurement(
        updateHandler: @escaping (RealtimeMeasurementResult) -> Void,
        errorHandler: ((MeasurementError) -> Void)? = nil
    ) {
        guard !isActive else {
            print("⚠️ Real-time measurement already active")
            return
        }
        
        self.updateHandler = updateHandler
        self.errorHandler = errorHandler
        self.isActive = true
        
        // Start frame throttler
        frameThrottler.start()
        
        // Reset statistics
        statistics = RealtimeMeasurementStatistics()
        
        print("✅ Real-time measurement started at \(frameThrottler.targetFPS) fps")
    }
    
    /// Stop real-time measurement
    func stopRealtimeMeasurement() {
        guard isActive else {
            print("⚠️ Real-time measurement not active")
            return
        }
        
        isActive = false
        
        // Stop frame throttler
        frameThrottler.stop()
        
        // Clear handlers
        updateHandler = nil
        errorHandler = nil
        
        // Clear cached measurement
        lastMeasurement = nil
        
        // Reset measurement filter
        measurementFilter?.reset()
        
        print("✅ Real-time measurement stopped")
        printStatistics()
    }
    
    /// Process an AR frame for real-time measurement
    /// - Parameter frame: ARFrame to process
    func processFrame(_ frame: ARFrame) {
        guard isActive else { return }
        
        // Use frame throttler to control processing frequency
        frameThrottler.processFrame(frame) { [weak self] throttledFrame in
            self?.performMeasurement(on: throttledFrame)
        }
    }
    
    /// Update target FPS for real-time measurement
    /// - Parameter fps: New target frames per second (1-30)
    func setTargetFPS(_ fps: Double) {
        frameThrottler.setTargetFPS(fps)
        print("📊 Real-time measurement FPS updated to \(fps)")
    }
    
    /// Get current measurement statistics
    /// - Returns: Statistics about real-time measurement performance
    func getStatistics() -> RealtimeMeasurementStatistics {
        return statistics
    }
    
    /// Get last successful measurement
    /// - Returns: Last measurement result, or nil if none available
    func getLastMeasurement() -> RealtimeMeasurementResult? {
        return lastMeasurement
    }
    
    /// Update configuration
    /// - Parameter configuration: New configuration
    func updateConfiguration(_ configuration: RealtimeMeasurementConfiguration) {
        self.configuration = configuration
        
        // Update measurement filter
        if configuration.enableSmoothing {
            var filterConfig = MeasurementFilterConfiguration()
            filterConfig.filterType = configuration.filterType
            filterConfig.windowSize = configuration.smoothingWindowSize
            filterConfig.enableOutlierDetection = configuration.enableOutlierDetection
            filterConfig.outlierThreshold = configuration.outlierThreshold
            
            if measurementFilter == nil {
                measurementFilter = MeasurementFilter(configuration: filterConfig)
            } else {
                measurementFilter?.updateConfiguration(filterConfig)
            }
        } else {
            measurementFilter = nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Perform measurement on a frame
    /// - Parameter frame: ARFrame to measure
    private func performMeasurement(on frame: ARFrame) {
        let startTime = CACurrentMediaTime()
        statistics.totalFramesProcessed += 1
        
        measurementQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Convert ARFrame to UIImage for object detection
            guard let image = self.convertARFrameToImage(frame) else {
                print("❌ Failed to convert ARFrame to image")
                self.handleError(.invalidImageData)
                return
            }
            
            print("🔍 Detecting objects in frame \(self.statistics.totalFramesProcessed)...")
            
            // Detect objects in the frame
            let detectedObjects = self.objectDetector.detectObjects(in: image)
            
            print("   Found \(detectedObjects.count) objects")
            
            guard !detectedObjects.isEmpty else {
                // No objects detected - use cached measurement if available
                if let cached = self.lastMeasurement, self.configuration.useCachedResults {
                    print("   Using cached measurement")
                    self.notifyUpdate(cached)
                } else {
                    print("   No objects detected and no cache available")
                }
                self.statistics.failedMeasurements += 1
                return
            }
            
            // Get the most confident detection
            guard let primaryObject = detectedObjects.max(by: { $0.confidence < $1.confidence }) else {
                print("   Failed to get primary object")
                self.statistics.failedMeasurements += 1
                return
            }
            
            print("   Primary object: \(primaryObject.objectType), confidence: \(primaryObject.confidence)")
            
            // Calculate dimensions
            let dimensions = self.measurementCalculator.calculateDimensions(
                object: primaryObject,
                arFrame: frame
            )
            
            print("   Calculated dimensions: \(dimensions.formattedDimensions())")
            
            // Apply filtering if enabled
            let finalDimensions: ObjectDimensions
            if let filter = self.measurementFilter {
                finalDimensions = filter.filter(dimensions)
            } else {
                finalDimensions = dimensions
            }
            
            // Create measurement result
            let processingTime = CACurrentMediaTime() - startTime
            let result = RealtimeMeasurementResult(
                object: primaryObject,
                dimensions: finalDimensions,
                timestamp: Date(),
                processingTime: processingTime,
                frameNumber: self.statistics.totalFramesProcessed
            )
            
            // Update statistics
            self.statistics.successfulMeasurements += 1
            self.statistics.totalProcessingTime += processingTime
            self.statistics.averageProcessingTime = self.statistics.totalProcessingTime / Double(self.statistics.successfulMeasurements)
            
            // Cache result
            self.lastMeasurement = result
            
            // Notify update on main thread
            self.notifyUpdate(result)
        }
    }
    
    /// Convert ARFrame to UIImage
    /// - Parameter frame: ARFrame to convert
    /// - Returns: UIImage, or nil if conversion fails
    private func convertARFrameToImage(_ frame: ARFrame) -> UIImage? {
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Notify update handler with measurement result
    /// - Parameter result: Measurement result to send
    private func notifyUpdate(_ result: RealtimeMeasurementResult) {
        DispatchQueue.main.async { [weak self] in
            self?.updateHandler?(result)
        }
    }
    
    /// Handle measurement error
    /// - Parameter error: Error that occurred
    private func handleError(_ error: MeasurementError) {
        statistics.failedMeasurements += 1
        
        DispatchQueue.main.async { [weak self] in
            self?.errorHandler?(error)
        }
    }
    
    /// Print statistics to console
    private func printStatistics() {
        print("📊 Real-time Measurement Statistics:")
        print("   Total frames processed: \(statistics.totalFramesProcessed)")
        print("   Successful measurements: \(statistics.successfulMeasurements)")
        print("   Failed measurements: \(statistics.failedMeasurements)")
        print("   Success rate: \(String(format: "%.1f%%", statistics.successRate * 100))")
        print("   Average processing time: \(String(format: "%.1f ms", statistics.averageProcessingTime * 1000))")
    }
}

// MARK: - Supporting Types

/// Configuration for real-time measurement
struct RealtimeMeasurementConfiguration {
    /// Whether to use cached results when detection fails
    var useCachedResults: Bool = true
    
    /// Whether to enable measurement smoothing
    var enableSmoothing: Bool = true
    
    /// Window size for smoothing filter
    var smoothingWindowSize: Int = 5
    
    /// Filter type to use
    var filterType: FilterType = .movingAverage
    
    /// Whether to enable outlier detection
    var enableOutlierDetection: Bool = true
    
    /// Outlier detection threshold (standard deviations)
    var outlierThreshold: Float = 2.5
    
    /// Minimum confidence threshold for measurements
    var minimumConfidence: Float = 0.5
    
    /// Maximum processing time before warning (in seconds)
    var maxProcessingTime: TimeInterval = 0.2
}

/// Result of a real-time measurement
struct RealtimeMeasurementResult {
    /// Detected object
    let object: DetectedObject
    
    /// Measured dimensions
    let dimensions: ObjectDimensions
    
    /// Timestamp of measurement
    let timestamp: Date
    
    /// Processing time for this measurement
    let processingTime: TimeInterval
    
    /// Frame number
    let frameNumber: Int
}

/// Statistics for real-time measurement performance
struct RealtimeMeasurementStatistics {
    /// Total frames processed
    var totalFramesProcessed: Int = 0
    
    /// Successful measurements
    var successfulMeasurements: Int = 0
    
    /// Failed measurements
    var failedMeasurements: Int = 0
    
    /// Total processing time
    var totalProcessingTime: TimeInterval = 0
    
    /// Average processing time per measurement
    var averageProcessingTime: TimeInterval = 0
    
    /// Success rate (0.0 - 1.0)
    var successRate: Double {
        guard totalFramesProcessed > 0 else { return 0 }
        return Double(successfulMeasurements) / Double(totalFramesProcessed)
    }
}


