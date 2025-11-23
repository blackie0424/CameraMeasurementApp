//
//  PerformanceMonitor.swift
//  CameraMeasurementApp
//
//  Performance monitoring utility for Manual AR Measurement
//  Tracks FPS, memory usage, and long-term stability
//  需求: 3.5
//

import Foundation
import SceneKit
import ARKit

/// Performance monitoring utility for tracking FPS, memory, and stability
class PerformanceMonitor {
    
    // MARK: - Singleton
    
    static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    
    /// FPS tracking
    private var frameCount: Int = 0
    private var lastFPSUpdateTime: TimeInterval = 0
    private(set) var currentFPS: Double = 0
    private var fpsHistory: [Double] = []
    
    /// Memory tracking
    private(set) var currentMemoryUsage: UInt64 = 0
    private var memoryHistory: [UInt64] = []
    private var peakMemoryUsage: UInt64 = 0
    
    /// Node tracking (for leak detection)
    private var nodeCount: Int = 0
    private var nodeCountHistory: [Int] = []
    
    /// Session tracking
    private var sessionStartTime: Date?
    private var sessionDuration: TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    /// Performance thresholds
    private let targetFPS: Double = 30.0
    private let minAcceptableFPS: Double = 25.0
    private let maxMemoryWarningMB: UInt64 = 200
    
    /// Monitoring state
    private(set) var isMonitoring: Bool = false
    private var monitoringTimer: Timer?
    
    /// Performance statistics
    private(set) var performanceStats = PerformanceStatistics()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start performance monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        sessionStartTime = Date()
        
        // Reset statistics
        performanceStats = PerformanceStatistics()
        fpsHistory.removeAll()
        memoryHistory.removeAll()
        nodeCountHistory.removeAll()
        
        // Start periodic memory monitoring (every 1 second)
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
        
