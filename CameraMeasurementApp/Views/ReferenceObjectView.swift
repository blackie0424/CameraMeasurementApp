//
//  ReferenceObjectView.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import UIKit

class ReferenceObjectView: UIView {
    
    // MARK: - Properties
    var referenceObject: ReferenceObject? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var showDimensions: Bool = true
    var showName: Bool = true
    
    // Visual styling
    var objectColor: UIColor = .systemBlue
    var dimensionTextColor: UIColor = .white
    var nameTextColor: UIColor = .systemGray
    var backgroundColor3D: UIColor = UIColor.black.withAlphaComponent(0.3)
    
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
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext(),
              let reference = referenceObject else { return }
        
        // Draw background
        context.setFillColor(backgroundColor3D.cgColor)
        context.fill(rect)
        
        // Draw 3D representation of reference object
        draw3DRepresentation(of: reference, in: rect, context: context)
        
        // Draw object name
        if showName {
            drawObjectName(reference.name, in: rect)
        }
        
        // Draw dimensions
        if showDimensions {
            drawObjectDimensions(reference.standardDimensions, in: rect)
        }
    }
    
    private func draw3DRepresentation(of reference: ReferenceObject, in rect: CGRect, context: CGContext) {
        // Calculate drawing area (leave space for text)
        let drawingRect = CGRect(
            x: rect.minX + 20,
            y: rect.minY + 40,
            width: rect.width - 40,
            height: rect.height - 80
        )
        
        // Draw based on object category
        switch reference.category {
        case .everyday:
            if reference.name.contains("打火機") {
                drawLighter(in: drawingRect, context: context)
            } else if reference.name.contains("信用卡") {
                drawCreditCard(in: drawingRect, context: context)
            } else {
                drawGenericBox(in: drawingRect, context: context)
            }
        case .currency:
            drawCoin(in: drawingRect, context: context)
        case .electronics:
            drawPhone(in: drawingRect, context: context)
        case .stationery:
            drawPen(in: drawingRect, context: context)
        case .furniture:
            drawGenericBox(in: drawingRect, context: context)
        case .unknown:
            drawGenericBox(in: drawingRect, context: context)
        }
    }
    
    private func drawLighter(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        // Draw lighter body (3D perspective)
        let bodyRect = CGRect(
            x: rect.midX - 30,
            y: rect.midY - 40,
            width: 60,
            height: 80
        )
        
        // Main body
        context.setFillColor(objectColor.cgColor)
        context.fill(bodyRect)
        
        // 3D effect - right side
        let rightSide = UIBezierPath()
        rightSide.move(to: CGPoint(x: bodyRect.maxX, y: bodyRect.minY))
        rightSide.addLine(to: CGPoint(x: bodyRect.maxX + 15, y: bodyRect.minY + 10))
        rightSide.addLine(to: CGPoint(x: bodyRect.maxX + 15, y: bodyRect.maxY + 10))
        rightSide.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY))
        rightSide.close()
        
        context.setFillColor(objectColor.withAlphaComponent(0.7).cgColor)
        rightSide.fill()
        
        // Top cap
        let topRect = CGRect(x: bodyRect.minX, y: bodyRect.minY - 10, width: bodyRect.width, height: 10)
        context.setFillColor(UIColor.systemGray.cgColor)
        context.fill(topRect)
        
        context.restoreGState()
    }
    
    private func drawCreditCard(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        // Draw card (3D perspective)
        let cardRect = CGRect(
            x: rect.midX - 60,
            y: rect.midY - 35,
            width: 120,
            height: 70
        )
        
        // Main card
        context.setFillColor(objectColor.cgColor)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
        cardPath.fill()
        
        // 3D effect - bottom edge
        let bottomEdge = UIBezierPath()
        bottomEdge.move(to: CGPoint(x: cardRect.minX, y: cardRect.maxY))
        bottomEdge.addLine(to: CGPoint(x: cardRect.minX + 10, y: cardRect.maxY + 8))
        bottomEdge.addLine(to: CGPoint(x: cardRect.maxX + 10, y: cardRect.maxY + 8))
        bottomEdge.addLine(to: CGPoint(x: cardRect.maxX, y: cardRect.maxY))
        bottomEdge.close()
        
        context.setFillColor(objectColor.withAlphaComponent(0.6).cgColor)
        bottomEdge.fill()
        
        // Magnetic stripe
        let stripeRect = CGRect(x: cardRect.minX + 10, y: cardRect.minY + 15, width: cardRect.width - 20, height: 12)
        context.setFillColor(UIColor.darkGray.cgColor)
        context.fill(stripeRect)
        
        context.restoreGState()
    }
    
    private func drawCoin(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        let radius: CGFloat = 40
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Main coin
        context.setFillColor(objectColor.cgColor)
        context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        
        // 3D effect - edge
        let edgePath = UIBezierPath()
        edgePath.move(to: CGPoint(x: center.x - radius, y: center.y))
        edgePath.addLine(to: CGPoint(x: center.x - radius + 5, y: center.y + 5))
        edgePath.addArc(withCenter: CGPoint(x: center.x, y: center.y + 5), radius: radius - 5, startAngle: .pi, endAngle: 0, clockwise: false)
        edgePath.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        edgePath.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: .pi, clockwise: true)
        edgePath.close()
        
        context.setFillColor(objectColor.withAlphaComponent(0.7).cgColor)
        edgePath.fill()
        
        // Inner circle detail
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: CGRect(x: center.x - radius + 10, y: center.y - radius + 10, width: (radius - 10) * 2, height: (radius - 10) * 2))
        
        context.restoreGState()
    }
    
    private func drawPhone(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        // Draw phone (3D perspective)
        let phoneRect = CGRect(
            x: rect.midX - 35,
            y: rect.midY - 60,
            width: 70,
            height: 120
        )
        
        // Main phone body
        context.setFillColor(objectColor.cgColor)
        let phonePath = UIBezierPath(roundedRect: phoneRect, cornerRadius: 12)
        phonePath.fill()
        
        // Screen
        let screenRect = phoneRect.insetBy(dx: 5, dy: 10)
        context.setFillColor(UIColor.black.cgColor)
        let screenPath = UIBezierPath(roundedRect: screenRect, cornerRadius: 8)
        screenPath.fill()
        
        // 3D effect - right edge
        let rightEdge = UIBezierPath()
        rightEdge.move(to: CGPoint(x: phoneRect.maxX, y: phoneRect.minY + 12))
        rightEdge.addLine(to: CGPoint(x: phoneRect.maxX + 8, y: phoneRect.minY + 16))
        rightEdge.addLine(to: CGPoint(x: phoneRect.maxX + 8, y: phoneRect.maxY + 16))
        rightEdge.addLine(to: CGPoint(x: phoneRect.maxX, y: phoneRect.maxY - 12))
        rightEdge.close()
        
        context.setFillColor(objectColor.withAlphaComponent(0.6).cgColor)
        rightEdge.fill()
        
        // Camera notch
        let notchRect = CGRect(x: phoneRect.midX - 15, y: phoneRect.minY + 5, width: 30, height: 5)
        context.setFillColor(UIColor.darkGray.cgColor)
        let notchPath = UIBezierPath(roundedRect: notchRect, cornerRadius: 2.5)
        notchPath.fill()
        
        context.restoreGState()
    }
    
    private func drawPen(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        // Draw pen (3D perspective)
        let penLength: CGFloat = 100
        let penWidth: CGFloat = 12
        
        let penRect = CGRect(
            x: rect.midX - penLength / 2,
            y: rect.midY - penWidth / 2,
            width: penLength,
            height: penWidth
        )
        
        // Main pen body
        context.setFillColor(objectColor.cgColor)
        let penPath = UIBezierPath(roundedRect: penRect, cornerRadius: penWidth / 2)
        penPath.fill()
        
        // Pen tip
        let tipPath = UIBezierPath()
        tipPath.move(to: CGPoint(x: penRect.maxX, y: penRect.midY))
        tipPath.addLine(to: CGPoint(x: penRect.maxX + 15, y: penRect.midY - 3))
        tipPath.addLine(to: CGPoint(x: penRect.maxX + 15, y: penRect.midY + 3))
        tipPath.close()
        
        context.setFillColor(UIColor.darkGray.cgColor)
        tipPath.fill()
        
        // Clip
        let clipRect = CGRect(x: penRect.minX + 20, y: penRect.minY - 8, width: 3, height: 16)
        context.setFillColor(UIColor.systemGray.cgColor)
        context.fill(clipRect)
        
        context.restoreGState()
    }
    
    private func drawGenericBox(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        // Draw generic 3D box
        let boxRect = CGRect(
            x: rect.midX - 40,
            y: rect.midY - 30,
            width: 80,
            height: 60
        )
        
        // Front face
        context.setFillColor(objectColor.cgColor)
        context.fill(boxRect)
        
        // Right face
        let rightFace = UIBezierPath()
        rightFace.move(to: CGPoint(x: boxRect.maxX, y: boxRect.minY))
        rightFace.addLine(to: CGPoint(x: boxRect.maxX + 20, y: boxRect.minY + 15))
        rightFace.addLine(to: CGPoint(x: boxRect.maxX + 20, y: boxRect.maxY + 15))
        rightFace.addLine(to: CGPoint(x: boxRect.maxX, y: boxRect.maxY))
        rightFace.close()
        
        context.setFillColor(objectColor.withAlphaComponent(0.7).cgColor)
        rightFace.fill()
        
        // Top face
        let topFace = UIBezierPath()
        topFace.move(to: CGPoint(x: boxRect.minX, y: boxRect.minY))
        topFace.addLine(to: CGPoint(x: boxRect.minX + 20, y: boxRect.minY - 15))
        topFace.addLine(to: CGPoint(x: boxRect.maxX + 20, y: boxRect.minY - 15))
        topFace.addLine(to: CGPoint(x: boxRect.maxX, y: boxRect.minY))
        topFace.close()
        
        context.setFillColor(objectColor.withAlphaComponent(0.5).cgColor)
        topFace.fill()
        
        context.restoreGState()
    }
    
    private func drawObjectName(_ name: String, in rect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: nameTextColor
        ]
        
        let attributedText = NSAttributedString(string: name, attributes: attributes)
        let textSize = attributedText.size()
        
        let textRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.minY + 10,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedText.draw(in: textRect)
    }
    
    private func drawObjectDimensions(_ dimensions: ObjectDimensions, in rect: CGRect) {
        let unit = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
        let measurementUnit = MeasurementUnit(rawValue: unit) ?? .centimeters
        
        let dimensionText = dimensions.formattedDimensions(unit: measurementUnit)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: dimensionTextColor
        ]
        
        let attributedText = NSAttributedString(string: dimensionText, attributes: attributes)
        let textSize = attributedText.size()
        
        let textRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.maxY - 25,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedText.draw(in: textRect)
    }
}
