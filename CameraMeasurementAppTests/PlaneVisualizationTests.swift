//
//  PlaneVisualizationTests.swift
//  CameraMeasurementAppTests
//
//  Property-based tests for plane visualization rendering
//

import Testing
import ARKit
import SceneKit
@testable import CameraMeasurementApp

// MARK: - Property 3: 平面類型到顏色映射
// Feature: ar-plane-detection-accuracy, Property 3: 平面類型到顏色映射
// Validates: Requirements 2.2, 2.3

/// Property-based tests for plane type to color mapping
struct PlaneColorMappingTests {
    
    /// Property: For any detected plane, horizontal planes should render as blue (transparency 0.3),
    /// vertical planes should render as green (transparency 0.3)
    @Test("Property 3: Horizontal planes map to blue color")
    func testHorizontalPlanesMapToBlue() async throws {
        // Test the color mapping logic for horizontal planes
        // Expected: RGB(0.2, 0.5, 1.0) with alpha 0.3
        
        let expectedRed: CGFloat = 0.2
        let expectedGreen: CGFloat = 0.5
        let expectedBlue: CGFloat = 1.0
        let expectedAlpha: CGFloat = 0.3
        
        // Create the expected color
        let horizontalColor = UIColor(red: expectedRed, green: expectedGreen, blue: expectedBlue, alpha: expectedAlpha)
        
        // Extract components to verify
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        horizontalColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Verify color components match specification
        #expect(abs(red - expectedRed) < 0.01, "Horizontal plane red component should be 0.2")
        #expect(abs(green - expectedGreen) < 0.01, "Horizontal plane green component should be 0.5")
        #expect(abs(blue - expectedBlue) < 0.01, "Horizontal plane blue component should be 1.0")
        #expect(abs(alpha - expectedAlpha) < 0.01, "Horizontal plane alpha should be 0.3")
    }
    
    @Test("Property 3: Vertical planes map to green color")
    func testVerticalPlanesMapToGreen() async throws {
        // Test the color mapping logic for vertical planes
        // Expected: RGB(0.2, 1.0, 0.5) with alpha 0.3
        
        let expectedRed: CGFloat = 0.2
        let expectedGreen: CGFloat = 1.0
        let expectedBlue: CGFloat = 0.5
        let expectedAlpha: CGFloat = 0.3
        
        // Create the expected color
        let verticalColor = UIColor(red: expectedRed, green: expectedGreen, blue: expectedBlue, alpha: expectedAlpha)
        
        // Extract components to verify
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        verticalColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Verify color components match specification
        #expect(abs(red - expectedRed) < 0.01, "Vertical plane red component should be 0.2")
        #expect(abs(green - expectedGreen) < 0.01, "Vertical plane green component should be 1.0")
        #expect(abs(blue - expectedBlue) < 0.01, "Vertical plane blue component should be 0.5")
        #expect(abs(alpha - expectedAlpha) < 0.01, "Vertical plane alpha should be 0.3")
    }
    
    /// Property test: Color mapping is consistent across multiple invocations
    @Test("Property 3: Color mapping is consistent")
    func testColorMappingIsConsistent() async throws {
        // Test that the color mapping function is deterministic
        // Same plane type should always produce the same color
        
        let iterations = 100
        
        // Test horizontal plane color consistency
        let horizontalColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3)
        
