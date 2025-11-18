//
//  ImageAnnotationService.swift
//  CameraMeasurementApp
//
//  影像標註服務
//  提供將測量資訊嵌入到照片的完整功能
//

import UIKit
import CoreGraphics

/// 標註樣式配置
struct AnnotationStyle {
    // 顏色配置
    var primaryColor: UIColor = .systemGreen
    var secondaryColor: UIColor = .systemOrange
    var textColor: UIColor = .white
    var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.7)
    var shadowColor: UIColor = .black
    
    // 線條和邊框
    var lineWidth: CGFloat = 3.0
    var cornerRadius: CGFloat = 8.0
    var shadowOpacity: Float = 0.5
    var shadowRadius: CGFloat = 4.0
    
    // 文字樣式
    var titleFont: UIFont = .systemFont(ofSize: 24, weight: .bold)
    var bodyFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
    var captionFont: UIFont = .systemFont(ofSize: 14, weight: .regular)
    
    // 間距和邊距
    var padding: CGFloat = 15
    var spacing: CGFloat = 10
    var margin: CGFloat = 20
    
    static let `default` = AnnotationStyle()
    
    static let compact = AnnotationStyle(
        titleFont: .systemFont(ofSize: 18, weight: .bold),
        bodyFont: .systemFont(ofSize: 14, weight: .medium),
        captionFont: .systemFont(ofSize: 12, weight: .regular),
        padding: 10,
        spacing: 8,
        margin: 15
    )
}

/// 標註佈局選項
enum AnnotationLayout {
    case overlay        // 覆蓋在影像上
    case sidebar        // 側邊欄顯示
    case topBottom      // 上下分佈
    case minimal        // 最小化顯示
}

/// 影像標註服務
class ImageAnnotationService {
    
    // MARK: - Properties
    private var style: AnnotationStyle
    private var layout: AnnotationLayout
    private var measurementUnit: MeasurementUnit
    
    // MARK: - Initialization
    init(style: AnnotationStyle = .default,
         layout: AnnotationLayout = .overlay,
         measurementUnit: MeasurementUnit = .centimeters) {
        self.style = style
        self.layout = layout
        self.measurementUnit = measurementUnit
    }
    
    // MARK: - Public Methods
    
