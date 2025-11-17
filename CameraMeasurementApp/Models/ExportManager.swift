//
//  ExportManager.swift
//  CameraMeasurementApp
//
//  測量資料匯出管理器
//  提供 CSV 匯出和影像標註功能
//

import Foundation
import UIKit
import CoreGraphics

/// 匯出格式類型
enum ExportFormat {
    case csv
    case json
    case annotatedImage
}

/// 匯出錯誤類型
enum ExportError: Error {
    case noDataToExport
    case fileCreationFailed
    case imageAnnotationFailed
    case invalidExportPath
    case permissionDenied
    
    var localizedDescription: String {
        switch self {
        case .noDataToExport:
            return "沒有可匯出的資料"
        case .fileCreationFailed:
            return "檔案建立失敗"
        case .imageAnnotationFailed:
            return "影像標註失敗"
        case .invalidExportPath:
            return "無效的匯出路徑"
        case .permissionDenied:
            return "沒有檔案存取權限"
        }
    }
}

/// 測量資料匯出管理器
class ExportManager {
    
    // MARK: - Singleton
    static let shared = ExportManager()
    
    private init() {}
    
    // MARK: - CSV Export
    
    /// 匯出測量記錄為 CSV 格式
    /// - Parameters:
    ///   - records: 要匯出的測量記錄陣列
    ///   - includeHeaders: 是否包含標題列
    /// - Returns: CSV 格式的字串
    /// - Throws: ExportError
    func exportToCSV(records: [MeasurementRecord], includeHeaders: Bool = true) throws -> String {
        guard !records.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var csvString = ""
        
        // Add headers
        if includeHeaders {
            csvString += "記錄ID,時間戳記,物體類型,長度(cm),寬度(cm),高度(cm),體積(cm³),準確度,參考物件,經度,緯度\n"
        }
        
        // Add data rows
        for record in records {
            for object in record.detectedObjects {
                guard let dimensions = object.dimensions else { continue }
                
                let row = [
                    record.id.uuidString,
                    formatDate(record.timestamp),
                    escapeCSVField(object.objectType.displayName),
                    String(format: "%.2f", dimensions.length),
                    String(format: "%.2f", dimensions.width),
                    String(format: "%.2f", dimensions.height),
                    String(format: "%.2f", dimensions.volume),
                    String(format: "%.2f", dimensions.accuracy),
                    escapeCSVField(record.referenceObject?.name ?? "無"),
                    record.location?.coordinate.longitude.description ?? "",
                    record.location?.coordinate.latitude.description ?? ""
                ].joined(separator: ",")
                
                csvString += row + "\n"
            }
        }
        
        return csvString
    }
    