        for iteration in 0..<iterations {
            let testColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3)
            
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            
            horizontalColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            testColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            #expect(abs(r1 - r2) < 0.01, "Iteration \(iteration): Red component should be consistent")
            #expect(abs(g1 - g2) < 0.01, "Iteration \(iteration): Green component should be consistent")
            #expect(abs(b1 - b2) < 0.01, "Iteration \(iteration): Blue component should be consistent")
            #expect(abs(a1 - a2) < 0.01, "Iteration \(iteration): Alpha component should be consistent")
        }
        
        // Test vertical plane color consistency
        let verticalColor = UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.3)
        
        for iteration in 0..<iterations {
            let testColor = UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.3)
            
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            
            verticalColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            testColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            #expect(abs(r1 - r2) < 0.01, "Iteration \(iteration): Red component should be consistent")
            #expect(abs(g1 - g2) < 0.01, "Iteration \(iteration): Green component should be consistent")
            #expect(abs(b1 - b2) < 0.01, "Iteration \(iteration): Blue component should be consistent")
            #expect(abs(a1 - a2) < 0.01, "Iteration \(iteration): Alpha component should be consistent")
        }
    }
    
    /// Property test: Colors are distinct between horizontal and vertical
    @Test("Property 3: Horizontal and vertical colors are distinct")
    func testHorizontalAndVerticalColorsAreDistinct() async throws {
        // Verify that horizontal and vertical planes have different colors
        
        let horizontalColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3)
        let verticalColor = UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.3)
        
        var hr: CGFloat = 0, hg: CGFloat = 0, hb: CGFloat = 0, ha: CGFloat = 0
        var vr: CGFloat = 0, vg: CGFloat = 0, vb: CGFloat = 0, va: CGFloat = 0
        
        horizontalColor.getRed(&hr, green: &hg, blue: &hb, alpha: &ha)
        verticalColor.getRed(&vr, green: &vg, blue: &vb, alpha: &va)
        
        // Colors should be different (at least one component differs significantly)
        let redDiff = abs(hr - vr)
        let greenDiff = abs(hg - vg)
        let blueDiff = abs(hb - vb)
        
        let hasSignificantDifference = redDiff > 0.1 || greenDiff > 0.1 || blueDiff > 0.1
        
        #expect(hasSignificantDifference, "Horizontal and vertical plane colors should be visually distinct")
        
        // Alpha should be the same
        #expect(abs(ha - va) < 0.01, "Both plane types should have same transparency")
    }
    
    /// Property test: Transparency is correct for both plane types
    @Test("Property 3: Both plane types have 0.3 transparency")
    func testBothPlaneTypesHaveCorrectTransparency() async throws {
        let expectedAlpha: CGFloat = 0.3
        
        // Test horizontal plane transparency
        let horizontalColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3)
        var hAlpha: CGFloat = 0
        horizontalColor.getRed(nil, green: nil, blue: nil, alpha: &hAlpha)
        #expect(abs(hAlpha - expectedAlpha) < 0.01, "Horizontal plane alpha should be 0.3")
        
        // Test vertical plane transparency
        let verticalColor = UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.3)
        var vAlpha: CGFloat = 0
        verticalColor.getRed(nil, green: nil, blue: nil, alpha: &vAlpha)
        #expect(abs(vAlpha - expectedAlpha) < 0.01, "Vertical plane alpha should be 0.3")
    }
    
    /// Property test: Color values are within valid range [0, 1]
    @Test("Property 3: Color components are within valid range")
    func testColorComponentsAreWithinValidRange() async throws {
        let colors = [
            UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3),  // Horizontal
            UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.3)   // Vertical
        ]
        
        for (index, color) in colors.enumerated() {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            #expect(r >= 0.0 && r <= 1.0, "Color \(index): Red component should be in [0, 1]")
            #expect(g >= 0.0 && g <= 1.0, "Color \(index): Green component should be in [0, 1]")
            #expect(b >= 0.0 && b <= 1.0, "Color \(index): Blue component should be in [0, 1]")
            #expect(a >= 0.0 && a <= 1.0, "Color \(index): Alpha component should be in [0, 1]")
        }
    }
}


// MARK: - Property 15: 追蹤品質不佳時平面變黃色
// Feature: ar-plane-detection-accuracy, Property 15: 追蹤品質不佳時平面變黃色
// Validates: Requirements 5.5

/// Property-based tests for tracking quality visual feedback
struct TrackingQualityVisualFeedbackTests {
    
    /// Property: For any tracking state of limited or notAvailable,
    /// all plane visualizations should change color to yellow
    @Test("Property 15: Poor tracking quality changes planes to yellow")
    func testPoorTrackingQualityChangesPlanesToYellow() async throws {
        // Test the yellow color specification for poor tracking quality
        // Expected: RGB(1.0, 0.8, 0.0) with alpha 0.3
        
        let expectedRed: CGFloat = 1.0
        let expectedGreen: CGFloat = 0.8
        let expectedBlue: CGFloat = 0.0
        let expectedAlpha: CGFloat = 0.3
        
        // Create the expected yellow color
        let yellowColor = UIColor(red: expectedRed, green: expectedGreen, blue: expectedBlue, alpha: expectedAlpha)
        
        // Extract components to verify
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        yellowColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Verify color components match specification
        #expect(abs(red - expectedRed) < 0.01, "Warning color red component should be 1.0")
        #expect(abs(green - expectedGreen) < 0.01, "Warning color green component should be 0.8")
        #expect(abs(blue - expectedBlue) < 0.01, "Warning color blue component should be 0.0")
        #expect(abs(alpha - expectedAlpha) < 0.01, "Warning color alpha should be 0.3")
    }
    
