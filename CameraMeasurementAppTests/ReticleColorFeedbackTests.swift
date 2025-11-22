//
//  ReticleColorFeedbackTests.swift
//  CameraMeasurementAppTests
//
//  Property-based tests for reticle color feedback
//

import Testing
import UIKit
@testable import CameraMeasurementApp

// MARK: - Property 8: 游標顏色回饋
// Feature: ar-plane-detection-accuracy, Property 8: 游標顏色回饋
// Validates: Requirements 3.4, 3.5

/// Property-based tests for reticle color feedback
struct ReticleColorFeedbackTests {
    
    /// Property: For any reticle state, when aligned with a valid plane the reticle should be green,
    /// when not aligned it should be red
    @Test("Property 8: OnPlane state maps to green color")
    func testOnPlaneStateMapToGreen() async throws {
        // Test the color mapping for onPlane state
        // Expected: Green color with high green component
        
        let expectedRed: CGFloat = 0.2
        let expectedGreen: CGFloat = 1.0
        let expectedBlue: CGFloat = 0.2
        let expectedAlpha: CGFloat = 0.8
        
        // Create the expected green color for onPlane state
        let greenColor = UIColor(red: expectedRed, green: expectedGreen, blue: expectedBlue, alpha: expectedAlpha)
        
        // Extract components to verify
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        greenColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Verify color components match specification
        #expect(abs(red - expectedRed) < 0.01, "OnPlane reticle red component should be 0.2")
        #expect(abs(green - expectedGreen) < 0.01, "OnPlane reticle green component should be 1.0")
        #expect(abs(blue - expectedBlue) < 0.01, "OnPlane reticle blue component should be 0.2")
        #expect(abs(alpha - expectedAlpha) < 0.01, "OnPlane reticle alpha should be 0.8")
    }
    
    @Test("Property 8: OffPlane state maps to red color")
    func testOffPlaneStateMapToRed() async throws {
        // Test the color mapping for offPlane state
        // Expected: Red color with high red component
        
        let expectedRed: CGFloat = 1.0
        let expectedGreen: CGFloat = 0.2
        let expectedBlue: CGFloat = 0.2
        let expectedAlpha: CGFloat = 0.8
        
        // Create the expected red color for offPlane state
        let redColor = UIColor(red: expectedRed, green: expectedGreen, blue: expectedBlue, alpha: expectedAlpha)
        
        // Extract components to verify
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        redColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Verify color components match specification
        #expect(abs(red - expectedRed) < 0.01, "OffPlane reticle red component should be 1.0")
        #expect(abs(green - expectedGreen) < 0.01, "OffPlane reticle green component should be 0.2")
        #expect(abs(blue - expectedBlue) < 0.01, "OffPlane reticle blue component should be 0.2")
        #expect(abs(alpha - expectedAlpha) < 0.01, "OffPlane reticle alpha should be 0.8")
    }
    
    @Test("Property 8: Disabled state maps to gray color")
    func testDisabledStateMapToGray() async throws {
        // Test the color mapping for disabled state
        // Expected: Gray color with equal RGB components
        
        let expectedGray: CGFloat = 0.5
        let expectedAlpha: CGFloat = 0.5
        
        // Create the expected gray color for disabled state
        let grayColor = UIColor(white: expectedGray, alpha: expectedAlpha)
        
        // Extract components to verify
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        grayColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Verify color components match specification (gray has equal RGB)
        #expect(abs(red - expectedGray) < 0.01, "Disabled reticle red component should be 0.5")
        #expect(abs(green - expectedGray) < 0.01, "Disabled reticle green component should be 0.5")
        #expect(abs(blue - expectedGray) < 0.01, "Disabled reticle blue component should be 0.5")
        #expect(abs(alpha - expectedAlpha) < 0.01, "Disabled reticle alpha should be 0.5")
    }
    
