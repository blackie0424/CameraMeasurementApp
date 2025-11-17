//
//  MeasurementOverlayView.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import UIKit

class MeasurementOverlayView: UIView {
    
    // MARK: - Properties
    var detectedObjects: [DetectedObject] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var showDimensions: Bool = true
    var showBoundingBoxes: Bool = true
    var showConfidence: Bool = true
    
    // Visual styling
    var boundingBoxColor: UIColor = .systemGreen
    var boundingBoxLineWidth: CGFloat = 2.0
    var dimensionTextColor: UIColor = .white
    var dimensionBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.7)
    var dimensionFont: UIFont = .systemFont(ofSize: 14, weight: .bold)
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isOpaque = false
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        for object in detectedObjects {
            drawObject(object, in: context)
        }
    }
    
    private func drawObject(_ object: DetectedObject, in context: CGContext) {
        // Draw bounding box
        if showBoundingBoxes {
            drawBoundingBox(object.boundingBox, in: context)
        }
        
        // Draw dimensions
        if showDimensions, let dimensions = object.dimensions {
            drawDimensions(dimensions, for: object, in: context)
        }
        
        // Draw confidence indicator
        if showConfidence {
            drawConfidence(object.confidence, at: object.boundingBox, in: context)
        }
    }
    
    private func drawBoundingBox(_ box: CGRect, in context: CGContext) {
        context.saveGState()
        
        // Set stroke properties
        context.setStrokeColor(boundingBoxColor.cgColor)
        context.setLineWidth(boundingBoxLineWidth)
        
        // Draw rectangle
        context.stroke(box)
        
        // Draw corner markers for better visibility
        let cornerLength: CGFloat = 20
        drawCornerMarkers(in: box, length: cornerLength, context: context)
        
        context.restoreGState()
    }
    
    private func drawCornerMarkers(in box: CGRect, length: CGFloat, context: CGContext) {
        let corners = [
            (box.minX, box.minY), // Top-left
            (box.maxX, box.minY), // Top-right
            (box.minX, box.maxY), // Bottom-left
            (box.maxX, box.maxY)  // Bottom-right
        ]
        
        for (x, y) in corners {
            // Horizontal line
            context.move(to: CGPoint(x: x, y: y))
            let hEndX = x + (x == box.minX ? length : -length)
            context.addLine(to: CGPoint(x: hEndX, y: y))
            
            // Vertical line
            context.move(to: CGPoint(x: x, y: y))
            let vEndY = y + (y == box.minY ? length : -length)
            context.addLine(to: CGPoint(x: x, y: vEndY))
        }
        
        context.strokePath()
    }
    
    private func drawDimensions(_ dimensions: ObjectDimensions, for object: DetectedObject, in context: CGContext) {
        let box = object.boundingBox
        
        // Get preferred unit
        let unit = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
        let measurementUnit = MeasurementUnit(rawValue: unit) ?? .centimeters
        
        // Format dimension text
        let dimensionText = dimensions.formattedDimensions(unit: measurementUnit)
        
        // Calculate text position (above bounding box)
        let textPosition = CGPoint(x: box.minX, y: box.minY - 30)
        
        // Draw text with background
        drawTextWithBackground(dimensionText, at: textPosition, in: context)
        
        // Draw dimension lines
        drawDimensionLines(for: box, dimensions: dimensions, in: context)
    }
    
    private func drawTextWithBackground(_ text: String, at position: CGPoint, in context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: dimensionFont,
            .foregroundColor: dimensionTextColor
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        
        // Draw background
        let padding: CGFloat = 6
        let backgroundRect = CGRect(
            x: position.x - padding,
            y: position.y - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        context.saveGState()
        context.setFillColor(dimensionBackgroundColor.cgColor)
        context.fill(backgroundRect)
        context.restoreGState()
        
        // Draw text
        attributedText.draw(at: position)
    }
    
    private func drawDimensionLines(for box: CGRect, dimensions: ObjectDimensions, in context: CGContext) {
        context.saveGState()
        
        context.setStrokeColor(UIColor.systemYellow.cgColor)
        context.setLineWidth(1.5)
        
        // Draw width line (top)
        let widthY = box.minY - 5
        context.move(to: CGPoint(x: box.minX, y: widthY))
        context.addLine(to: CGPoint(x: box.maxX, y: widthY))
        
        // Draw height line (right)
        let heightX = box.maxX + 5
        context.move(to: CGPoint(x: heightX, y: box.minY))
        context.addLine(to: CGPoint(x: heightX, y: box.maxY))
        
        context.strokePath()
        
        // Draw arrow caps
        drawArrowCaps(at: CGPoint(x: box.minX, y: widthY), direction: .left, context: context)
        drawArrowCaps(at: CGPoint(x: box.maxX, y: widthY), direction: .right, context: context)
        drawArrowCaps(at: CGPoint(x: heightX, y: box.minY), direction: .up, context: context)
        drawArrowCaps(at: CGPoint(x: heightX, y: box.maxY), direction: .down, context: context)
        
        context.restoreGState()
    }
    
    private func drawArrowCaps(at point: CGPoint, direction: ArrowDirection, context: CGContext) {
        let arrowSize: CGFloat = 5
        
        context.saveGState()
        context.setFillColor(UIColor.systemYellow.cgColor)
        
        let path = UIBezierPath()
        
        switch direction {
        case .left:
            path.move(to: point)
            path.addLine(to: CGPoint(x: point.x + arrowSize, y: point.y - arrowSize))
            path.addLine(to: CGPoint(x: point.x + arrowSize, y: point.y + arrowSize))
        case .right:
            path.move(to: point)
            path.addLine(to: CGPoint(x: point.x - arrowSize, y: point.y - arrowSize))
            path.addLine(to: CGPoint(x: point.x - arrowSize, y: point.y + arrowSize))
        case .up:
            path.move(to: point)
            path.addLine(to: CGPoint(x: point.x - arrowSize, y: point.y + arrowSize))
            path.addLine(to: CGPoint(x: point.x + arrowSize, y: point.y + arrowSize))
        case .down:
            path.move(to: point)
            path.addLine(to: CGPoint(x: point.x - arrowSize, y: point.y - arrowSize))
            path.addLine(to: CGPoint(x: point.x + arrowSize, y: point.y - arrowSize))
        }
        
        path.close()
        path.fill()
        
        context.restoreGState()
    }
    
    private func drawConfidence(_ confidence: Float, at box: CGRect, in context: CGContext) {
        let confidenceText = String(format: "%.0f%%", confidence * 100)
        let position = CGPoint(x: box.maxX - 50, y: box.minY + 5)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let attributedText = NSAttributedString(string: confidenceText, attributes: attributes)
        let textSize = attributedText.size()
        
        // Draw background
        let padding: CGFloat = 4
        let backgroundRect = CGRect(
            x: position.x - padding,
            y: position.y - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        context.saveGState()
        
        // Color based on confidence level
        let backgroundColor: UIColor
        if confidence >= 0.9 {
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        } else if confidence >= 0.7 {
            backgroundColor = UIColor.systemYellow.withAlphaComponent(0.8)
        } else {
            backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        }
        
        context.setFillColor(backgroundColor.cgColor)
        context.fill(backgroundRect)
        context.restoreGState()
        
        // Draw text
        attributedText.draw(at: position)
    }
    
    // MARK: - Helper Types
    private enum ArrowDirection {
        case left, right, up, down
    }
}
