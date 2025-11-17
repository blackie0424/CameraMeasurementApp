//
//  ResultsViewController.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import UIKit

class ResultsViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var measurementOverlayView: MeasurementOverlayView!
    @IBOutlet weak var referenceObjectView: ReferenceObjectView!
    @IBOutlet weak var measurementInfoView: UIView!
    @IBOutlet weak var objectNameLabel: UILabel!
    @IBOutlet weak var dimensionsLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var referenceObjectLabel: UILabel!
    @IBOutlet weak var changeReferenceButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var retakeButton: UIButton!
    
    // MARK: - Properties
    var measurementRecord: MeasurementRecord?
    var selectedReferenceObject: ReferenceObject?
    private var availableReferenceObjects: [ReferenceObject] = ReferenceObject.defaultObjects
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayMeasurementResults()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // Configure image view
        resultImageView.contentMode = .scaleAspectFit
        resultImageView.backgroundColor = .black
        
        // Configure measurement info view
        measurementInfoView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        measurementInfoView.layer.cornerRadius = 12
        measurementInfoView.layer.masksToBounds = true
        
        // Configure buttons
        configureButton(saveButton, title: "儲存", color: .systemGreen)
        configureButton(shareButton, title: "分享", color: .systemBlue)
        configureButton(retakeButton, title: "重新拍攝", color: .systemGray)
        configureButton(changeReferenceButton, title: "更換參考物件", color: .systemOrange)
        
        // Configure labels
        objectNameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        objectNameLabel.textColor = .white
        
        dimensionsLabel.font = .systemFont(ofSize: 16, weight: .medium)
        dimensionsLabel.textColor = .white
        dimensionsLabel.numberOfLines = 0
        
        accuracyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        accuracyLabel.textColor = .systemGray
        
        referenceObjectLabel.font = .systemFont(ofSize: 14, weight: .regular)
        referenceObjectLabel.textColor = .systemGray2
    }
    
    private func configureButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    }
    
    // MARK: - Display Methods
    private func displayMeasurementResults() {
        guard let record = measurementRecord else {
            showError("無測量資料")
            return
        }
        
        // Display captured image
        resultImageView.image = record.image
        
        // Display detected objects with measurements
        if let primaryObject = record.detectedObjects.first {
            displayObjectInfo(primaryObject)
            
            // Draw measurement overlay
            measurementOverlayView.detectedObjects = record.detectedObjects
            measurementOverlayView.setNeedsDisplay()
        }
        
        // Display reference object if available
        if let reference = record.referenceObject ?? selectedReferenceObject {
            displayReferenceObject(reference)
        } else {
            // Auto-select best reference object
            if let primaryObject = record.detectedObjects.first {
                selectedReferenceObject = selectBestReferenceObject(for: primaryObject)
                if let reference = selectedReferenceObject {
                    displayReferenceObject(reference)
                }
            }
        }
    }
    
    private func displayObjectInfo(_ object: DetectedObject) {
        // Display object type
        objectNameLabel.text = object.objectType.displayName
        
        // Display dimensions
        if let dimensions = object.dimensions {
            let unit = UserDefaults.standard.string(forKey: "preferredUnit") ?? "cm"
            let measurementUnit = MeasurementUnit(rawValue: unit) ?? .centimeters
            
            dimensionsLabel.text = """
            尺寸: \(dimensions.formattedDimensions(unit: measurementUnit))
            體積: \(String(format: "%.1f", dimensions.volume)) cm³
            """
            
            // Display accuracy
            let accuracyPercentage = Int(dimensions.accuracy * 100)
            accuracyLabel.text = "準確度: \(accuracyPercentage)%"
            
            // Set accuracy color based on value
            if dimensions.accuracy >= 0.9 {
                accuracyLabel.textColor = .systemGreen
            } else if dimensions.accuracy >= 0.7 {
                accuracyLabel.textColor = .systemYellow
            } else {
                accuracyLabel.textColor = .systemRed
            }
        } else {
            dimensionsLabel.text = "無法測量此物體"
            accuracyLabel.text = ""
        }
    }
    
    private func displayReferenceObject(_ reference: ReferenceObject) {
        referenceObjectLabel.text = "參考物件: \(reference.name)"
        
        // Display reference object visualization
        referenceObjectView.referenceObject = reference
        referenceObjectView.setNeedsDisplay()
    }
    
    private func selectBestReferenceObject(for object: DetectedObject) -> ReferenceObject? {
        guard let dimensions = object.dimensions else { return nil }
        
        // Select reference object with similar size
        let objectSize = dimensions.length * dimensions.width * dimensions.height
        
        return availableReferenceObjects.min(by: { ref1, ref2 in
            let size1 = ref1.standardDimensions.volume
            let size2 = ref2.standardDimensions.volume
            
            return abs(size1 - objectSize) < abs(size2 - objectSize)
        })
    }
    
    // MARK: - Actions
    @IBAction func changeReferenceButtonTapped(_ sender: UIButton) {
        showReferenceObjectPicker()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let record = measurementRecord else { return }
        
        // Show save options
        showSaveOptions(for: record)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let record = measurementRecord else { return }
        
        // Show share options
        showShareOptions(for: record)
    }
    
    @IBAction func retakeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    // MARK: - Helper Methods
    private func showReferenceObjectPicker() {
        let alert = UIAlertController(title: "選擇參考物件", message: nil, preferredStyle: .actionSheet)
        
        for reference in availableReferenceObjects {
            alert.addAction(UIAlertAction(title: reference.name, style: .default) { [weak self] _ in
                self?.selectedReferenceObject = reference
                self?.displayReferenceObject(reference)
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = changeReferenceButton
            popover.sourceRect = changeReferenceButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func createAnnotatedImage(from record: MeasurementRecord) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: record.image.size)
        
        return renderer.image { context in
            // Draw original image
            record.image.draw(at: .zero)
            
            let ctx = context.cgContext
            
            // Draw measurement annotations for detected objects
            ctx.setStrokeColor(UIColor.systemGreen.cgColor)
            ctx.setLineWidth(3.0)
            
            for object in record.detectedObjects {
                // Draw bounding box
                ctx.stroke(object.boundingBox)
                
                // Draw dimension labels
                if let dimensions = object.dimensions {
                    let text = dimensions.formattedDimensions()
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                        .foregroundColor: UIColor.white,
                        .strokeColor: UIColor.black,
                        .strokeWidth: -3.0
                    ]
                    
                    let textRect = CGRect(
                        x: object.boundingBox.minX,
                        y: object.boundingBox.minY - 30,
                        width: object.boundingBox.width,
                        height: 30
                    )
                    
                    text.draw(in: textRect, withAttributes: attributes)
                }
            }
            
            // Draw reference object visualization
            if let reference = record.referenceObject ?? selectedReferenceObject {
                drawReferenceObject(reference, in: ctx, imageSize: record.image.size)
            }
        }
    }
    
    private func drawReferenceObject(_ reference: ReferenceObject, in context: CGContext, imageSize: CGSize) {
        // Position reference object in bottom-right corner
        let refWidth: CGFloat = 120
        let refHeight: CGFloat = 120
        let margin: CGFloat = 20
        
        let refRect = CGRect(
            x: imageSize.width - refWidth - margin,
            y: imageSize.height - refHeight - margin,
            width: refWidth,
            height: refHeight
        )
        
        // Draw semi-transparent background
        context.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
        context.fill(refRect)
        
        // Draw border
        context.setStrokeColor(UIColor.systemOrange.cgColor)
        context.setLineWidth(2.0)
        context.stroke(refRect)
        
        // Draw reference object icon/representation
        let iconSize: CGFloat = 60
        let iconRect = CGRect(
            x: refRect.midX - iconSize / 2,
            y: refRect.minY + 15,
            width: iconSize,
            height: iconSize
        )
        
        // Draw a simple representation based on object type
        drawReferenceIcon(for: reference, in: iconRect, context: context)
        
        // Draw reference object name and dimensions
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let nameText = reference.name
        let nameSize = nameText.size(withAttributes: nameAttributes)
        let namePoint = CGPoint(
            x: refRect.midX - nameSize.width / 2,
            y: refRect.minY + iconSize + 20
        )
        nameText.draw(at: namePoint, withAttributes: nameAttributes)
        
        // Draw dimensions
        let dimAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.lightGray
        ]
        
        let dimText = reference.standardDimensions.formattedDimensions()
        let dimSize = dimText.size(withAttributes: dimAttributes)
        let dimPoint = CGPoint(
            x: refRect.midX - dimSize.width / 2,
            y: namePoint.y + nameSize.height + 5
        )
        dimText.draw(at: dimPoint, withAttributes: dimAttributes)
    }
    
    private func drawReferenceIcon(for reference: ReferenceObject, in rect: CGRect, context: CGContext) {
        context.setFillColor(UIColor.systemOrange.cgColor)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        
        // Draw different shapes based on reference object type
        switch reference.name {
        case "打火機":
            // Draw a rectangle (lighter shape)
            let lighterRect = CGRect(
                x: rect.midX - 15,
                y: rect.midY - 25,
                width: 30,
                height: 50
            )
            context.fill(lighterRect)
            context.stroke(lighterRect)
            
        case "硬幣":
            // Draw a circle (coin shape)
            context.fillEllipse(in: rect.insetBy(dx: 10, dy: 10))
            context.strokeEllipse(in: rect.insetBy(dx: 10, dy: 10))
            
        case "信用卡":
            // Draw a rounded rectangle (card shape)
            let cardRect = rect.insetBy(dx: 5, dy: 15)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 5)
            context.addPath(path.cgPath)
            context.fillPath()
            context.addPath(path.cgPath)
            context.strokePath()
            
        case "iPhone":
            // Draw a rounded rectangle with notch (phone shape)
            let phoneRect = rect.insetBy(dx: 15, dy: 5)
            let path = UIBezierPath(roundedRect: phoneRect, cornerRadius: 8)
            context.addPath(path.cgPath)
            context.fillPath()
            context.addPath(path.cgPath)
            context.strokePath()
            
        case "原子筆":
            // Draw a thin rectangle (pen shape)
            let penRect = CGRect(
                x: rect.midX - 5,
                y: rect.minY + 5,
                width: 10,
                height: rect.height - 10
            )
            context.fill(penRect)
            context.stroke(penRect)
            
        default:
            // Draw a generic square
            let defaultRect = rect.insetBy(dx: 15, dy: 15)
            context.fill(defaultRect)
            context.stroke(defaultRect)
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showError("儲存失敗: \(error.localizedDescription)")
        } else {
            showSuccess("已儲存到相簿")
        }
    }
    
    private func showSaveOptions(for record: MeasurementRecord) {
        let alert = UIAlertController(title: "儲存選項", message: "選擇要儲存的格式", preferredStyle: .actionSheet)
        
        // Save annotated image to photo library
        alert.addAction(UIAlertAction(title: "儲存標註影像到相簿", style: .default) { [weak self] _ in
            self?.saveAnnotatedImageToPhotoLibrary(record)
        })
        
        // Save to Core Data
        alert.addAction(UIAlertAction(title: "儲存測量記錄", style: .default) { [weak self] _ in
            self?.saveMeasurementRecord(record)
        })
        
        // Export as CSV
        alert.addAction(UIAlertAction(title: "匯出為 CSV", style: .default) { [weak self] _ in
            self?.exportAsCSV(record)
        })
        
        // Export all (image + CSV)
        alert.addAction(UIAlertAction(title: "匯出全部（影像 + CSV）", style: .default) { [weak self] _ in
            self?.exportAll(record)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = saveButton
            popover.sourceRect = saveButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showShareOptions(for record: MeasurementRecord) {
        let alert = UIAlertController(title: "分享選項", message: "選擇要分享的內容", preferredStyle: .actionSheet)
        
        // Share annotated image
        alert.addAction(UIAlertAction(title: "分享標註影像", style: .default) { [weak self] _ in
            self?.shareAnnotatedImage(record)
        })
        
        // Share CSV data
        alert.addAction(UIAlertAction(title: "分享 CSV 資料", style: .default) { [weak self] _ in
            self?.shareCSVData(record)
        })
        
        // Share both
        alert.addAction(UIAlertAction(title: "分享全部", style: .default) { [weak self] _ in
            self?.shareAll(record)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Save Methods
    
    private func saveAnnotatedImageToPhotoLibrary(_ record: MeasurementRecord) {
        do {
            let annotatedImage = try ExportManager.shared.createAnnotatedImage(from: record)
            UIImageWriteToSavedPhotosAlbum(annotatedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        } catch {
            showError("影像標註失敗: \(error.localizedDescription)")
        }
    }
    
    private func saveMeasurementRecord(_ record: MeasurementRecord) {
        do {
            try DataManager.shared.saveMeasurementRecord(record)
            showSuccess("測量記錄已儲存")
        } catch {
            showError("儲存失敗: \(error.localizedDescription)")
        }
    }
    
    private func exportAsCSV(_ record: MeasurementRecord) {
        do {
            let csvString = try ExportManager.shared.exportRecordToCSV(record)
            let fileURL = try ExportManager.shared.saveCSVToFile(csvString, filename: "measurement_\(record.id.uuidString).csv")
            showSuccess("CSV 已匯出到: \(fileURL.lastPathComponent)")
            
            // Optionally share the file
            shareFile(at: fileURL)
        } catch {
            showError("CSV 匯出失敗: \(error.localizedDescription)")
        }
    }
    
    private func exportAll(_ record: MeasurementRecord) {
        do {
            // Export annotated image
            let annotatedImage = try ExportManager.shared.createAnnotatedImage(from: record)
            let imageURL = try ExportManager.shared.saveAnnotatedImageToFile(
                annotatedImage, 
                filename: "measurement_\(record.id.uuidString).jpg"
            )
            
            // Export CSV
            let csvString = try ExportManager.shared.exportRecordToCSV(record)
            let csvURL = try ExportManager.shared.saveCSVToFile(
                csvString, 
                filename: "measurement_\(record.id.uuidString).csv"
            )
            
            // Save to Core Data
            try DataManager.shared.saveMeasurementRecord(record)
            
            showSuccess("已匯出影像和 CSV，並儲存測量記錄")
            
            // Share both files
            shareFiles(at: [imageURL, csvURL])
        } catch {
            showError("匯出失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Share Methods
    
    private func shareAnnotatedImage(_ record: MeasurementRecord) {
        do {
            let annotatedImage = try ExportManager.shared.createAnnotatedImage(from: record)
            let activityVC = UIActivityViewController(activityItems: [annotatedImage], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = shareButton
            present(activityVC, animated: true)
        } catch {
            showError("影像標註失敗: \(error.localizedDescription)")
        }
    }
    
    private func shareCSVData(_ record: MeasurementRecord) {
        do {
            let csvString = try ExportManager.shared.exportRecordToCSV(record)
            let fileURL = try ExportManager.shared.saveCSVToFile(csvString, filename: "measurement_\(record.id.uuidString).csv")
            shareFile(at: fileURL)
        } catch {
            showError("CSV 匯出失敗: \(error.localizedDescription)")
        }
    }
    
    private func shareAll(_ record: MeasurementRecord) {
        do {
            // Create annotated image
            let annotatedImage = try ExportManager.shared.createAnnotatedImage(from: record)
            let imageURL = try ExportManager.shared.saveAnnotatedImageToFile(
                annotatedImage, 
                filename: "measurement_\(record.id.uuidString).jpg"
            )
            
            // Create CSV
            let csvString = try ExportManager.shared.exportRecordToCSV(record)
            let csvURL = try ExportManager.shared.saveCSVToFile(
                csvString, 
                filename: "measurement_\(record.id.uuidString).csv"
            )
            
            shareFiles(at: [imageURL, csvURL])
        } catch {
            showError("匯出失敗: \(error.localizedDescription)")
        }
    }
    
    private func shareFile(at url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }
    
    private func shareFiles(at urls: [URL]) {
        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "錯誤", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "成功", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
}
