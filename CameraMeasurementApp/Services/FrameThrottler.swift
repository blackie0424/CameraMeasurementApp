//
//  FrameThrottler.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import ARKit

/// Controls frame processing frequency to optimize performance
/// Downsamples from ARKit's 60fps to configurable target rate (5-10fps)
class FrameThrottler {
    
    // MARK: - Properties
    
    /// Target frames per second for processing (default: 10fps)
    private(set) var targetFPS: Double
    
    /// Minimum time interval between processed frames
    private var minimumFrameInterval: TimeInterval {
        return 1.0 / targetFPS
    }
    
    /// Timestamp of the last processed frame
    private var lastProcessedTime: TimeInterval = 0
    
    /// Frame buffer queue for managing incoming frames
    private let frameQueue = DispatchQueue(label: "com.camerameasurement.frameThrottler", qos: .userInitiated)
    
    /// Whether throttling is currently active
    private(set) var isActive: Bool = false
    
    /// Statistics tracking
    private var totalFramesReceived: Int = 0
    private var totalFramesProcessed: Int = 0
    private var startTime: TimeInterval = 0
    
    // MARK: - Initialization
    
    /// Initialize frame throttler with target FPS
    /// - Parameter targetFPS: Desired frames per second (default: 10, range: 1-30)
    init(targetFPS: Double = 10.0) {
        self.targetFPS = min(max(targetFPS, 1.0), 30.0) // Clamp between 1-30 fps
    }
    
    // MARK: - Public Methods
    
    /// Start throttling frames
    func start() {
        frameQueue.async { [weak self] in
            guard let self = self else { return }
            self.isActive = true
            self.lastProcessedTime = 0
            self.totalFramesReceived = 0
            self.totalFramesProcessed = 0
            self.startTime = CACurrentMediaTime()
        }
    }
    
    /// Stop throttling frames
    func stop() {
        frameQueue.async { [weak self] in
            guard let self = self else { return }
            self.isActive = false
        }
    }
    
    /// Update target FPS
    /// - Parameter fps: New target frames per second (range: 1-30)
    func setTargetFPS(_ fps: Double) {
        frameQueue.async { [weak self] in
            guard let self = self else { return }
            self.targetFPS = min(max(fps, 1.0), 30.0)
        }
    }
    
    /// Process incoming frame with throttling
    /// - Parameters:
    ///   - frame: ARFrame to potentially process
    ///   - handler: Closure called if frame should be processed
    /// - Returns: True if frame was processed, false if throttled
    @discardableResult
    func processFrame(_ frame: ARFrame, handler: @escaping (ARFrame) -> Void) -> Bool {
        guard isActive else {
            // Log occasionally
            if totalFramesReceived % 100 == 0 {
                print("⚠️ FrameThrottler not active, received \(totalFramesReceived) frames")
            }
            return false
        }
        
        totalFramesReceived += 1
        
        let currentTime = frame.timestamp
        let timeSinceLastProcess = currentTime - lastProcessedTime
        
        // Log occasionally
        if totalFramesReceived % 100 == 0 {
            print("🎞️ FrameThrottler: received \(totalFramesReceived) frames, processed \(totalFramesProcessed)")
        }
        
        // Check if enough time has passed since last processed frame
        if timeSinceLastProcess >= minimumFrameInterval {
            lastProcessedTime = currentTime
            totalFramesProcessed += 1
            
            // Log first few processed frames
            if totalFramesProcessed <= 3 {
                print("✅ FrameThrottler processing frame \(totalFramesProcessed)")
            }
            
            // Execute handler on background queue
            frameQueue.async {
                handler(frame)
            }
            
            return true
        }
        
        return false
    }
    
    /// Process incoming frame synchronously with throttling
    /// - Parameters:
    ///   - frame: ARFrame to potentially process
    ///   - handler: Closure called if frame should be processed
    /// - Returns: True if frame was processed, false if throttled
    @discardableResult
    func processFrameSync(_ frame: ARFrame, handler: (ARFrame) -> Void) -> Bool {
        guard isActive else { return false }
        
        totalFramesReceived += 1
        
        let currentTime = frame.timestamp
        let timeSinceLastProcess = currentTime - lastProcessedTime
        
        // Check if enough time has passed since last processed frame
        if timeSinceLastProcess >= minimumFrameInterval {
            lastProcessedTime = currentTime
            totalFramesProcessed += 1
            
            handler(frame)
            return true
        }
        
        return false
    }
    
    /// Check if a frame should be processed without actually processing it
    /// - Parameter frame: ARFrame to check
    /// - Returns: True if frame should be processed based on throttling rules
    func shouldProcessFrame(_ frame: ARFrame) -> Bool {
        guard isActive else { return false }
        
        let currentTime = frame.timestamp
        let timeSinceLastProcess = currentTime - lastProcessedTime
        
        return timeSinceLastProcess >= minimumFrameInterval
    }
    
    /// Reset throttler state
    func reset() {
        frameQueue.async { [weak self] in
            guard let self = self else { return }
            self.lastProcessedTime = 0
            self.totalFramesReceived = 0
            self.totalFramesProcessed = 0
            self.startTime = CACurrentMediaTime()
        }
    }
    
    // MARK: - Statistics
    