    /// 建立完整標註的影像
    func createAnnotatedImage(from record: MeasurementRecord) -> UIImage? {
        let baseImage = record.image
        let size = baseImage.size
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 繪製原始影像
            baseImage.draw(at: .zero)
            
            let ctx = context.cgContext
            
            // 根據佈局繪製標註
            switch layout {
            case .overlay:
                drawOverlayAnnotations(ctx: ctx, record: record, imageSize: size)
            case .sidebar:
                drawSidebarAnnotations(ctx: ctx, record: record, imageSize: size)
            case .topBottom:
                drawTopBottomAnnotations(ctx: ctx, record: record, imageSize: size)
            case .minimal:
                drawMinimalAnnotations(ctx: ctx, record: record, imageSize: size)
            }
        }
    }
    
    /// 建立帶有測量資訊的影像（簡化版）
    func createQuickAnnotatedImage(image: UIImage,
                                  detectedObjects: [DetectedObject],
                                  referenceObject: ReferenceObject? = nil) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            image.draw(at: .zero)
            
            let ctx = context.cgContext
            
            // 繪製物體標註
            for object in detectedObjects {
                drawObjectAnnotation(ctx: ctx, object: object, imageSize: image.size)
            }
            
            // 繪製參考物件
            if let reference = referenceObject {
                drawReferenceObjectBadge(ctx: ctx, reference: reference, imageSize: image.size)
            }
        }
    }
    
    /// 建立測量資訊文字圖層
    func createTextOverlay(for record: MeasurementRecord, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 繪製半透明背景
            ctx.setFillColor(style.backgroundColor.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // 繪製測量資訊文字
            drawMeasurementText(ctx: ctx, record: record, size: size)
        }
    }
    
    /// 匯出標註資訊為文字
    func exportAnnotationText(from record: MeasurementRecord) -> String {
        var text = "=== 測量標註資訊 ===\n\n"
        
        // 時間戳記
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        text += "測量時間: \(dateFormatter.string(from: record.timestamp))\n"
        
        // 位置資訊
        if let location = record.location {
            text += String(format: "GPS 座標: %.6f, %.6f\n",
                         location.coordinate.latitude,
                         location.coordinate.longitude)
        }
        
        text += "\n--- 檢測到的物體 ---\n"
        text += "總數: \(record.detectedObjects.count)\n\n"
        
        // 物體詳細資訊
        for (index, object) in record.detectedObjects.enumerated() {
            text += "[\(index + 1)] \(object.objectType.displayName)\n"
            text += "  信心度: \(String(format: "%.1f%%", object.confidence * 100))\n"
            
            if let dimensions = object.dimensions {
                text += "  尺寸: \(dimensions.formattedDimensions(unit: measurementUnit))\n"
                text += "  體積: \(String(format: "%.2f", dimensions.volume)) \(measurementUnit.symbol)³\n"
                text += "  準確度: \(String(format: "%.1f%%", dimensions.accuracy * 100))\n"
            }
            text += "\n"
        }
        
        // 參考物件資訊
        if let reference = record.referenceObject {
            text += "--- 參考物件 ---\n"
            text += "名稱: \(reference.name)\n"
            text += "標準尺寸: \(reference.standardDimensions.formattedDimensions(unit: measurementUnit))\n"
        }
        
        // 統計資訊
        if record.hasValidMeasurements {
            text += "\n--- 統計資訊 ---\n"
            text += "平均準確度: \(String(format: "%.1f%%", record.averageAccuracy * 100))\n"
        }
        
        return text
    }
    
    // MARK: - Configuration
    
    func updateStyle(_ newStyle: AnnotationStyle) {
        self.style = newStyle
    }
    
    func updateLayout(_ newLayout: AnnotationLayout) {
        self.layout = newLayout
    }
    
    func updateMeasurementUnit(_ unit: MeasurementUnit) {
        self.measurementUnit = unit
    }
    
    // MARK: - Private Drawing Methods
    
    private func drawOverlayAnnotations(ctx: CGContext, record: MeasurementRecord, imageSize: CGSize) {
        // 繪製頂部資訊欄
        drawHeaderBar(ctx: ctx, record: record, imageSize: imageSize)
        
        // 繪製物體標註
        for object in record.detectedObjects {
            drawObjectAnnotation(ctx: ctx, object: object, imageSize: imageSize)
        }
        
        // 繪製參考物件
        if let reference = record.referenceObject {
            drawReferenceObjectCard(ctx: ctx, reference: reference, imageSize: imageSize)
        }
        
        // 繪製底部統計資訊
        if record.hasValidMeasurements {
            drawFooterStats(ctx: ctx, record: record, imageSize: imageSize)
        }
    }
    
    private func drawSidebarAnnotations(ctx: CGContext, record: MeasurementRecord, imageSize: CGSize) {
        let sidebarWidth: CGFloat = 250
        let sidebarRect = CGRect(
            x: imageSize.width - sidebarWidth,
            y: 0,
            width: sidebarWidth,
            height: imageSize.height
        )
        
        // 繪製側邊欄背景
        ctx.setFillColor(style.backgroundColor.cgColor)
        ctx.fill(sidebarRect)
        
        // 繪製側邊欄內容
        var yOffset: CGFloat = style.margin
        
        // 標題
        let titleText = "測量結果"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.titleFont,
            .foregroundColor: style.textColor
        ]
        let titleSize = titleText.size(withAttributes: titleAttributes)
        titleText.draw(at: CGPoint(x: sidebarRect.minX + style.padding, y: yOffset), withAttributes: titleAttributes)
        yOffset += titleSize.height + style.spacing * 2
        
        // 物體列表
        for (index, object) in record.detectedObjects.enumerated() {
            yOffset = drawObjectInSidebar(ctx: ctx, object: object, index: index + 1, yOffset: yOffset, sidebarRect: sidebarRect)
        }
        
        // 繪製簡化的物體標記
        for object in record.detectedObjects {
            drawSimpleObjectMarker(ctx: ctx, object: object, imageSize: imageSize)
        }
    }
    
    private func drawTopBottomAnnotations(ctx: CGContext, record: MeasurementRecord, imageSize: CGSize) {
        // 頂部：標題和時間
        drawHeaderBar(ctx: ctx, record: record, imageSize: imageSize)
        
        // 中間：物體標註（簡化）
        for object in record.detectedObjects {
            drawSimpleObjectMarker(ctx: ctx, object: object, imageSize: imageSize)
        }
        
        // 底部：詳細測量資訊
        drawDetailedFooter(ctx: ctx, record: record, imageSize: imageSize)
    }
    
    private func drawMinimalAnnotations(ctx: CGContext, record: MeasurementRecord, imageSize: CGSize) {
        // 只繪製基本的邊界框和尺寸
        for object in record.detectedObjects {
            // 邊界框
            ctx.setStrokeColor(style.primaryColor.cgColor)
            ctx.setLineWidth(style.lineWidth)
            ctx.stroke(object.boundingBox)
            
            // 尺寸標籤
            if let dimensions = object.dimensions {
                let text = dimensions.formattedDimensions(unit: measurementUnit)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: style.bodyFont,
                    .foregroundColor: style.textColor,
                    .strokeColor: UIColor.black,
                    .strokeWidth: -3.0
                ]
                
                let textPoint = CGPoint(
                    x: object.boundingBox.minX,
                    y: object.boundingBox.minY - style.bodyFont.pointSize - 5
                )
                text.draw(at: textPoint, withAttributes: attributes)
            }
        }
    }
    
    private func drawHeaderBar(ctx: CGContext, record: MeasurementRecord, imageSize: CGSize) {
        let barHeight: CGFloat = 70
        let barRect = CGRect(x: 0, y: 0, width: imageSize.width, height: barHeight)
        
        // 背景
        ctx.setFillColor(style.backgroundColor.cgColor)
        ctx.fill(barRect)
        
        // 標題
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.titleFont,
            .foregroundColor: style.textColor
        ]
        "相機測量".draw(at: CGPoint(x: style.margin, y: style.padding), withAttributes: titleAttributes)
        
        // 時間戳記
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let timeText = dateFormatter.string(from: record.timestamp)
        
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: style.captionFont,
            .foregroundColor: style.textColor.withAlphaComponent(0.8)
        ]
        timeText.draw(at: CGPoint(x: style.margin, y: style.padding + style.titleFont.pointSize + 5), withAttributes: timeAttributes)
        
        // 物體數量
        let countText = "物體: \(record.detectedObjects.count)"
        let countSize = countText.size(withAttributes: timeAttributes)
        countText.draw(at: CGPoint(x: imageSize.width - countSize.width - style.margin, y: style.padding), withAttributes: timeAttributes)
    }
    
    private func drawObjectAnnotation(ctx: CGContext, object: DetectedObject, imageSize: CGSize) {
        // 繪製邊界框
        ctx.setStrokeColor(style.primaryColor.cgColor)
        ctx.setLineWidth(style.lineWidth)
        ctx.stroke(object.boundingBox)
        
        // 繪製角落標記
        drawCornerMarkers(ctx: ctx, rect: object.boundingBox)
        
        guard let dimensions = object.dimensions else { return }
        
        // 繪製尺寸標籤背景
        let labelText = dimensions.formattedDimensions(unit: measurementUnit)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: style.bodyFont,
            .foregroundColor: style.textColor
        ]
        
        let labelSize = labelText.size(withAttributes: labelAttributes)
        let labelRect = CGRect(
            x: object.boundingBox.minX,
            y: object.boundingBox.minY - labelSize.height - style.padding * 2,
            width: labelSize.width + style.padding * 2,
            height: labelSize.height + style.padding
        )
        
        // 標籤背景
        let path = UIBezierPath(roundedRect: labelRect, cornerRadius: style.cornerRadius)
        ctx.setFillColor(style.backgroundColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        
        // 標籤文字
        labelText.draw(at: CGPoint(x: labelRect.minX + style.padding, y: labelRect.minY + style.padding / 2), withAttributes: labelAttributes)
        
        // 繪製物體類型
        let typeText = object.objectType.displayName
        let typeAttributes: [NSAttributedString.Key: Any] = [
            .font: style.captionFont,
            .foregroundColor: style.textColor
        ]
        
        let typeSize = typeText.size(withAttributes: typeAttributes)
        let typeRect = CGRect(
            x: object.boundingBox.minX,
            y: object.boundingBox.maxY + 5,
            width: typeSize.width + style.padding * 2,
            height: typeSize.height + style.padding
        )
        
        let typePath = UIBezierPath(roundedRect: typeRect, cornerRadius: style.cornerRadius)
        ctx.setFillColor(style.secondaryColor.withAlphaComponent(0.9).cgColor)
        ctx.addPath(typePath.cgPath)
        ctx.fillPath()
        
        typeText.draw(at: CGPoint(x: typeRect.minX + style.padding, y: typeRect.minY + style.padding / 2), withAttributes: typeAttributes)
        
        // 繪製信心度指示器
        drawConfidenceIndicator(ctx: ctx, confidence: object.confidence, rect: object.boundingBox)
    }
    
    private func drawCornerMarkers(ctx: CGContext, rect: CGRect) {
        let markerLength: CGFloat = 15
        ctx.setStrokeColor(style.primaryColor.cgColor)
        ctx.setLineWidth(style.lineWidth)
        
        // 左上角
        ctx.move(to: CGPoint(x: rect.minX, y: rect.minY + markerLength))
        ctx.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.minX + markerLength, y: rect.minY))
        
        // 右上角
        ctx.move(to: CGPoint(x: rect.maxX - markerLength, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + markerLength))
        
        // 左下角
        ctx.move(to: CGPoint(x: rect.minX, y: rect.maxY - markerLength))
        ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.minX + markerLength, y: rect.maxY))
        
        // 右下角
        ctx.move(to: CGPoint(x: rect.maxX - markerLength, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - markerLength))
        
        ctx.strokePath()
    }
    
    private func drawConfidenceIndicator(ctx: CGContext, confidence: Float, rect: CGRect) {
        let indicatorWidth: CGFloat = 60
        let indicatorHeight: CGFloat = 8
        let indicatorRect = CGRect(
            x: rect.maxX - indicatorWidth - 5,
            y: rect.minY + 5,
            width: indicatorWidth,
            height: indicatorHeight
        )
        
        // 背景
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        ctx.fill(indicatorRect)
        
        // 信心度條
        let fillWidth = indicatorWidth * CGFloat(confidence)
        let fillRect = CGRect(
            x: indicatorRect.minX,
            y: indicatorRect.minY,
            width: fillWidth,
            height: indicatorHeight
        )
        
        let confidenceColor: UIColor
        if confidence >= 0.8 {
            confidenceColor = .systemGreen
        } else if confidence >= 0.6 {
            confidenceColor = .systemYellow
        } else {
            confidenceColor = .systemRed
        }
        
        ctx.setFillColor(confidenceColor.cgColor)
        ctx.fill(fillRect)
        
        // 邊框
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(1.0)
        ctx.stroke(indicatorRect)
    }
    
    private func drawReferenceObjectCard(ctx: CGContext, reference: ReferenceObject, imageSize: CGSize) {
        let cardWidth: CGFloat = 180
        let cardHeight: CGFloat = 200
        let cardRect = CGRect(
            x: imageSize.width - cardWidth - style.margin,
            y: imageSize.height - cardHeight - style.margin,
            width: cardWidth,
            height: cardHeight
        )
        
        // 卡片背景
        let path = UIBezierPath(roundedRect: cardRect, cornerRadius: style.cornerRadius)
        ctx.setFillColor(style.backgroundColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        
        // 卡片邊框
        ctx.setStrokeColor(style.secondaryColor.cgColor)
        ctx.setLineWidth(2.0)
        ctx.addPath(path.cgPath)
        ctx.strokePath()
        
        // 標題
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.captionFont,
            .foregroundColor: style.textColor.withAlphaComponent(0.7)
        ]
        "參考物件".draw(at: CGPoint(x: cardRect.minX + style.padding, y: cardRect.minY + style.padding), withAttributes: titleAttributes)
        
        // 參考物件圖示
        let iconSize: CGFloat = 80
        let iconRect = CGRect(
            x: cardRect.midX - iconSize / 2,
            y: cardRect.minY + 40,
            width: iconSize,
            height: iconSize
        )
        drawReferenceIcon(ctx: ctx, reference: reference, rect: iconRect)
        
        // 名稱
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: style.bodyFont,
            .foregroundColor: style.textColor
        ]
        let nameSize = reference.name.size(withAttributes: nameAttributes)
        reference.name.draw(
            at: CGPoint(x: cardRect.midX - nameSize.width / 2, y: iconRect.maxY + style.spacing),
            withAttributes: nameAttributes
        )
        
        // 尺寸
        let dimText = reference.standardDimensions.formattedDimensions(unit: measurementUnit)
        let dimAttributes: [NSAttributedString.Key: Any] = [
            .font: style.captionFont,
            .foregroundColor: style.textColor.withAlphaComponent(0.8)
        ]
        let dimSize = dimText.size(withAttributes: dimAttributes)
        dimText.draw(
            at: CGPoint(x: cardRect.midX - dimSize.width / 2, y: iconRect.maxY + style.spacing + nameSize.height + 5),
            withAttributes: dimAttributes
        )
    }
    
    private func drawReferenceObjectBadge(ctx: CGContext, reference: ReferenceObject, imageSize: CGSize) {
        let badgeWidth: CGFloat = 150
        let badgeHeight: CGFloat = 40
        let badgeRect = CGRect(
            x: imageSize.width - badgeWidth - style.margin,
            y: style.margin,
            width: badgeWidth,
            height: badgeHeight
        )
        
        // 背景
        let path = UIBezierPath(roundedRect: badgeRect, cornerRadius: style.cornerRadius)
        ctx.setFillColor(style.secondaryColor.withAlphaComponent(0.9).cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        
        // 文字
        let text = "參考: \(reference.name)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.captionFont,
            .foregroundColor: style.textColor
        ]
        let textSize = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: badgeRect.midX - textSize.width / 2, y: badgeRect.midY - textSize.height / 2),
            withAttributes: attributes
        )
    }
    
    private func drawReferenceIcon(ctx: CGContext, reference: ReferenceObject, rect: CGRect) {
        ctx.setFillColor(style.secondaryColor.cgColor)
        ctx.setStrokeColor(style.textColor.cgColor)
        ctx.setLineWidth(2.0)
        
        switch reference.name {
        case "打火機":
            let lighterRect = CGRect(x: rect.midX - 12, y: rect.midY - 20, width: 24, height: 40)
            ctx.fill(lighterRect)
            ctx.stroke(lighterRect)
            
        case "硬幣":
            ctx.fillEllipse(in: rect.insetBy(dx: 15, dy: 15))
            ctx.strokeEllipse(in: rect.insetBy(dx: 15, dy: 15))
            
        case "信用卡":
            let cardRect = rect.insetBy(dx: 10, dy: 20)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 4)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            ctx.addPath(path.cgPath)
            ctx.strokePath()
            
        case "iPhone":
            let phoneRect = rect.insetBy(dx: 20, dy: 10)
            let path = UIBezierPath(roundedRect: phoneRect, cornerRadius: 6)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            ctx.addPath(path.cgPath)
            ctx.strokePath()
            
        case "原子筆":
            let penRect = CGRect(x: rect.midX - 4, y: rect.minY + 5, width: 8, height: rect.height - 10)
            ctx.fill(penRect)
            ctx.stroke(penRect)
            
        default:
            let defaultRect = rect.insetBy(dx: 20, dy: 20)
            ctx.fill(defaultRect)
            ctx.stroke(defaultRect)
        }
    }
    
    private func drawFooterStats(ctx: CGContext, record: MeasurementRecord, imageSize: CGSize) {
        let footerHeight: CGFloat = 50
        let footerRect = CGRect(
            x: 0,
            y: imageSize.height - footerHeight,
            width: imageSize.width,
            height: footerHeight
        )
        
        // 背景
        ctx.setFillColor(style.backgroundColor.cgColor)
        ctx.fill(footerRect)
        
        // 統計資訊
        let statsText = String(format: "平均準確度: %.1f%% | 物體數量: %d",
                              record.averageAccuracy * 100,
                              record.detectedObjects.count)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.bodyFont,
            .foregroundColor: style.textColor
        ]
        
        let textSize = statsText.size(withAttributes: attributes)
        statsText.draw(
            at: CGPoint(x: footerRect.midX - textSize.width / 2, y: footerRect.midY - textSize.height / 2),
            withAttributes: attributes
        )
    }
    
    private func drawDetailedFooter(ctx: CGContext, record: MeasurementRecord, imageSize: CGSize) {
        let footerHeight: CGFloat = 150
        let footerRect = CGRect(
            x: 0,
            y: imageSize.height - footerHeight,
            width: imageSize.width,
            height: footerHeight
        )
        
        // 背景
        ctx.setFillColor(style.backgroundColor.cgColor)
        ctx.fill(footerRect)
        
        var yOffset = footerRect.minY + style.padding
        
        // 標題
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.bodyFont,
            .foregroundColor: style.textColor
        ]
        "測量詳情".draw(at: CGPoint(x: style.margin, y: yOffset), withAttributes: titleAttributes)
        yOffset += style.bodyFont.pointSize + style.spacing
        
        // 物體列表
        let itemAttributes: [NSAttributedString.Key: Any] = [
            .font: style.captionFont,
            .foregroundColor: style.textColor.withAlphaComponent(0.9)
        ]
        
        for (index, object) in record.detectedObjects.prefix(3).enumerated() {
            var itemText = "\(index + 1). \(object.objectType.displayName)"
            if let dimensions = object.dimensions {
                itemText += " - \(dimensions.formattedDimensions(unit: measurementUnit))"
            }
            
            itemText.draw(at: CGPoint(x: style.margin, y: yOffset), withAttributes: itemAttributes)
            yOffset += style.captionFont.pointSize + style.spacing / 2
        }
        
        if record.detectedObjects.count > 3 {
            let moreText = "... 還有 \(record.detectedObjects.count - 3) 個物體"
            moreText.draw(at: CGPoint(x: style.margin, y: yOffset), withAttributes: itemAttributes)
        }
    }
    
    private func drawSimpleObjectMarker(ctx: CGContext, object: DetectedObject, imageSize: CGSize) {
        // 簡單的十字標記
        let centerX = object.boundingBox.midX
        let centerY = object.boundingBox.midY
        let markerSize: CGFloat = 20
        
        ctx.setStrokeColor(style.primaryColor.cgColor)
        ctx.setLineWidth(style.lineWidth)
        
        // 水平線
        ctx.move(to: CGPoint(x: centerX - markerSize, y: centerY))
        ctx.addLine(to: CGPoint(x: centerX + markerSize, y: centerY))
        
        // 垂直線
        ctx.move(to: CGPoint(x: centerX, y: centerY - markerSize))
        ctx.addLine(to: CGPoint(x: centerX, y: centerY + markerSize))
        
        ctx.strokePath()
        
        // 編號
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: style.bodyFont,
            .foregroundColor: style.textColor,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        
        let numberText = "\(object.objectType.displayName)"
        let numberSize = numberText.size(withAttributes: numberAttributes)
        numberText.draw(
            at: CGPoint(x: centerX - numberSize.width / 2, y: centerY + markerSize + 5),
            withAttributes: numberAttributes
        )
    }
    
    private func drawObjectInSidebar(ctx: CGContext, object: DetectedObject, index: Int, yOffset: CGFloat, sidebarRect: CGRect) -> CGFloat {
        var currentY = yOffset
        
        // 物體編號和類型
        let titleText = "\(index). \(object.objectType.displayName)"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.bodyFont,
            .foregroundColor: style.textColor
        ]
        titleText.draw(at: CGPoint(x: sidebarRect.minX + style.padding, y: currentY), withAttributes: titleAttributes)
        currentY += style.bodyFont.pointSize + style.spacing / 2
        
        // 尺寸
        if let dimensions = object.dimensions {
            let dimText = dimensions.formattedDimensions(unit: measurementUnit)
            let dimAttributes: [NSAttributedString.Key: Any] = [
                .font: style.captionFont,
                .foregroundColor: style.textColor.withAlphaComponent(0.8)
            ]
            dimText.draw(at: CGPoint(x: sidebarRect.minX + style.padding + 10, y: currentY), withAttributes: dimAttributes)
            currentY += style.captionFont.pointSize + style.spacing / 2
            
            // 準確度
            let accuracyText = String(format: "準確度: %.1f%%", dimensions.accuracy * 100)
            accuracyText.draw(at: CGPoint(x: sidebarRect.minX + style.padding + 10, y: currentY), withAttributes: dimAttributes)
            currentY += style.captionFont.pointSize + style.spacing
        }
        
        // 分隔線
        ctx.setStrokeColor(style.textColor.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(1.0)
        ctx.move(to: CGPoint(x: sidebarRect.minX + style.padding, y: currentY))
        ctx.addLine(to: CGPoint(x: sidebarRect.maxX - style.padding, y: currentY))
        ctx.strokePath()
        
        return currentY + style.spacing
    }
    
    private func drawMeasurementText(ctx: CGContext, record: MeasurementRecord, size: CGSize) {
        var yOffset: CGFloat = style.margin
        
        // 標題
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.titleFont,
            .foregroundColor: style.textColor
        ]
        "測量資訊".draw(at: CGPoint(x: style.margin, y: yOffset), withAttributes: titleAttributes)
        yOffset += style.titleFont.pointSize + style.spacing * 2
        
        // 時間
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let timeText = "時間: \(dateFormatter.string(from: record.timestamp))"
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: style.bodyFont,
            .foregroundColor: style.textColor
        ]
        timeText.draw(at: CGPoint(x: style.margin, y: yOffset), withAttributes: bodyAttributes)
        yOffset += style.bodyFont.pointSize + style.spacing
        
        // 物體資訊
        for (index, object) in record.detectedObjects.enumerated() {
            let objectText = "\(index + 1). \(object.objectType.displayName)"
            objectText.draw(at: CGPoint(x: style.margin, y: yOffset), withAttributes: bodyAttributes)
            yOffset += style.bodyFont.pointSize + style.spacing / 2
            
            if let dimensions = object.dimensions {
                let dimText = "   \(dimensions.formattedDimensions(unit: measurementUnit))"
                dimText.draw(at: CGPoint(x: style.margin, y: yOffset), withAttributes: bodyAttributes)
                yOffset += style.bodyFont.pointSize + style.spacing
            }
        }
    }
}

// MARK: - Convenience Extensions

extension ImageAnnotationService {
    /// 快速建立標註影像（使用預設設定）
    static func quickAnnotate(image: UIImage,
                             detectedObjects: [DetectedObject],
                             referenceObject: ReferenceObject? = nil) -> UIImage? {
        let service = ImageAnnotationService()
        return service.createQuickAnnotatedImage(
            image: image,
            detectedObjects: detectedObjects,
            referenceObject: referenceObject
        )
    }
    
    /// 建立最小化標註影像
    static func minimalAnnotate(record: MeasurementRecord) -> UIImage? {
        let service = ImageAnnotationService(layout: .minimal)
        return service.createAnnotatedImage(from: record)
    }
    
    /// 建立詳細標註影像
    static func detailedAnnotate(record: MeasurementRecord) -> UIImage? {
        let service = ImageAnnotationService(layout: .topBottom)
        return service.createAnnotatedImage(from: record)
    }
}
