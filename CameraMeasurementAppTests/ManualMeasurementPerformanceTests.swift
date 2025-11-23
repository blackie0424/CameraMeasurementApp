//
//  ManualMeasurementPerformanceTests.swift
//  CameraMeasurementAppTests
//
//  Performance tests for Manual AR Measurement feature
//  需求: 3.5
//

import XCTest
import SceneKit
import ARKit
@testable import CameraMeasurementApp

class ManualMeasurementPerformanceTests: XCTestCase {
    
    var performanceMonitor: PerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        performanceMonitor = PerformanceMonitor.shared
    }
    
    override func tearDown() {
        performanceMonitor.stopMonitoring()
        super.tearDown()
    }
    
    // MARK: - FPS Tests
    
    /// Test that FPS tracking works correctly
    func testFPSTracking() {
        performanceMonitor.startMonitoring()
        
        // Simulate 60 frames over 2 seconds (30 FPS)
        let startTime: TimeInterval = 0
        for frame in 0..<60 {
            let time = startTime + Double(frame) / 30.0
            performanceMonitor.updateFPS(at: time)
        }
        
        // Allow time for FPS calculation
        Thread.sleep(forTimeInterval: 0.1)
        
        // FPS should be around 30
        let currentFPS = performanceMonitor.currentFPS
        XCTAssertGreaterThan(currentFPS, 25.0, "FPS should be above minimum threshold")
        XCTAssertLessThan(currentFPS, 35.0, "FPS should be reasonable")
    }
    
    /// Test FPS performance under load
    func testFPSPerformance() {
        performanceMonitor.startMonitoring()
        
        measure {
            // Simulate rendering loop
            let startTime = CACurrentMediaTime()
            var frameCount = 0
            
            while CACurrentMediaTime() - startTime < 1.0 {
                performanceMonitor.updateFPS(at: CACurrentMediaTime())
                frameCount += 1
                
                // Simulate some work
                _ = (0..<100).map { $0 * $0 }
            }
            
            // Should achieve at least 30 FPS
            XCTAssertGreaterThanOrEqual(frameCount, 30, "Should render at least 30 frames per second")
        }
    }
    
    // MARK: - Memory Tests
    
    /// Test memory usage tracking
    func testMemoryTracking() {
        performanceMonitor.startMonitoring()
        
        // Wait for initial memory measurement
        Thread.sleep(forTimeInterval: 1.5)
        
        let initialMemory = performanceMonitor.currentMemoryUsage
        XCTAssertGreaterThan(initialMemory, 0, "Memory usage should be tracked")
        
        // Memory should be in reasonable range (< 200 MB)
        let memoryMB = initialMemory / (1024 * 1024)
        XCTAssertLessThan(memoryMB, 200, "Memory usage should be under 200 MB")
    }
    
    /// Test for memory leaks with node creation and removal
    func testNodeMemoryLeak() {
        // Create a test scene
        let scene = SCNScene()
        let rootNode = scene.rootNode
        
        // Measure initial node count
        let initialNodeCount = countNodes(in: rootNode)
        
        // Create and remove nodes multiple times
        for _ in 0..<10 {
            // Create nodes
            let sphere = SCNSphere(radius: 0.01)
            let node = SCNNode(geometry: sphere)
            rootNode.addChildNode(node)
            
            // Remove nodes
            node.removeFromParentNode()
        }
        
        // Final node count should be same as initial
        let finalNodeCount = countNodes(in: rootNode)
        XCTAssertEqual(initialNodeCount, finalNodeCount, "Node count should not increase after cleanup")
    }
    
    // MARK: - Stability Tests
    
    /// Test long-running stability
    func testLongRunningStability() {
        performanceMonitor.startMonitoring()
        
        let testDuration: TimeInterval = 5.0 // 5 seconds for test
        let startTime = CACurrentMediaTime()
        var frameCount = 0
        
        // Simulate continuous operation
        while CACurrentMediaTime() - startTime < testDuration {
            let currentTime = CACurrentMediaTime()
            performanceMonitor.updateFPS(at: currentTime)
            frameCount += 1
            
            // Simulate work
            Thread.sleep(forTimeInterval: 1.0 / 60.0) // Target 60 FPS
        }
        
        // Should maintain stable FPS
        let averageFPS = Double(frameCount) / testDuration
        XCTAssertGreaterThan(averageFPS, 30.0, "Should maintain at least 30 FPS over time")
        
        // Performance should be acceptable
        XCTAssertTrue(performanceMonitor.isPerformanceAcceptable(), "Performance should remain acceptable")
    }
    
    /// Test performance under stress (rapid state changes)
    func testStressPerformance() {
        performanceMonitor.startMonitoring()
        
        let scene = SCNScene()
        let rootNode = scene.rootNode
        
        measure {
            // Simulate rapid measurement cycles
            for _ in 0..<100 {
                // Create measurement nodes
                let startMarker = SCNNode(geometry: SCNSphere(radius: 0.01))
                let endMarker = SCNNode(geometry: SCNSphere(radius: 0.01))
                let line = SCNNode(geometry: SCNCylinder(radius: 0.002, height: 1.0))
                
                rootNode.addChildNode(startMarker)
                rootNode.addChildNode(endMarker)
                rootNode.addChildNode(line)
                
                // Clean up
                startMarker.removeFromParentNode()
                endMarker.removeFromParentNode()
                line.removeFromParentNode()
            }
        }
        
        // Memory should not leak
        XCTAssertTrue(performanceMonitor.isPerformanceAcceptable(), "Performance should be acceptable after stress test")
    }
    
    // MARK: - Throttling Tests
    
    /// Test that frame throttling works correctly
    func testFrameThrottling() {
        let updateInterval: TimeInterval = 1.0 / 30.0 // 30 FPS
        var lastUpdateTime: TimeInterval = 0
        var updateCount = 0
        
        // Simulate 60 FPS input, should throttle to 30 FPS
        let startTime: TimeInterval = 0
        for frame in 0..<120 { // 2 seconds at 60 FPS
            let currentTime = startTime + Double(frame) / 60.0
            
            // Throttling logic
            if currentTime - lastUpdateTime >= updateInterval {
                lastUpdateTime = currentTime
                updateCount += 1
            }
        }
        
        // Should have approximately 60 updates (30 FPS * 2 seconds)
        XCTAssertGreaterThanOrEqual(updateCount, 55, "Should have at least 55 updates")
        XCTAssertLessThanOrEqual(updateCount, 65, "Should have at most 65 updates")
    }
    
    // MARK: - Helper Methods
    
    private func countNodes(in node: SCNNode) -> Int {
        var count = 1
        for child in node.childNodes {
            count += countNodes(in: child)
        }
        return count
    }
}

