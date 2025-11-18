//
//  MeasurementAnnotationView.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//  Comprehensive annotation system combining measurements and reference objects
//

import UIKit

/// Comprehensive view that combines measurement overlays with reference object visualization
class MeasurementAnnotationView: UIView {
    
    // MARK: - Subviews
    private let measurementOverlay: MeasurementOverlayView
    private let referenceObjectContainer: UIView
    private var referenceObjectViews: [ReferenceObjectView] = []
    
    // MARK: - Properties
    var detectedObjects: [DetectedObject] = [] {
        didSet {
            measurementOverlay.updateObjects(detectedObjects)
        }
    }
    
    var referenceObjects: [ReferenceObject] = [] {
        didSet {
            updateReferenceObjectViews()
        }
    }
    
    var showReferenceObjects: Bool = true {
        didSet {
            referenceObjectContainer.isHidden = !showReferenceObjects
        }
    }
    
    // Layout configuration
    var referenceObjectSize: CGSize = CGSize(width: 150, height: 180)
    var referenceObjectSpacing: CGFloat = 10
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        measurementOverlay = MeasurementOverlayView(frame: frame)
        referenceObjectContainer = UIView(frame: frame)
        
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        measurementOverlay = MeasurementOverlayView(frame: .zero)
        referenceObjectContainer = UIView(frame: .zero)
        
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // Add measurement overlay
        addSubview(measurementOverlay)
        measurementOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            measurementOverlay.topAnchor.constraint(equalTo: topAnchor),
            measurementOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            measurementOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            measurementOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add reference object container
        addSubview(referenceObjectContainer)
        referenceObjectContainer.translatesAutoresizingMaskIntoConstraints = false
        referenceObjectContainer.backgroundColor = .clear
        NSLayoutConstraint.activate([
            referenceObjectContainer.topAnchor.constraint(equalTo: topAnchor),
            referenceObjectContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            referenceObjectContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            referenceObjectContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        measurementOverlay.frame = bounds
        referenceObjectContainer.frame = bounds
        layoutReferenceObjects()
    }
    
    private func layoutReferenceObjects() {
        let startX = bounds.width - referenceObjectSize.width - 20
        var currentY: CGFloat = 100
        
        for (index, view) in referenceObjectViews.enumerated() {
            view.frame = CGRect(
                x: startX,
                y: currentY,
                width: referenceObjectSize.width,
                height: referenceObjectSize.height
            )
            currentY += referenceObjectSize.height + referenceObjectSpacing
        }
    }
    
    // MARK: - Reference Object Management
    private func updateReferenceObjectViews() {
        // Remove existing views
        referenceObjectViews.forEach { $0.removeFromSuperview() }
        referenceObjectViews.removeAll()
        
        // Create new views for each reference object
        for reference in referenceObjects {
            let refView = ReferenceObjectView(frame: .zero)
            refView.referenceObject = reference
            refView.layer.borderWidth = 2
            refView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
            refView.layer.shadowColor = UIColor.black.cgColor
            refView.layer.shadowOffset = CGSize(width: 0, height: 2)
            refView.layer.shadowOpacity = 0.3
            refView.layer.shadowRadius = 4
            
            referenceObjectContainer.addSubview(refView)
            referenceObjectViews.append(refView)
        }
        
        setNeedsLayout()
    }
    
    // MARK: - Public Methods
    
    /// Update both detected objects and reference objects
    func updateAnnotations(detectedObjects: [DetectedObject], referenceObjects: [ReferenceObject]) {
        self.detectedObjects = detectedObjects
        self.referenceObjects = referenceObjects
    }
    
    /// Clear all annotations
    func clearAnnotations() {
        detectedObjects = []
        referenceObjects = []
        measurementOverlay.clearOverlay()
    }
    
    /// Configure measurement overlay display options
    func configureMeasurementOverlay(showBoundingBoxes: Bool? = nil,
                                    showDimensions: Bool? = nil,
                                    showConfidence: Bool? = nil,
                                    showLabels: Bool? = nil,
                                    showDimensionLines: Bool? = nil) {
        if let show = showBoundingBoxes {
            measurementOverlay.showBoundingBoxes = show
        }
        if let show = showDimensions {
            measurementOverlay.showDimensions = show
        }
        if let show = showConfidence {
            measurementOverlay.showConfidence = show
        }
        if let show = showLabels {
            measurementOverlay.showObjectLabels = show
        }
        if let show = showDimensionLines {
            measurementOverlay.showDimensionLines = show
        }
    }
    
    /// Configure visual styling
    func configureStyle(boundingBoxColor: UIColor? = nil,
                       dimensionTextColor: UIColor? = nil,
                       dimensionLineColor: UIColor? = nil,
                       referenceObjectColor: UIColor? = nil) {
        measurementOverlay.configureStyle(
            boundingBoxColor: boundingBoxColor,
            dimensionTextColor: dimensionTextColor,
            dimensionLineColor: dimensionLineColor
        )
        
        if let refColor = referenceObjectColor {
            referenceObjectViews.forEach { $0.objectColor = refColor }
        }
    }
    
    /// Capture the current annotation view as an image
    func captureAnnotatedImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Export annotation data as text
    func exportAnnotationData() -> String {
        var data = "測量標註資料\n"
        data += "==================\n\n"
        
        data += "檢測到的物體: \(detectedObjects.count)\n"
        for (index, object) in detectedObjects.enumerated() {
            data += "\n物體 \(index + 1):\n"
            data += "  類型: \(object.objectType.displayName)\n"
            data += "  信心度: \(String(format: "%.1f%%", object.confidence * 100))\n"
            
            if let dimensions = object.dimensions {
                let unit = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
                let measurementUnit = MeasurementUnit(rawValue: unit) ?? .centimeters
                data += "  尺寸: \(dimensions.formattedDimensions(unit: measurementUnit))\n"
                data += "  準確度: \(String(format: "%.1f%%", dimensions.accuracy * 100))\n"
            }
        }
        
        if !referenceObjects.isEmpty {
            data += "\n\n參考物件: \(referenceObjects.count)\n"
            for (index, reference) in referenceObjects.enumerated() {
                data += "\n參考物件 \(index + 1):\n"
                data += "  名稱: \(reference.name)\n"
                
                let unit = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
                let measurementUnit = MeasurementUnit(rawValue: unit) ?? .centimeters
                data += "  標準尺寸: \(reference.standardDimensions.formattedDimensions(unit: measurementUnit))\n"
            }
        }
        
        return data
    }
}
