//
//  ExportManager+ImageAnnotation.swift
//  CameraMeasurementApp
//
//  ExportManager 的影像標註擴展
//  整合 ImageAnnotationService 提供更強大的標註功能
//

import UIKit

extension ExportManager {
    
    // MARK: - Enhanced Image Annotation
    
    /// 使用進階標註服務建立標註影像
    /// - Parameters:
    ///   - record: 測量記錄
    ///   - layout: 標註佈局樣式
    ///   - style: 視覺樣式配置
    /// - Returns: 標註後的影像
    /// - Throws: ExportError
    func createEnhancedAnnotatedImage(from record: MeasurementRecord,
                                     layout: AnnotationLayout = .overlay,
                                     style: AnnotationStyle = .default) throws -> UIImage {
        guard !record.detectedObjects.isEmpty else {
            throw ExportError.imageAnnotationFailed
        }
        
        // 取得使用者偏好的測量單位
        let unitString = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
        let measurementUnit = MeasurementUnit(rawValue: unitString) ?? .centimeters
        
        // 建立標註服務
        let annotationService = ImageAnnotationService(
            style: style,
            layout: layout,
            measurementUnit: measurementUnit
        )
        
        guard let annotatedImage = annotationService.createAnnotatedImage(from: record) else {
            throw ExportError.imageAnnotationFailed
        }
        
        return annotatedImage
    }
    
    /// 建立多種佈局的標註影像
    /// - Parameter record: 測量記錄
    /// - Returns: 包含不同佈局的影像字典
    /// - Throws: ExportError
    func createMultiLayoutAnnotations(from record: MeasurementRecord) throws -> [AnnotationLayout: UIImage] {
        guard !record.detectedObjects.isEmpty else {
            throw ExportError.imageAnnotationFailed
        }
        
        var results: [AnnotationLayout: UIImage] = [:]
        let layouts: [AnnotationLayout] = [.overlay, .sidebar, .topBottom, .minimal]
        
        for layout in layouts {
            if let image = try? createEnhancedAnnotatedImage(from: record, layout: layout) {
                results[layout] = image
            }
        }
        
        guard !results.isEmpty else {
            throw ExportError.imageAnnotationFailed
        }
        
        return results
    }
    
    /// 匯出標註影像和文字資訊
    /// - Parameters:
    ///   - record: 測量記錄
    ///   - includeTextFile: 是否包含文字檔案
    /// - Returns: 匯出檔案的 URL 陣列
    /// - Throws: ExportError
    func exportAnnotatedPackage(record: MeasurementRecord,
                               includeTextFile: Bool = true) throws -> [URL] {
        var exportedURLs: [URL] = []
        
        // 建立標註影像
        let annotatedImage = try createEnhancedAnnotatedImage(from: record)
        
        // 儲存影像
        let timestamp = formatDateForFilename(Date())
        let imageFilename = "annotated_\(timestamp).jpg"
        let imageURL = try saveAnnotatedImageToFile(annotatedImage, filename: imageFilename)
        exportedURLs.append(imageURL)
        
        // 儲存文字資訊
        if includeTextFile {
            let unitString = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
            let measurementUnit = MeasurementUnit(rawValue: unitString) ?? .centimeters
            
            let annotationService = ImageAnnotationService(measurementUnit: measurementUnit)
            let textContent = annotationService.exportAnnotationText(from: record)
            
            let textFilename = "measurement_info_\(timestamp).txt"
            let textURL = try saveTextToFile(textContent, filename: textFilename)
            exportedURLs.append(textURL)
        }
        
        return exportedURLs
    }
    
    /// 批次匯出帶有進階標註的影像
    /// - Parameters:
    ///   - records: 測量記錄陣列
    ///   - layout: 標註佈局
    ///   - includeTextFiles: 是否包含文字檔案
    /// - Returns: 匯出檔案的 URL 陣列
    /// - Throws: ExportError
    func batchExportEnhancedAnnotations(records: [MeasurementRecord],
                                       layout: AnnotationLayout = .overlay,
                                       includeTextFiles: Bool = true) throws -> [URL] {
        guard !records.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var exportedURLs: [URL] = []
        let timestamp = formatDateForFilename(Date())
        
        for (index, record) in records.enumerated() {
            // 匯出標註影像
            let annotatedImage = try createEnhancedAnnotatedImage(from: record, layout: layout)
            let imageFilename = "annotated_\(timestamp)_\(index + 1).jpg"
            let imageURL = try saveAnnotatedImageToFile(annotatedImage, filename: imageFilename)
            exportedURLs.append(imageURL)
            
            // 匯出文字資訊
            if includeTextFiles {
                let unitString = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
                let measurementUnit = MeasurementUnit(rawValue: unitString) ?? .centimeters
                
                let annotationService = ImageAnnotationService(measurementUnit: measurementUnit)
                let textContent = annotationService.exportAnnotationText(from: record)
                
                let textFilename = "measurement_info_\(timestamp)_\(index + 1).txt"
                let textURL = try saveTextToFile(textContent, filename: textFilename)
                exportedURLs.append(textURL)
            }
        }
        
        return exportedURLs
    }
    