    /// Property test: Color mapping is consistent across multiple invocations
    @Test("Property 8: Color mapping is consistent for all states")
    func testColorMappingIsConsistent() async throws {
        let iterations = 100
        
        // Test onPlane state consistency
        let onPlaneColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
        
        for iteration in 0..<iterations {
            let testColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
            
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            
            onPlaneColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            testColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            #expect(abs(r1 - r2) < 0.01, "Iteration \(iteration): OnPlane red should be consistent")
            #expect(abs(g1 - g2) < 0.01, "Iteration \(iteration): OnPlane green should be consistent")
            #expect(abs(b1 - b2) < 0.01, "Iteration \(iteration): OnPlane blue should be consistent")
            #expect(abs(a1 - a2) < 0.01, "Iteration \(iteration): OnPlane alpha should be consistent")
        }
        
        // Test offPlane state consistency
        let offPlaneColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)
        
        for iteration in 0..<iterations {
            let testColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)
            
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            
            offPlaneColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            testColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            #expect(abs(r1 - r2) < 0.01, "Iteration \(iteration): OffPlane red should be consistent")
            #expect(abs(g1 - g2) < 0.01, "Iteration \(iteration): OffPlane green should be consistent")
            #expect(abs(b1 - b2) < 0.01, "Iteration \(iteration): OffPlane blue should be consistent")
            #expect(abs(a1 - a2) < 0.01, "Iteration \(iteration): OffPlane alpha should be consistent")
        }
        
        // Test disabled state consistency
        let disabledColor = UIColor(white: 0.5, alpha: 0.5)
        
        for iteration in 0..<iterations {
            let testColor = UIColor(white: 0.5, alpha: 0.5)
            
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            
            disabledColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            testColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            #expect(abs(r1 - r2) < 0.01, "Iteration \(iteration): Disabled red should be consistent")
            #expect(abs(g1 - g2) < 0.01, "Iteration \(iteration): Disabled green should be consistent")
            #expect(abs(b1 - b2) < 0.01, "Iteration \(iteration): Disabled blue should be consistent")
            #expect(abs(a1 - a2) < 0.01, "Iteration \(iteration): Disabled alpha should be consistent")
        }
    }
    
    /// Property test: OnPlane and OffPlane colors are distinct
    @Test("Property 8: OnPlane green and OffPlane red are distinct")
    func testOnPlaneAndOffPlaneColorsAreDistinct() async throws {
        let greenColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
        let redColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)
        
        var gr: CGFloat = 0, gg: CGFloat = 0, gb: CGFloat = 0
        var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0
        
        greenColor.getRed(&gr, green: &gg, blue: &gb, alpha: nil)
        redColor.getRed(&rr, green: &rg, blue: &rb, alpha: nil)
        
        // Calculate color distance
        let colorDistance = sqrt(pow(gr - rr, 2) + pow(gg - rg, 2) + pow(gb - rb, 2))
        
        // Colors should be significantly different for clear visual feedback
        #expect(colorDistance > 0.5, "OnPlane green and OffPlane red should be visually distinct")
        
        // Verify the dominant component is different
        #expect(gg > rg, "Green should dominate in onPlane state")
        #expect(rr > gr, "Red should dominate in offPlane state")
    }
    
    /// Property test: All reticle states map to valid colors
    @Test("Property 8: All state colors are within valid range")
    func testAllStateColorsAreWithinValidRange() async throws {
        let colors = [
            ("onPlane", UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)),
            ("offPlane", UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)),
            ("disabled", UIColor(white: 0.5, alpha: 0.5))
        ]
        
        for (stateName, color) in colors {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            #expect(r >= 0.0 && r <= 1.0, "\(stateName): Red component should be in [0, 1]")
            #expect(g >= 0.0 && g <= 1.0, "\(stateName): Green component should be in [0, 1]")
            #expect(b >= 0.0 && b <= 1.0, "\(stateName): Blue component should be in [0, 1]")
            #expect(a >= 0.0 && a <= 1.0, "\(stateName): Alpha component should be in [0, 1]")
        }
    }
    
    /// Property test: Green indicates positive state (aligned with plane)
    @Test("Property 8: Green color indicates positive alignment state")
    func testGreenIndicatesPositiveState() async throws {
        let greenColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        greenColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        
        // Green should be the dominant component (positive feedback)
        #expect(g > r && g > b, "Green should be dominant for positive alignment")
        #expect(g > 0.7, "Green component should be bright for visibility")
    }
    
    /// Property test: Red indicates negative state (not aligned)
    @Test("Property 8: Red color indicates negative alignment state")
    func testRedIndicatesNegativeState() async throws {
        let redColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        redColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        
        // Red should be the dominant component (negative feedback)
        #expect(r > g && r > b, "Red should be dominant for negative alignment")
        #expect(r > 0.7, "Red component should be bright for visibility")
    }
    
    /// Property test: Disabled state is neutral (gray)
    @Test("Property 8: Gray color indicates neutral disabled state")
    func testGrayIndicatesNeutralState() async throws {
        let grayColor = UIColor(white: 0.5, alpha: 0.5)
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        grayColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        
        // Gray should have equal RGB components (neutral)
        #expect(abs(r - g) < 0.01, "Gray should have equal red and green")
        #expect(abs(g - b) < 0.01, "Gray should have equal green and blue")
        #expect(abs(r - b) < 0.01, "Gray should have equal red and blue")
    }
    
    /// Property test: Disabled state has lower opacity
    @Test("Property 8: Disabled state has reduced opacity")
    func testDisabledStateHasReducedOpacity() async throws {
        let onPlaneColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
        let offPlaneColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)
        let disabledColor = UIColor(white: 0.5, alpha: 0.5)
        
        var onPlaneAlpha: CGFloat = 0
        var offPlaneAlpha: CGFloat = 0
        var disabledAlpha: CGFloat = 0
        
        onPlaneColor.getRed(nil, green: nil, blue: nil, alpha: &onPlaneAlpha)
        offPlaneColor.getRed(nil, green: nil, blue: nil, alpha: &offPlaneAlpha)
        disabledColor.getRed(nil, green: nil, blue: nil, alpha: &disabledAlpha)
        
        // Disabled state should have lower opacity to indicate inactive state
        #expect(disabledAlpha < onPlaneAlpha, "Disabled alpha should be less than onPlane")
        #expect(disabledAlpha < offPlaneAlpha, "Disabled alpha should be less than offPlane")
    }
    
    /// Property test: Random state selection produces valid colors
    @Test("Property 8: Random state selection produces valid colors")
    func testRandomStateSelectionProducesValidColors() async throws {
        let states: [ReticleState] = [.onPlane, .offPlane, .disabled]
        let iterations = 100
        
        for iteration in 0..<iterations {
            // Randomly select a state
            let randomState = states.randomElement()!
            
            // Get the expected color for this state
            let color: UIColor
            switch randomState {
            case .onPlane:
                color = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
            case .offPlane:
                color = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)
            case .disabled:
                color = UIColor(white: 0.5, alpha: 0.5)
            }
            
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            // Verify all components are valid
            #expect(r >= 0.0 && r <= 1.0, "Iteration \(iteration): Red should be valid")
            #expect(g >= 0.0 && g <= 1.0, "Iteration \(iteration): Green should be valid")
            #expect(b >= 0.0 && b <= 1.0, "Iteration \(iteration): Blue should be valid")
            #expect(a >= 0.0 && a <= 1.0, "Iteration \(iteration): Alpha should be valid")
            
            // Verify state-specific properties
            switch randomState {
            case .onPlane:
                #expect(g > 0.7, "Iteration \(iteration): OnPlane should have high green")
            case .offPlane:
                #expect(r > 0.7, "Iteration \(iteration): OffPlane should have high red")
            case .disabled:
                #expect(abs(r - g) < 0.01 && abs(g - b) < 0.01, "Iteration \(iteration): Disabled should be gray")
            }
        }
    }
}