    /// Get current processing statistics
    /// - Returns: Dictionary containing statistics
    func getStatistics() -> [String: Any] {
        var stats: [String: Any] = [:]
        
        frameQueue.sync {
            let elapsedTime = CACurrentMediaTime() - startTime
            let actualFPS = elapsedTime > 0 ? Double(totalFramesProcessed) / elapsedTime : 0
            let receivedFPS = elapsedTime > 0 ? Double(totalFramesReceived) / elapsedTime : 0
            let processingRatio = totalFramesReceived > 0 ? Double(totalFramesProcessed) / Double(totalFramesReceived) : 0
            
            stats["targetFPS"] = targetFPS
            stats["actualFPS"] = actualFPS
            stats["receivedFPS"] = receivedFPS
            stats["totalFramesReceived"] = totalFramesReceived
            stats["totalFramesProcessed"] = totalFramesProcessed
            stats["processingRatio"] = processingRatio
            stats["elapsedTime"] = elapsedTime
            stats["isActive"] = isActive
        }
        
        return stats
    }
    
    /// Get actual processing FPS
    /// - Returns: Current frames per second being processed
    func getActualFPS() -> Double {
        var fps: Double = 0
        
        frameQueue.sync {
            let elapsedTime = CACurrentMediaTime() - startTime
            fps = elapsedTime > 0 ? Double(totalFramesProcessed) / elapsedTime : 0
        }
        
        return fps
    }
    
    /// Get processing efficiency (ratio of processed to received frames)
    /// - Returns: Value between 0 and 1 indicating processing efficiency
    func getProcessingEfficiency() -> Double {
        var efficiency: Double = 0
        
        frameQueue.sync {
            efficiency = totalFramesReceived > 0 ? Double(totalFramesProcessed) / Double(totalFramesReceived) : 0
        }
        
        return efficiency
    }
}

// MARK: - Frame Buffer Manager

/// Manages a buffer of frames for advanced throttling strategies
class FrameBufferManager {
    
    // MARK: - Properties
    
    /// Maximum number of frames to keep in buffer
    private let maxBufferSize: Int
    
    /// Frame buffer
    private var frameBuffer: [ARFrame] = []
    
    /// Queue for thread-safe buffer access
    private let bufferQueue = DispatchQueue(label: "com.camerameasurement.frameBuffer", qos: .userInitiated)
    
    /// Buffer strategy
    enum BufferStrategy {
        case keepLatest      // Keep only the most recent frame
        case keepOldest      // Keep the oldest frame
        case keepBest        // Keep frame with best tracking quality
    }
    
    private let strategy: BufferStrategy
    
    // MARK: - Initialization
    
    /// Initialize frame buffer manager
    /// - Parameters:
    ///   - maxSize: Maximum buffer size (default: 3)
    ///   - strategy: Buffer management strategy (default: .keepLatest)
    init(maxSize: Int = 3, strategy: BufferStrategy = .keepLatest) {
        self.maxBufferSize = max(1, maxSize)
        self.strategy = strategy
    }
    
    // MARK: - Public Methods
    
    /// Add frame to buffer
    /// - Parameter frame: ARFrame to add
    func addFrame(_ frame: ARFrame) {
        bufferQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.frameBuffer.append(frame)
            
            // Trim buffer if needed
            if self.frameBuffer.count > self.maxBufferSize {
                self.trimBuffer()
            }
        }
    }
    
    /// Get next frame from buffer
    /// - Returns: Next frame to process, or nil if buffer is empty
    func getNextFrame() -> ARFrame? {
        var frame: ARFrame?
        
        bufferQueue.sync {
            if !frameBuffer.isEmpty {
                frame = frameBuffer.removeFirst()
            }
        }
        
        return frame
    }
    
    /// Get latest frame without removing from buffer
    /// - Returns: Most recent frame, or nil if buffer is empty
    func peekLatestFrame() -> ARFrame? {
        var frame: ARFrame?
        
        bufferQueue.sync {
            frame = frameBuffer.last
        }
        
        return frame
    }
    
    /// Clear all frames from buffer
    func clear() {
        bufferQueue.async { [weak self] in
            self?.frameBuffer.removeAll()
        }
    }
    
    /// Get current buffer size
    /// - Returns: Number of frames in buffer
    func getBufferSize() -> Int {
        var size = 0
        
        bufferQueue.sync {
            size = frameBuffer.count
        }
        
        return size
    }
    
    /// Check if buffer is empty
    /// - Returns: True if buffer has no frames
    func isEmpty() -> Bool {
        return getBufferSize() == 0
    }
    
    /// Check if buffer is full
    /// - Returns: True if buffer is at maximum capacity
    func isFull() -> Bool {
        return getBufferSize() >= maxBufferSize
    }
    
    // MARK: - Private Methods
    
    private func trimBuffer() {
        guard frameBuffer.count > maxBufferSize else { return }
        
        switch strategy {
        case .keepLatest:
            // Remove oldest frames
            frameBuffer.removeFirst(frameBuffer.count - maxBufferSize)
            
        case .keepOldest:
            // Remove newest frames
            frameBuffer.removeLast(frameBuffer.count - maxBufferSize)
            
        case .keepBest:
            // Sort by tracking quality and keep best frames
            frameBuffer.sort { frame1, frame2 in
                let quality1 = getTrackingQuality(frame1)
                let quality2 = getTrackingQuality(frame2)
                return quality1 > quality2
            }
            frameBuffer.removeLast(frameBuffer.count - maxBufferSize)
        }
    }
    
    private func getTrackingQuality(_ frame: ARFrame) -> Int {
        switch frame.camera.trackingState {
        case .normal:
            return 3
        case .limited:
            return 2
        case .notAvailable:
            return 1
        }
    }
}