    /// 將 CSV 資料寫入檔案
    /// - Parameters:
    ///   - csvString: CSV 格式的字串
    ///   - filename: 檔案名稱
    /// - Returns: 檔案 URL
    /// - Throws: ExportError
    func saveCSVToFile(_ csvString: String, filename: String = "measurements.csv") throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed
        }
    }
    
    /// 匯出單筆測量記錄為 CSV
    /// - Parameter record: 測量記錄
    /// - Returns: CSV 格式的字串
    /// - Throws: ExportError
    func exportRecordToCSV(_ record: MeasurementRecord) throws -> String {
        return try exportToCSV(records: [record], includeHeaders: true)
    }
    
    // MARK: - JSON Export
    
    /// 匯出測量記錄為 JSON 格式
    /// - Parameter records: 要匯出的測量記錄陣列
    /// - Returns: JSON 格式的資料
    /// - Throws: ExportError
    func exportToJSON(records: [MeasurementRecord]) throws -> Data {
        guard !records.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var exportData: [[String: Any]] = []
        
        for record in records {
            var recordDict: [String: Any] = [
                "id": record.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: record.timestamp),
                "referenceObject": record.referenceObject?.name ?? NSNull()
            ]
            
            if let location = record.location {
                recordDict["location"] = [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "altitude": location.altitude
                ]
            }
            
            var objectsArray: [[String: Any]] = []
            for object in record.detectedObjects {
                var objectDict: [String: Any] = [
                    "id": object.id.uuidString,
                    "type": object.objectType.rawValue,
                    "confidence": object.confidence
                ]
                
                if let dimensions = object.dimensions {
                    objectDict["dimensions"] = [
                        "length": dimensions.length,
                        "width": dimensions.width,
                        "height": dimensions.height,
                        "volume": dimensions.volume,
                        "accuracy": dimensions.accuracy,
                        "measurementDate": ISO8601DateFormatter().string(from: dimensions.measurementDate)
                    ]
                }
                
                objectsArray.append(objectDict)
            }
            
            recordDict["detectedObjects"] = objectsArray
            exportData.append(recordDict)
        }
        
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            throw ExportError.fileCreationFailed
        }
    }
    
    // MARK: - Image Annotation
    
    /// 建立帶有測量標註的影像
    /// - Parameters:
    ///   - record: 測量記錄
    ///   - options: 標註選項
    /// - Returns: 標註後的影像
    /// - Throws: ExportError
    func createAnnotatedImage(from record: MeasurementRecord, 
                            options: AnnotationOptions = .default) throws -> UIImage {
        guard !record.detectedObjects.isEmpty else {
            throw ExportError.imageAnnotationFailed
        }
        
        let image = record.image
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)
            
            let ctx = context.cgContext
            
            // Draw measurement annotations for detected objects
            for object in record.detectedObjects {
                drawObjectAnnotation(object, in: ctx, imageSize: image.size, options: options)
            }
            
            // Draw reference object if available
            if options.showReferenceObject, 
               let reference = record.referenceObject {
                drawReferenceObject(reference, in: ctx, imageSize: image.size, options: options)
            }
            
            // Draw timestamp and metadata
            if options.showMetadata {
                drawMetadata(record, in: ctx, imageSize: image.size, options: options)
            }
        }
    }
    
    /// 儲存標註影像到相簿
    /// - Parameters:
    ///   - image: 要儲存的影像
    ///   - completion: 完成回調
    func saveAnnotatedImageToPhotoLibrary(_ image: UIImage, 
                                         completion: @escaping (Result<Void, Error>) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        // Note: For proper error handling, should use PHPhotoLibrary
        completion(.success(()))
    }
    
    /// 儲存標註影像到檔案
    /// - Parameters:
    ///   - image: 要儲存的影像
    ///   - filename: 檔案名稱
    /// - Returns: 檔案 URL
    /// - Throws: ExportError
    func saveAnnotatedImageToFile(_ image: UIImage, filename: String) throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw ExportError.imageAnnotationFailed
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed
        }
    }
    
    // MARK: - Batch Export
    
    /// 批次匯出測量記錄（包含 CSV 和標註影像）
    /// - Parameters:
    ///   - records: 測量記錄陣列
    ///   - exportImages: 是否匯出標註影像
    /// - Returns: 匯出檔案的 URL 陣列
    /// - Throws: ExportError
    func batchExport(records: [MeasurementRecord], 
                    exportImages: Bool = true) throws -> [URL] {
        guard !records.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var exportedURLs: [URL] = []
        
        // Export CSV
        let csvString = try exportToCSV(records: records)
        let timestamp = formatDateForFilename(Date())
        let csvURL = try saveCSVToFile(csvString, filename: "measurements_\(timestamp).csv")
        exportedURLs.append(csvURL)
        
        // Export annotated images if requested
        if exportImages {
            for (index, record) in records.enumerated() {
                let annotatedImage = try createAnnotatedImage(from: record)
                let imageFilename = "measurement_\(timestamp)_\(index + 1).jpg"
                let imageURL = try saveAnnotatedImageToFile(annotatedImage, filename: imageFilename)
                exportedURLs.append(imageURL)
            }
        }
        
        return exportedURLs
    }
    
    // MARK: - Helper Methods
    
    private func drawObjectAnnotation(_ object: DetectedObject, 
                                     in context: CGContext, 
                                     imageSize: CGSize,
                                     options: AnnotationOptions) {
        // Draw bounding box
        context.setStrokeColor(options.boundingBoxColor.cgColor)
        context.setLineWidth(options.lineWidth)
        context.stroke(object.boundingBox)
        
        // Draw dimension labels
        if let dimensions = object.dimensions, options.showDimensions {
            let text = dimensions.formattedDimensions(unit: options.measurementUnit)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: options.fontSize, weight: .bold),
                .foregroundColor: options.textColor,
                .strokeColor: options.textStrokeColor,
                .strokeWidth: -3.0
            ]
            
            let textRect = CGRect(
                x: object.boundingBox.minX,
                y: object.boundingBox.minY - options.fontSize - 10,
                width: object.boundingBox.width,
                height: options.fontSize + 10
            )
            
            text.draw(in: textRect, withAttributes: attributes)
            
            // Draw object type label
            if options.showObjectType {
                let typeText = object.objectType.displayName
                let typeRect = CGRect(
                    x: object.boundingBox.minX,
                    y: object.boundingBox.maxY + 5,
                    width: object.boundingBox.width,
                    height: options.fontSize + 5
                )
                typeText.draw(in: typeRect, withAttributes: attributes)
            }
        }
    }
    
    private func drawReferenceObject(_ reference: ReferenceObject, 
                                    in context: CGContext, 
                                    imageSize: CGSize,
                                    options: AnnotationOptions) {
        let refWidth: CGFloat = 150
        let refHeight: CGFloat = 150
        let margin: CGFloat = 20
        
        let refRect = CGRect(
            x: imageSize.width - refWidth - margin,
            y: imageSize.height - refHeight - margin,
            width: refWidth,
            height: refHeight
        )
        
        // Draw semi-transparent background
        context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        context.fill(refRect)
        
        // Draw border
        context.setStrokeColor(options.referenceObjectColor.cgColor)
        context.setLineWidth(2.0)
        context.stroke(refRect)
        
        // Draw reference object icon
        let iconSize: CGFloat = 70
        let iconRect = CGRect(
            x: refRect.midX - iconSize / 2,
            y: refRect.minY + 20,
            width: iconSize,
            height: iconSize
        )
        
        drawReferenceIcon(for: reference, in: iconRect, context: context, color: options.referenceObjectColor)
        
        // Draw reference object name
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let nameText = reference.name
        let nameSize = nameText.size(withAttributes: nameAttributes)
        let namePoint = CGPoint(
            x: refRect.midX - nameSize.width / 2,
            y: refRect.minY + iconSize + 25
        )
        nameText.draw(at: namePoint, withAttributes: nameAttributes)
        
        // Draw dimensions
        let dimAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.lightGray
        ]
        
        let dimText = reference.standardDimensions.formattedDimensions(unit: options.measurementUnit)
        let dimSize = dimText.size(withAttributes: dimAttributes)
        let dimPoint = CGPoint(
            x: refRect.midX - dimSize.width / 2,
            y: namePoint.y + nameSize.height + 5
        )
        dimText.draw(at: dimPoint, withAttributes: dimAttributes)
    }
    
    private func drawReferenceIcon(for reference: ReferenceObject, 
                                   in rect: CGRect, 
                                   context: CGContext,
                                   color: UIColor) {
        context.setFillColor(color.cgColor)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        
        switch reference.name {
        case "打火機":
            let lighterRect = CGRect(x: rect.midX - 15, y: rect.midY - 25, width: 30, height: 50)
            context.fill(lighterRect)
            context.stroke(lighterRect)
            
        case "硬幣":
            context.fillEllipse(in: rect.insetBy(dx: 10, dy: 10))
            context.strokeEllipse(in: rect.insetBy(dx: 10, dy: 10))
            
        case "信用卡":
            let cardRect = rect.insetBy(dx: 5, dy: 15)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 5)
            context.addPath(path.cgPath)
            context.fillPath()
            context.addPath(path.cgPath)
            context.strokePath()
            
        case "iPhone":
            let phoneRect = rect.insetBy(dx: 15, dy: 5)
            let path = UIBezierPath(roundedRect: phoneRect, cornerRadius: 8)
            context.addPath(path.cgPath)
            context.fillPath()
            context.addPath(path.cgPath)
            context.strokePath()
            
        case "原子筆":
            let penRect = CGRect(x: rect.midX - 5, y: rect.minY + 5, width: 10, height: rect.height - 10)
            context.fill(penRect)
            context.stroke(penRect)
            
        default:
            let defaultRect = rect.insetBy(dx: 15, dy: 15)
            context.fill(defaultRect)
            context.stroke(defaultRect)
        }
    }
    
    private func drawMetadata(_ record: MeasurementRecord, 
                            in context: CGContext, 
                            imageSize: CGSize,
                            options: AnnotationOptions) {
        let margin: CGFloat = 20
        let bgHeight: CGFloat = 80
        
        let bgRect = CGRect(
            x: margin,
            y: margin,
            width: imageSize.width - (margin * 2),
            height: bgHeight
        )
        
        // Draw semi-transparent background
        context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        context.fill(bgRect)
        
        // Draw metadata text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var metadataText = "測量時間: \(dateFormatter.string(from: record.timestamp))\n"
        metadataText += "物體數量: \(record.detectedObjects.count)\n"
        
        if let location = record.location {
            metadataText += String(format: "位置: %.4f, %.4f", 
                                 location.coordinate.latitude, 
                                 location.coordinate.longitude)
        }
        
        let textRect = bgRect.insetBy(dx: 15, dy: 10)
        metadataText.draw(in: textRect, withAttributes: attributes)
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }
}

// MARK: - Annotation Options

/// 影像標註選項
struct AnnotationOptions {
    var showDimensions: Bool = true
    var showObjectType: Bool = true
    var showReferenceObject: Bool = true
    var showMetadata: Bool = true
    var boundingBoxColor: UIColor = .systemGreen
    var referenceObjectColor: UIColor = .systemOrange
    var textColor: UIColor = .white
    var textStrokeColor: UIColor = .black
    var lineWidth: CGFloat = 3.0
    var fontSize: CGFloat = 24.0
    var measurementUnit: MeasurementUnit = .centimeters
    
    static let `default` = AnnotationOptions()
    
    static let minimal = AnnotationOptions(
        showDimensions: true,
        showObjectType: false,
        showReferenceObject: false,
        showMetadata: false
    )
    
    static let detailed = AnnotationOptions(
        showDimensions: true,
        showObjectType: true,
        showReferenceObject: true,
        showMetadata: true
    )
}