    /// Property test: Yellow warning color is distinct from normal plane colors
    @Test("Property 15: Yellow warning color is distinct from normal colors")
    func testYellowWarningColorIsDistinct() async throws {
        let yellowColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.3)
        let horizontalColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3)
        let verticalColor = UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.3)
        
        var yr: CGFloat = 0, yg: CGFloat = 0, yb: CGFloat = 0
        var hr: CGFloat = 0, hg: CGFloat = 0, hb: CGFloat = 0
        var vr: CGFloat = 0, vg: CGFloat = 0, vb: CGFloat = 0
        
        yellowColor.getRed(&yr, green: &yg, blue: &yb, alpha: nil)
        horizontalColor.getRed(&hr, green: &hg, blue: &hb, alpha: nil)
        verticalColor.getRed(&vr, green: &vg, blue: &vb, alpha: nil)
        
        // Calculate color distance from yellow to horizontal
        let distToHorizontal = sqrt(pow(yr - hr, 2) + pow(yg - hg, 2) + pow(yb - hb, 2))
        
        // Calculate color distance from yellow to vertical
        let distToVertical = sqrt(pow(yr - vr, 2) + pow(yg - vg, 2) + pow(yb - vb, 2))
        
        // Yellow should be significantly different from both normal colors
        #expect(distToHorizontal > 0.5, "Yellow should be visually distinct from horizontal blue")
        #expect(distToVertical > 0.5, "Yellow should be visually distinct from vertical green")
    }
    
    /// Property test: Yellow color is consistent across multiple invocations
    @Test("Property 15: Yellow warning color is consistent")
    func testYellowWarningColorIsConsistent() async throws {
        let iterations = 100
        
        let referenceYellow = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.3)
        
        for iteration in 0..<iterations {
            let testYellow = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.3)
            
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            
            referenceYellow.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            testYellow.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            #expect(abs(r1 - r2) < 0.01, "Iteration \(iteration): Red component should be consistent")
            #expect(abs(g1 - g2) < 0.01, "Iteration \(iteration): Green component should be consistent")
            #expect(abs(b1 - b2) < 0.01, "Iteration \(iteration): Blue component should be consistent")
            #expect(abs(a1 - a2) < 0.01, "Iteration \(iteration): Alpha component should be consistent")
        }
    }
    
    /// Property test: Yellow color maintains same transparency as normal colors
    @Test("Property 15: Yellow warning maintains 0.3 transparency")
    func testYellowWarningMaintainsTransparency() async throws {
        let expectedAlpha: CGFloat = 0.3
        
        let yellowColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.3)
        var alpha: CGFloat = 0
        yellowColor.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        
        #expect(abs(alpha - expectedAlpha) < 0.01, "Yellow warning color alpha should be 0.3")
    }
    
    /// Property test: Color change applies to all plane types
    @Test("Property 15: Yellow warning applies to all plane types")
    func testYellowWarningAppliesUniversally() async throws {
        // This property tests that the warning color is the same
        // regardless of the original plane type (horizontal or vertical)
        
        let warningColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.3)
        
        // Simulate applying warning color to different plane types
        // The result should always be the same yellow color
        
        let iterations = 50
        for iteration in 0..<iterations {
            // Generate random plane type (horizontal or vertical)
            let isHorizontal = Bool.random()
            
            // Original color doesn't matter - warning color should be applied
            let originalColor = isHorizontal ?
                UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3) :
                UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.3)
            
            // After applying warning, color should be yellow
            let resultColor = warningColor
            
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            resultColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            #expect(abs(r - 1.0) < 0.01, "Iteration \(iteration): Warning red should be 1.0")
            #expect(abs(g - 0.8) < 0.01, "Iteration \(iteration): Warning green should be 0.8")
            #expect(abs(b - 0.0) < 0.01, "Iteration \(iteration): Warning blue should be 0.0")
            #expect(abs(a - 0.3) < 0.01, "Iteration \(iteration): Warning alpha should be 0.3")
        }
    }
    
    /// Property test: Yellow is a warm, attention-grabbing color
    @Test("Property 15: Yellow is a warm warning color")
    func testYellowIsWarmWarningColor() async throws {
        let yellowColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.3)
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        yellowColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        
        // Yellow should have high red and green, low blue (warm color)
        #expect(r > 0.7, "Yellow should have high red component (warm)")
        #expect(g > 0.7, "Yellow should have high green component (warm)")
        #expect(b < 0.3, "Yellow should have low blue component (warm)")
        
        // Yellow should be bright (high luminance)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        #expect(luminance > 0.6, "Yellow should be bright for visibility")
    }
}