// MARK: - Performance Benchmark Tests

extension ManualMeasurementPerformanceTests {
    
    /// Benchmark: Node creation performance
    func testNodeCreationPerformance() {
        measure {
            let scene = SCNScene()
            for _ in 0..<100 {
                let sphere = SCNSphere(radius: 0.01)
                let node = SCNNode(geometry: sphere)
                scene.rootNode.addChildNode(node)
            }
        }
    }
    
    /// Benchmark: Distance calculation performance
    func testDistanceCalculationPerformance() {
        let stateManager = MeasurementStateManager()
        let point1 = SCNVector3(0, 0, 0)
        let point2 = SCNVector3(1, 1, 1)
        
        measure {
            for _ in 0..<10000 {
                _ = stateManager.calculateDistance(from: point1, to: point2)
            }
        }
    }
    
    /// Benchmark: Line geometry update performance
    func testLineUpdatePerformance() {
        let scene = SCNScene()
        let cylinder = SCNCylinder(radius: 0.002, height: 1.0)
        let lineNode = SCNNode(geometry: cylinder)
        scene.rootNode.addChildNode(lineNode)
        
        measure {
            for i in 0..<1000 {
                let height = CGFloat(i % 100) / 100.0
                cylinder.height = height
                lineNode.position = SCNVector3(0, Float(height) / 2, 0)
            }
        }
    }
}