        print("📊 Performance monitoring started")
    }
    
    /// Stop performance monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        // Generate final report
        generatePerformanceReport()
        
        print("📊 Performance monitoring stopped")
    }
    
    /// Update FPS tracking (call this in renderer updateAtTime)
    /// - Parameter time: Current time from renderer
    func updateFPS(at time: TimeInterval) {
        frameCount += 1
        
        // Calculate FPS every second
        if time - lastFPSUpdateTime >= 1.0 {
            currentFPS = Double(frameCount) / (time - lastFPSUpdateTime)
            
            // Record FPS
            fpsHistory.append(currentFPS)
            
            // Update statistics
            performanceStats.recordFPS(currentFPS)
            
            // Check for performance issues
            if currentFPS < minAcceptableFPS {
                performanceStats.lowFPSCount += 1
                print("⚠️ Low FPS detected: \(String(format: "%.1f", currentFPS)) FPS")
            }
            
            // Reset for next second
            frameCount = 0
            lastFPSUpdateTime = time
        }
    }
    
    /// Update node count (call this periodically to detect leaks)
    /// - Parameter sceneView: The ARSCNView to inspect
    func updateNodeCount(from sceneView: ARSCNView) {
        nodeCount = countNodes(in: sceneView.scene.rootNode)
        nodeCountHistory.append(nodeCount)
        
        // Check for potential memory leak (node count keeps growing)
        if nodeCountHistory.count > 10 {
            let recent = Array(nodeCountHistory.suffix(10))
            let isGrowing = recent.enumerated().allSatisfy { index, count in
                index == 0 || count >= recent[index - 1]
            }
            
            if isGrowing && nodeCount > 50 {
                performanceStats.potentialLeakDetected = true
                print("⚠️ Potential node leak detected: \(nodeCount) nodes")
            }
        }
    }
    
    /// Get current performance summary
    func getCurrentSummary() -> String {
        return """
        📊 Performance Summary:
        - FPS: \(String(format: "%.1f", currentFPS)) (Target: \(targetFPS))
        - Memory: \(formatMemory(currentMemoryUsage)) (Peak: \(formatMemory(peakMemoryUsage)))
        - Nodes: \(nodeCount)
        - Session Duration: \(formatDuration(sessionDuration))
        """
    }
    
    /// Check if performance is acceptable
    func isPerformanceAcceptable() -> Bool {
        let fpsOK = currentFPS >= minAcceptableFPS || currentFPS == 0 // 0 means not yet measured
        let memoryOK = currentMemoryUsage < maxMemoryWarningMB * 1024 * 1024
        let noLeaks = !performanceStats.potentialLeakDetected
        
        return fpsOK && memoryOK && noLeaks
    }
    
    // MARK: - Private Methods
    
    /// Update memory usage
    private func updateMemoryUsage() {
        currentMemoryUsage = getMemoryUsage()
        memoryHistory.append(currentMemoryUsage)
        
        // Update peak memory
        if currentMemoryUsage > peakMemoryUsage {
            peakMemoryUsage = currentMemoryUsage
        }
        
        // Update statistics
        performanceStats.recordMemory(currentMemoryUsage)
        
        // Check for memory warnings
        let memoryMB = currentMemoryUsage / (1024 * 1024)
        if memoryMB > maxMemoryWarningMB {
            performanceStats.highMemoryCount += 1
            print("⚠️ High memory usage: \(memoryMB) MB")
        }
    }
    
    /// Get current memory usage in bytes
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    /// Count all nodes in scene hierarchy
    private func countNodes(in node: SCNNode) -> Int {
        var count = 1
        for child in node.childNodes {
            count += countNodes(in: child)
        }
        return count
    }
    
    /// Format memory size for display
    private func formatMemory(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024.0 * 1024.0)
        return String(format: "%.1f MB", mb)
    }
    
    /// Format duration for display
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Generate and print performance report
    private func generatePerformanceReport() {
        let report = """
        
        ═══════════════════════════════════════════════════════
        📊 PERFORMANCE MONITORING REPORT
        ═══════════════════════════════════════════════════════
        
        Session Duration: \(formatDuration(sessionDuration))
        
        FPS Statistics:
        - Average: \(String(format: "%.1f", performanceStats.averageFPS)) FPS
        - Minimum: \(String(format: "%.1f", performanceStats.minFPS)) FPS
        - Maximum: \(String(format: "%.1f", performanceStats.maxFPS)) FPS
        - Target: \(targetFPS) FPS
        - Low FPS Events: \(performanceStats.lowFPSCount)
        - Status: \(performanceStats.averageFPS >= targetFPS ? "✅ PASS" : "⚠️ BELOW TARGET")
        
        Memory Statistics:
        - Average: \(formatMemory(performanceStats.averageMemory))
        - Peak: \(formatMemory(peakMemoryUsage))
        - High Memory Events: \(performanceStats.highMemoryCount)
        - Status: \(peakMemoryUsage < maxMemoryWarningMB * 1024 * 1024 ? "✅ PASS" : "⚠️ HIGH")
        
        Node Count:
        - Current: \(nodeCount)
        - Potential Leak: \(performanceStats.potentialLeakDetected ? "⚠️ YES" : "✅ NO")
        
        Overall Status: \(isPerformanceAcceptable() ? "✅ ACCEPTABLE" : "⚠️ NEEDS ATTENTION")
        
        ═══════════════════════════════════════════════════════
        """
        
        print(report)
    }
}

// MARK: - Performance Statistics

struct PerformanceStatistics {
    var averageFPS: Double = 0
    var minFPS: Double = Double.greatestFiniteMagnitude
    var maxFPS: Double = 0
    var lowFPSCount: Int = 0
    
    var averageMemory: UInt64 = 0
    var highMemoryCount: Int = 0
    
    var potentialLeakDetected: Bool = false
    
    private var fpsSamples: [Double] = []
    private var memorySamples: [UInt64] = []
    
    mutating func recordFPS(_ fps: Double) {
        fpsSamples.append(fps)
        
        if fps < minFPS {
            minFPS = fps
        }
        if fps > maxFPS {
            maxFPS = fps
        }
        
        averageFPS = fpsSamples.reduce(0, +) / Double(fpsSamples.count)
    }
    
    mutating func recordMemory(_ memory: UInt64) {
        memorySamples.append(memory)
        averageMemory = memorySamples.reduce(0, +) / UInt64(memorySamples.count)
    }
}
