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
    
    var showDimensions: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var showBoundingBoxes: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var showConfidence: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var showObjectLabels: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var showDimensionLines: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Visual styling
    var boundingBoxColor: UIColor = .systemGreen
    var boundingBoxLineWidth: CGFloat = 2.0
    var dimensionTextColor: UIColor = .white
    var dimensionBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.7)
    var dimensionFont: UIFont = .systemFont(ofSize: 14, weight: .bold)
    var labelFont: UIFont = .systemFont(ofSize: 12, weight: .medium)
    var dimensionLineColor: UIColor = .systemYellow
    var dimensionLineWidth: CGFloat = 1.5
    
    // MARK: - Real-time Measurement Properties
    private var realtimeDimensions: ObjectDimensions?
    private var realtimeIndicatorPosition: CGPoint?
    private var isRealtimeMeasurementActive: Bool = false
    private var measurementFailureState: Bool = false
    
    // Real-time dimension labels
    private let lengthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.85)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.alpha = 0
        return label
    }()
    
    private let widthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.85)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.alpha = 0
        return label
    }()
    
    private let heightLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.85)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.alpha = 0
        return label
    }()
    
    // Measurement indicator view
    private let measurementIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.alpha = 0
        return view
    }()
    
    // Failure state label
    private let failureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
        label.textAlignment = .center
        label.text = "測量失敗 - 請調整角度或距離"
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.numberOfLines = 0
        label.alpha = 0
        return label
    }()
    
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
        
        // Add real-time measurement labels
        addSubview(lengthLabel)
        addSubview(widthLabel)
        addSubview(heightLabel)
        addSubview(measurementIndicator)
        addSubview(failureLabel)
        
        // Setup measurement indicator
        setupMeasurementIndicator()
    }
    
    private func setupMeasurementIndicator() {
        // Create crosshair indicator
        let crosshairSize: CGFloat = 40
        let lineWidth: CGFloat = 2
        
        let horizontalLine = UIView()
        horizontalLine.backgroundColor = .systemYellow
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        measurementIndicator.addSubview(horizontalLine)
        
        let verticalLine = UIView()
        verticalLine.backgroundColor = .systemYellow
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        measurementIndicator.addSubview(verticalLine)
        
        NSLayoutConstraint.activate([
            horizontalLine.centerXAnchor.constraint(equalTo: measurementIndicator.centerXAnchor),
            horizontalLine.centerYAnchor.constraint(equalTo: measurementIndicator.centerYAnchor),
            horizontalLine.widthAnchor.constraint(equalToConstant: crosshairSize),
            horizontalLine.heightAnchor.constraint(equalToConstant: lineWidth),
            
            verticalLine.centerXAnchor.constraint(equalTo: measurementIndicator.centerXAnchor),
            verticalLine.centerYAnchor.constraint(equalTo: measurementIndicator.centerYAnchor),
            verticalLine.widthAnchor.constraint(equalToConstant: lineWidth),
            verticalLine.heightAnchor.constraint(equalToConstant: crosshairSize)
        ])
        
        // Add pulsing animation
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 0.8
        pulseAnimation.toValue = 1.2
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        measurementIndicator.layer.add(pulseAnimation, forKey: "pulse")
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
            drawBoundingBox(object.boundingBox, confidence: object.confidence, in: context)
        }
        
        // Draw object label
        if showObjectLabels {
            drawObjectLabel(object.objectType, at: object.boundingBox, in: context)
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
    
    private func drawBoundingBox(_ box: CGRect, confidence: Float, in context: CGContext) {
        context.saveGState()
        
        // Set stroke color based on confidence level
        let color = getColorForConfidence(confidence)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(boundingBoxLineWidth)
        
        // Draw rectangle
        context.stroke(box)
        
        // Draw corner markers for better visibility
        let cornerLength: CGFloat = 20
        drawCornerMarkers(in: box, length: cornerLength, color: color, context: context)
        
        context.restoreGState()
    }
    
    private func getColorForConfidence(_ confidence: Float) -> UIColor {
        if confidence >= 0.9 {
            return .systemGreen
        } else if confidence >= 0.7 {
            return .systemYellow
        } else {
            return .systemOrange
        }
    }
    
    private func drawCornerMarkers(in box: CGRect, length: CGFloat, color: UIColor, context: CGContext) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(boundingBoxLineWidth + 1)
        
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
    
    private func drawObjectLabel(_ objectType: ObjectType, at box: CGRect, in context: CGContext) {
        let labelText = objectType.displayName
        let attributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.white
        ]
        
        let attributedText = NSAttributedString(string: labelText, attributes: attributes)
        let textSize = attributedText.size()
        
        // Position label at top-left of bounding box
        let padding: CGFloat = 4
        let labelPosition = CGPoint(x: box.minX, y: box.minY - textSize.height - padding * 2 - 5)
        
        // Draw background
        let backgroundRect = CGRect(
            x: labelPosition.x - padding,
            y: labelPosition.y - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        context.saveGState()
        context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.8).cgColor)
        let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 4)
        context.addPath(path.cgPath)
        context.fillPath()
        context.restoreGState()
        
        // Draw text
        attributedText.draw(at: labelPosition)
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
        guard showDimensionLines else { return }
        
        context.saveGState()
        
        context.setStrokeColor(dimensionLineColor.cgColor)
        context.setLineWidth(dimensionLineWidth)
        
        // Get preferred unit
        let unit = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
        let measurementUnit = MeasurementUnit(rawValue: unit) ?? .centimeters
        let factor = measurementUnit.conversionFactor
        let unitSymbol = measurementUnit.symbol
        
        // Draw width line (top)
        let widthY = box.minY - 35
        context.move(to: CGPoint(x: box.minX, y: widthY))
        context.addLine(to: CGPoint(x: box.maxX, y: widthY))
        context.strokePath()
        
        // Draw width label
        let widthText = String(format: "%.1f%@", dimensions.width * factor, unitSymbol)
        drawDimensionLabel(widthText, at: CGPoint(x: box.midX, y: widthY - 15), in: context)
        
        // Draw arrow caps for width
        drawArrowCaps(at: CGPoint(x: box.minX, y: widthY), direction: .left, context: context)
        drawArrowCaps(at: CGPoint(x: box.maxX, y: widthY), direction: .right, context: context)
        
        // Draw height line (right)
        let heightX = box.maxX + 15
        context.move(to: CGPoint(x: heightX, y: box.minY))
        context.addLine(to: CGPoint(x: heightX, y: box.maxY))
        context.strokePath()
        
        // Draw height label
        let heightText = String(format: "%.1f%@", dimensions.height * factor, unitSymbol)
        drawDimensionLabel(heightText, at: CGPoint(x: heightX + 5, y: box.midY), in: context)
        
        // Draw arrow caps for height
        drawArrowCaps(at: CGPoint(x: heightX, y: box.minY), direction: .up, context: context)
        drawArrowCaps(at: CGPoint(x: heightX, y: box.maxY), direction: .down, context: context)
        
        context.restoreGState()
    }
    
    private func drawDimensionLabel(_ text: String, at position: CGPoint, in context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        
        // Draw background
        let padding: CGFloat = 3
        let backgroundRect = CGRect(
            x: position.x - textSize.width / 2 - padding,
            y: position.y - textSize.height / 2 - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        context.saveGState()
        context.setFillColor(UIColor.systemYellow.withAlphaComponent(0.9).cgColor)
        let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 3)
        context.addPath(path.cgPath)
        context.fillPath()
        context.restoreGState()
        
        // Draw text
        let textPosition = CGPoint(
            x: position.x - textSize.width / 2,
            y: position.y - textSize.height / 2
        )
        attributedText.draw(at: textPosition)
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
    
    // MARK: - Public Methods
    
    /// Update the overlay with new detected objects
    func updateObjects(_ objects: [DetectedObject]) {
        self.detectedObjects = objects
    }
    
    /// Clear all detected objects from the overlay
    func clearOverlay() {
        self.detectedObjects = []
    }
    
    /// Toggle visibility of specific overlay elements
    func toggleElement(_ element: OverlayElement, visible: Bool) {
        switch element {
        case .boundingBoxes:
            showBoundingBoxes = visible
        case .dimensions:
            showDimensions = visible
        case .confidence:
            showConfidence = visible
        case .labels:
            showObjectLabels = visible
        case .dimensionLines:
            showDimensionLines = visible
        }
    }
    
    /// Configure visual styling
    func configureStyle(boundingBoxColor: UIColor? = nil,
                       dimensionTextColor: UIColor? = nil,
                       dimensionLineColor: UIColor? = nil) {
        if let boxColor = boundingBoxColor {
            self.boundingBoxColor = boxColor
        }
        if let textColor = dimensionTextColor {
            self.dimensionTextColor = textColor
        }
        if let lineColor = dimensionLineColor {
            self.dimensionLineColor = lineColor
        }
        setNeedsDisplay()
    }
    
    // MARK: - Real-time Measurement Methods
    
    /// Update real-time measurement display with smooth animation
    func updateRealtimeMeasurement(_ dimensions: ObjectDimensions) {
        print("📐 MeasurementOverlayView.updateRealtimeMeasurement called")
        print("   Dimensions: L=\(dimensions.length), W=\(dimensions.width), H=\(dimensions.height)")
        print("   Labels alpha: length=\(lengthLabel.alpha), width=\(widthLabel.alpha), height=\(heightLabel.alpha)")
        print("   View bounds: \(bounds)")
        
        realtimeDimensions = dimensions
        isRealtimeMeasurementActive = true
        measurementFailureState = false
        
        // Get preferred unit
        let unit = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
        let measurementUnit = MeasurementUnit(rawValue: unit) ?? .centimeters
        let factor = measurementUnit.conversionFactor
        let unitSymbol = measurementUnit.symbol
        
        // Update label texts
        let lengthText = String(format: "長: %.1f%@", dimensions.length * factor, unitSymbol)
        let widthText = String(format: "寬: %.1f%@", dimensions.width * factor, unitSymbol)
        let heightText = String(format: "高: %.1f%@", dimensions.height * factor, unitSymbol)
        
        print("   Label texts: \(lengthText), \(widthText), \(heightText)")
        
        // Animate label updates with smooth transition
        UIView.transition(with: lengthLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.lengthLabel.text = lengthText
        }
        
        UIView.transition(with: widthLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.widthLabel.text = widthText
        }
        
        UIView.transition(with: heightLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.heightLabel.text = heightText
        }
        
        // Show labels with animation if not already visible
        if lengthLabel.alpha == 0 {
            print("   Showing labels (alpha was 0)")
            showRealtimeLabels()
        } else {
            print("   Labels already visible (alpha=\(lengthLabel.alpha))")
        }
        
        // Hide failure label if visible
        if failureLabel.alpha > 0 {
            hideFailureLabel()
        }
        
        // Update label positions
        updateLabelPositions()
        
        print("   ✅ updateRealtimeMeasurement completed")
    }
    
    /// Show measurement indicator at specific position
    func showMeasurementIndicator(at position: CGPoint) {
        realtimeIndicatorPosition = position
        measurementIndicator.center = position
        
        UIView.animate(withDuration: 0.2) {
            self.measurementIndicator.alpha = 1.0
        }
    }
    
    /// Clear real-time measurement display
    func clearRealtimeMeasurement() {
        realtimeDimensions = nil
        isRealtimeMeasurementActive = false
        measurementFailureState = false
        
        hideRealtimeLabels()
        hideMeasurementIndicator()
        hideFailureLabel()
    }
    
    /// Show measurement failure state
    func showMeasurementFailure() {
        measurementFailureState = true
        isRealtimeMeasurementActive = false
        
        // Hide measurement labels
        hideRealtimeLabels()
        
        // Show failure label
        showFailureLabel()
    }
    
    // MARK: - Private Real-time Methods
    
    private func showRealtimeLabels() {
        print("   🎨 showRealtimeLabels called")
        print("      Label frames before: length=\(lengthLabel.frame), width=\(widthLabel.frame), height=\(heightLabel.frame)")
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.lengthLabel.alpha = 1.0
            self.widthLabel.alpha = 1.0
            self.heightLabel.alpha = 1.0
            print("      Setting alpha to 1.0")
        } completion: { _ in
            print("      Animation completed, alpha: \(self.lengthLabel.alpha)")
        }
    }
    
    private func hideRealtimeLabels() {
        UIView.animate(withDuration: 0.2) {
            self.lengthLabel.alpha = 0
            self.widthLabel.alpha = 0
            self.heightLabel.alpha = 0
        }
    }
    
    private func hideMeasurementIndicator() {
        UIView.animate(withDuration: 0.2) {
            self.measurementIndicator.alpha = 0
        }
    }
    
    private func showFailureLabel() {
        // Position failure label at center
        failureLabel.frame = CGRect(
            x: bounds.midX - 150,
            y: bounds.midY - 30,
            width: 300,
            height: 60
        )
        
        UIView.animate(withDuration: 0.3) {
            self.failureLabel.alpha = 1.0
        }
    }
    
    private func hideFailureLabel() {
        UIView.animate(withDuration: 0.2) {
            self.failureLabel.alpha = 0
        }
    }
    
    private func updateLabelPositions() {
        let padding: CGFloat = 20
        let labelHeight: CGFloat = 36
        let labelWidth: CGFloat = 120
        
        // Position labels vertically on the left side
        let startY = bounds.midY - (labelHeight * 1.5 + padding)
        
        print("   📍 updateLabelPositions called")
        print("      Bounds: \(bounds)")
        print("      StartY: \(startY)")
        
        lengthLabel.frame = CGRect(
            x: padding,
            y: startY,
            width: labelWidth,
            height: labelHeight
        )
        
        widthLabel.frame = CGRect(
            x: padding,
            y: startY + labelHeight + 10,
            width: labelWidth,
            height: labelHeight
        )
        
        heightLabel.frame = CGRect(
            x: padding,
            y: startY + (labelHeight + 10) * 2,
            width: labelWidth,
            height: labelHeight
        )
        
        print("      Label frames set: length=\(lengthLabel.frame), width=\(widthLabel.frame), height=\(heightLabel.frame)")
        print("      Label superview: \(lengthLabel.superview != nil ? "exists" : "nil")")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update label positions when view bounds change
        if isRealtimeMeasurementActive {
            updateLabelPositions()
        }
        
        // Update failure label position
        if measurementFailureState {
            failureLabel.frame = CGRect(
                x: bounds.midX - 150,
                y: bounds.midY - 30,
                width: 300,
                height: 60
            )
        }
    }
    
    // MARK: - Helper Types
    
    enum OverlayElement {
        case boundingBoxes
        case dimensions
        case confidence
        case labels
        case dimensionLines
    }
    
    private enum ArrowDirection {
        case left, right, up, down
    }
}
