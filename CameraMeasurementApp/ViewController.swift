//
//  ViewController.swift
//  CameraMeasurementApp
//
//  Created by 吳崇岳 on 2025/10/25.
//

import UIKit
import AVFoundation
import SceneKit

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var arSceneView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var measurementOverlayView: UIView!
    @IBOutlet weak var guidanceLabel: UILabel!
    
    // MARK: - Properties
    private var arManager: ARManagerProtocol?
    private var objectDetector: ObjectDetectorProtocol?
    private var measurementCalculator: MeasurementCalculatorProtocol?
    private var referenceObjectManager: ReferenceObjectManagerProtocol?
    
    private var currentMeasurementRecord: MeasurementRecord?
    private var isCapturing = false
    
    private let settingsManager = SettingsManager.shared
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCameraMeasurement()
        checkPermissions()
        setupNotifications()
        showInitialGuidance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
        applySettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopARSession()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // UI elements are now connected via IBOutlets from storyboard
        // Additional configuration if needed
        arSceneView.backgroundColor = .darkGray
        measurementOverlayView.isUserInteractionEnabled = false
        
        // Configure guidance label padding
        guidanceLabel.layer.masksToBounds = true
        guidanceLabel.clipsToBounds = true
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: .settingsDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMeasurementUnitChange),
            name: .measurementUnitDidChange,
            object: nil
        )
    }
    
    private func applySettings() {
        // Apply current settings to the UI and behavior
        let shouldShowGuidance = settingsManager.shouldShowGuidance
        
        if shouldShowGuidance {
            showGuidance("將相機對準物體，確保物體完整顯示在畫面中")
        } else {
            hideGuidance()
        }
    }
    
    @objc private func handleSettingsChange() {
        applySettings()
    }
    
    @objc private func handleMeasurementUnitChange() {
        // Refresh any displayed measurements with new unit
        updateStatusLabel("測量單位已更新為 \(settingsManager.measurementUnit.name)")
    }
    
    private func setupCameraMeasurement() {
        // Initialize core components (will be implemented in later tasks)
        // arManager = ARManager()
        // objectDetector = ObjectDetector()
        // measurementCalculator = MeasurementCalculator()
        // referenceObjectManager = ReferenceObjectManager()
        
        updateStatusLabel("相機測量系統已準備就緒")
    }
    
    private func checkPermissions() {
        // Check camera permission
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.updateStatusLabel("相機權限已授予")
                    } else {
                        self?.handlePermissionDenied(.cameraPermissionDenied)
                    }
                }
            }
        case .denied, .restricted:
            handlePermissionDenied(.cameraPermissionDenied)
        case .authorized:
            updateStatusLabel("相機權限已授予")
        @unknown default:
            updateStatusLabel("未知的權限狀態")
        }
    }
    
    // MARK: - AR Session Management
    private func startARSession() {
        // AR session will be started when ARManager is implemented
        updateStatusLabel("相機測量系統已準備就緒")
    }
    
    private func stopARSession() {
        // AR session will be stopped when ARManager is implemented
        updateStatusLabel("相機測量系統已停止")
    }
    
    // MARK: - Actions
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        guard !isCapturing else { return }
        
        isCapturing = true
        captureButton.isEnabled = false
        hideGuidance()
        updateStatusLabel("正在拍攝和分析...")
        
        // Capture and measurement logic will be implemented in later tasks
        performMeasurement()
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        // Navigate to settings page
        performSegue(withIdentifier: "showSettings", sender: nil)
    }
    
    // MARK: - Measurement Methods
    private func performMeasurement() {
        // This is a placeholder implementation
        // Actual measurement logic will be implemented in later tasks
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isCapturing = false
            self?.captureButton.isEnabled = true
            self?.updateStatusLabel("測量完成")
            
            // Create mock measurement data for testing the results display
            self?.showMockResults()
        }
    }
    
    private func showMockResults() {
        // Create mock data for testing the results display interface
        guard let mockImage = createMockImage() else { return }
        
        let mockDimensions = ObjectDimensions(
            length: 15.5,
            width: 8.2,
            height: 3.0,
            accuracy: 0.92
        )
        
        let mockObject = DetectedObject(
            boundingBox: CGRect(x: 100, y: 200, width: 200, height: 300),
            objectType: .phone,
            confidence: 0.95,
            worldPosition: SCNVector3(0, 0, 0),
            dimensions: mockDimensions
        )
        
        let mockRecord = MeasurementRecord(
            image: mockImage,
            detectedObjects: [mockObject],
            referenceObject: ReferenceObject.iPhone
        )
        
        showResults(with: mockRecord)
    }
    
    private func createMockImage() -> UIImage? {
        // Create a simple mock image for testing
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw background
            UIColor.systemGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw mock object
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 100, y: 200, width: 200, height: 300))
            
            // Draw text
            let text = "測試物體"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            text.draw(at: CGPoint(x: 150, y: 340), withAttributes: attributes)
        }
    }
    
    private func showResults(with record: MeasurementRecord) {
        performSegue(withIdentifier: "showResults", sender: record)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showResults",
           let resultsVC = segue.destination as? ResultsViewController,
           let record = sender as? MeasurementRecord {
            resultsVC.measurementRecord = record
        }
    }
    
    // MARK: - UI Helper Methods
    private func updateStatusLabel(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = message
        }
    }
    
    private func showInitialGuidance() {
        // Check if this is the first time user is using the app
        let hasSeenGuidance = settingsManager.hasSeenInitialGuidance
        let shouldShowGuidance = settingsManager.shouldShowGuidance
        
        if !hasSeenGuidance {
            showGuidance("將相機對準物體，確保物體完整顯示在畫面中")
            
            // Show detailed tutorial for first-time users
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.showFirstTimeUserTutorial()
            }
        } else if shouldShowGuidance {
            // Show brief guidance for returning users
            showGuidance("將相機對準物體，確保物體完整顯示在畫面中")
            
            // Auto-hide guidance after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.hideGuidance()
            }
        }
    }
    
    private func showGuidance(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.guidanceLabel.text = message
            self?.guidanceLabel.alpha = 0
            self?.guidanceLabel.isHidden = false
            
            UIView.animate(withDuration: 0.3) {
                self?.guidanceLabel.alpha = 1
            }
        }
    }
    
    private func hideGuidance() {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.3, animations: {
                self?.guidanceLabel.alpha = 0
            }) { _ in
                self?.guidanceLabel.isHidden = true
            }
        }
    }
    
    private func updateGuidance(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.2, animations: {
                self?.guidanceLabel.alpha = 0
            }) { _ in
                self?.guidanceLabel.text = message
                UIView.animate(withDuration: 0.2) {
                    self?.guidanceLabel.alpha = 1
                }
            }
        }
    }
    
    private func showFirstTimeUserTutorial() {
        let alert = UIAlertController(
            title: "歡迎使用相機測量",
            message: """
            使用步驟：
            1. 將相機對準要測量的物體
            2. 確保物體完整顯示在畫面中
            3. 點擊「拍照測量」按鈕
            4. 系統會自動識別物體並顯示測量結果
            
            提示：光線充足的環境能獲得更準確的測量結果
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "開始使用", style: .default) { [weak self] _ in
            self?.settingsManager.hasSeenInitialGuidance = true
        })
        
        present(alert, animated: true)
    }
    
    private func handleError(_ error: MeasurementError) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel(error.localizedDescription)
            self?.showErrorAlert(error)
        }
    }
    
    private func handlePermissionDenied(_ error: MeasurementError) {
        DispatchQueue.main.async { [weak self] in
            self?.showPermissionAlert(error)
        }
    }
    
    private func showErrorAlert(_ error: MeasurementError) {
        let alert = UIAlertController(
            title: "錯誤",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: error.recoveryAction, style: .default) { _ in
            // Handle recovery action
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showPermissionAlert(_ error: MeasurementError) {
        let alert = UIAlertController(
            title: "需要權限",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "前往設定", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showSettingsAlert() {
        let alert = UIAlertController(
            title: "設定",
            message: "設定功能將在後續任務中實現",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        
        present(alert, animated: true)
    }
}

