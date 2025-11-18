//
//  AnnotationDrawingExtensions.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//  Shared drawing utilities for annotation views
//

import UIKit

// MARK: - CGContext Drawing Extensions

extension CGContext {
    
    /// Draw a dashed line between two points
    func drawDashedLine(from start: CGPoint, to end: CGPoint, color: UIColor, lineWidth: CGFloat = 1.0, dashPattern: [CGFloat] = [5, 3]) {
        saveGState()
        setStrokeColor(color.cgColor)
        setLineWidth(lineWidth)
        setLineDash(phase: 0, lengths: dashPattern)
        
        move(to: start)
        addLine(to: end)
        strokePath()
        
        restoreGState()
    }
    
    /// Draw a rounded rectangle with gradient
    func drawGradientRoundedRect(_ rect: CGRect, cornerRadius: CGFloat, startColor: UIColor, endColor: UIColor) {
        saveGState()
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        addPath(path.cgPath)
        clip()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [startColor.cgColor, endColor.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            let startPoint = CGPoint(x: rect.midX, y: rect.minY)
            let endPoint = CGPoint(x: rect.midX, y: rect.maxY)
            drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
        
        restoreGState()
    }
    
    /// Draw a shadow for a path
    func drawWithShadow(color: UIColor, offset: CGSize, blur: CGFloat, drawing: () -> Void) {
        saveGState()
        setShadow(offset: offset, blur: blur, color: color.cgColor)
        drawing()
        restoreGState()
    }
}

// MARK: - UIBezierPath Extensions

extension UIBezierPath {
    
    /// Create an arrow path
    static func arrow(from start: CGPoint, to end: CGPoint, headLength: CGFloat = 10, headAngle: CGFloat = .pi / 6) -> UIBezierPath {
        let path = UIBezierPath()
        
        // Main line
        path.move(to: start)
        path.addLine(to: end)
        
        // Calculate arrow head
        let angle = atan2(end.y - start.y, end.x - start.x)
        
        let arrowPoint1 = CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        )
        
        // Draw arrow head
        path.move(to: end)
        path.addLine(to: arrowPoint1)
        path.move(to: end)
        path.addLine(to: arrowPoint2)
        
        return path
    }
    
    /// Create a double-headed arrow path
    static func doubleArrow(from start: CGPoint, to end: CGPoint, headLength: CGFloat = 10, headAngle: CGFloat = .pi / 6) -> UIBezierPath {
        let path = UIBezierPath()
        
        // Main line
        path.move(to: start)
        path.addLine(to: end)
        
        // Calculate angle
        let angle = atan2(end.y - start.y, end.x - start.x)
        
        // Start arrow head
        let startArrow1 = CGPoint(
            x: start.x + headLength * cos(angle - headAngle),
            y: start.y + headLength * sin(angle - headAngle)
        )
        
        let startArrow2 = CGPoint(
            x: start.x + headLength * cos(angle + headAngle),
            y: start.y + headLength * sin(angle + headAngle)
        )
        
        path.move(to: start)
        path.addLine(to: startArrow1)
        path.move(to: start)
        path.addLine(to: startArrow2)
        
        // End arrow head
        let endArrow1 = CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        )
        
        let endArrow2 = CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        )
        
        path.move(to: end)
        path.addLine(to: endArrow1)
        path.move(to: end)
        path.addLine(to: endArrow2)
        
        return path
    }
    
    /// Create a measurement line with tick marks
    static func measurementLine(from start: CGPoint, to end: CGPoint, tickLength: CGFloat = 8) -> UIBezierPath {
        let path = UIBezierPath()
        
        // Main line
        path.move(to: start)
        path.addLine(to: end)
        
        // Calculate perpendicular angle for tick marks
        let angle = atan2(end.y - start.y, end.x - start.x)
        let perpAngle = angle + .pi / 2
        
        // Start tick
        let startTick1 = CGPoint(
            x: start.x + tickLength * cos(perpAngle),
            y: start.y + tickLength * sin(perpAngle)
        )
        let startTick2 = CGPoint(
            x: start.x - tickLength * cos(perpAngle),
            y: start.y - tickLength * sin(perpAngle)
        )
        
        path.move(to: startTick1)
        path.addLine(to: startTick2)
        
        // End tick
        let endTick1 = CGPoint(
            x: end.x + tickLength * cos(perpAngle),
            y: end.y + tickLength * sin(perpAngle)
        )
        let endTick2 = CGPoint(
            x: end.x - tickLength * cos(perpAngle),
            y: end.y - tickLength * sin(perpAngle)
        )
        
        path.move(to: endTick1)
        path.addLine(to: endTick2)
        
        return path
    }
}

// MARK: - Text Drawing Helpers

extension NSAttributedString {
    
    /// Draw text with a background and optional border
    func drawWithBackground(at point: CGPoint,
                           backgroundColor: UIColor,
                           borderColor: UIColor? = nil,
                           borderWidth: CGFloat = 0,
                           cornerRadius: CGFloat = 4,
                           padding: CGFloat = 6) {
        let textSize = self.size()
        
        let backgroundRect = CGRect(
            x: point.x - padding,
            y: point.y - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        // Draw background
        let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: cornerRadius)
        backgroundColor.setFill()
        path.fill()
        
        // Draw border if specified
        if let borderColor = borderColor, borderWidth > 0 {
            borderColor.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
        }
        
        // Draw text
        self.draw(at: point)
    }
    
    /// Draw text centered at a point
    func drawCentered(at point: CGPoint) {
        let textSize = self.size()
        let drawPoint = CGPoint(
            x: point.x - textSize.width / 2,
            y: point.y - textSize.height / 2
        )
        self.draw(at: drawPoint)
    }
}

// MARK: - Color Utilities

extension UIColor {
    
    /// Get a color based on confidence level
    static func confidenceColor(for confidence: Float) -> UIColor {
        switch confidence {
        case 0.9...1.0:
            return .systemGreen
        case 0.7..<0.9:
            return .systemYellow
        case 0.5..<0.7:
            return .systemOrange
        default:
            return .systemRed
        }
    }
    
    /// Get a color with adjusted brightness
    func adjustedBrightness(by amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue,
                          saturation: saturation,
                          brightness: min(max(brightness + amount, 0), 1),
                          alpha: alpha)
        }
        
        return self
    }
}

// MARK: - Geometry Helpers

extension CGRect {
    
    /// Get edge midpoints of the rectangle
    var edgeMidpoints: [CGPoint] {
        return [
            CGPoint(x: midX, y: minY), // Top
            CGPoint(x: maxX, y: midY), // Right
            CGPoint(x: midX, y: maxY), // Bottom
            CGPoint(x: minX, y: midY)  // Left
        ]
    }
    
    /// Expand or contract the rectangle by a given amount
    func adjusted(by amount: CGFloat) -> CGRect {
        return insetBy(dx: -amount, dy: -amount)
    }
}

extension CGPoint {
    
    /// Calculate distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - x
        let dy = point.y - y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Calculate midpoint between two points
    func midpoint(to point: CGPoint) -> CGPoint {
        return CGPoint(x: (x + point.x) / 2, y: (y + point.y) / 2)
    }
}