    /// 建立比較影像（原始 vs 標註）
    /// - Parameter record: 測量記錄
    /// - Returns: 並排比較的影像
    /// - Throws: ExportError
    func createComparisonImage(from record: MeasurementRecord) throws -> UIImage {
        guard !record.detectedObjects.isEmpty else {
            throw ExportError.imageAnnotationFailed
        }
        
        let originalImage = record.image
        let annotatedImage = try createEnhancedAnnotatedImage(from: record, layout: .minimal)
        
        let totalWidth = originalImage.size.width * 2 + 20
        let totalHeight = max(originalImage.size.height, annotatedImage.size.height) + 60
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 背景
            ctx.setFillColor(UIColor.systemBackground.cgColor)
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: totalWidth, height: totalHeight)))
            
            // 標題
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            
            "原始影像".draw(at: CGPoint(x: originalImage.size.width / 2 - 40, y: 10), withAttributes: titleAttributes)
            "標註影像".draw(at: CGPoint(x: originalImage.size.width + 30, y: 10), withAttributes: titleAttributes)
            
            // 繪製原始影像
            originalImage.draw(at: CGPoint(x: 0, y: 50))
            
            // 繪製標註影像
            annotatedImage.draw(at: CGPoint(x: originalImage.size.width + 20, y: 50))
        }
    }
    
    /// 建立標註預覽縮圖
    /// - Parameters:
    ///   - record: 測量記錄
    ///   - size: 縮圖大小
    /// - Returns: 縮圖影像
    /// - Throws: ExportError
    func createAnnotatedThumbnail(from record: MeasurementRecord,
                                 size: CGSize = CGSize(width: 300, height: 300)) throws -> UIImage {
        let annotatedImage = try createEnhancedAnnotatedImage(from: record, layout: .minimal)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            annotatedImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveTextToFile(_ text: String, filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed
        }
    }
}

// MARK: - Annotation Layout Extension

extension AnnotationLayout {
    var displayName: String {
        switch self {
        case .overlay:
            return "覆蓋標註"
        case .sidebar:
            return "側邊欄"
        case .topBottom:
            return "上下分佈"
        case .minimal:
            return "最小化"
        }
    }
    
    var description: String {
        switch self {
        case .overlay:
            return "在影像上直接顯示測量資訊"
        case .sidebar:
            return "在側邊欄顯示詳細資訊"
        case .topBottom:
            return "在頂部和底部顯示資訊"
        case .minimal:
            return "只顯示基本的邊界框和尺寸"
        }
    }
}

// MARK: - Annotation Style Presets

extension AnnotationStyle {
    static let professional = AnnotationStyle(
        primaryColor: .systemBlue,
        secondaryColor: .systemIndigo,
        textColor: .white,
        backgroundColor: UIColor.black.withAlphaComponent(0.8),
        lineWidth: 2.5,
        cornerRadius: 6.0
    )
    
    static let vibrant = AnnotationStyle(
        primaryColor: .systemPink,
        secondaryColor: .systemPurple,
        textColor: .white,
        backgroundColor: UIColor.systemPurple.withAlphaComponent(0.7),
        lineWidth: 3.5,
        cornerRadius: 10.0
    )
    
    static let minimal = AnnotationStyle(
        primaryColor: .systemGray,
        secondaryColor: .systemGray2,
        textColor: .label,
        backgroundColor: UIColor.systemBackground.withAlphaComponent(0.9),
        lineWidth: 1.5,
        cornerRadius: 4.0,
        titleFont: .systemFont(ofSize: 18, weight: .medium),
        bodyFont: .systemFont(ofSize: 14, weight: .regular),
        captionFont: .systemFont(ofSize: 12, weight: .light)
    )
}
