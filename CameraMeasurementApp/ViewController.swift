//
//  ViewController.swift
//  CameraMeasurementApp
//
//  Created by 吳崇岳 on 2025/10/25.
//

import UIKit
import AVFoundation
import SceneKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var arSceneView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var measurementOverlayView: UIView!
    @IBOutlet weak var guidanceLabel: UILabel!
    
    // MARK: - Properties
    private var sceneView: ARSCNView!
    private var arManager: ARManager?
    
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
        
        // Setup ARSCNView
        setupARSCNView()
        
        // Add Manual Measurement button
        setupManualMeasurementButton()
    }
    
    private func setupManualMeasurementButton() {
        let manualMeasureButton = UIButton(type: .system)
        manualMeasureButton.translatesAutoresizingMaskIntoConstraints = false
        manualMeasureButton.setTitle("手動測量", for: .normal)
        manualMeasureButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        manualMeasureButton.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
        manualMeasureButton.setTitleColor(.white, for: .normal)
        manualMeasureButton.layer.cornerRadius = 8
        manualMeasureButton.addTarget(self, action: #selector(showManualMeasurement), for: .touchUpInside)
        
        view.addSubview(manualMeasureButton)
        
        NSLayoutConstraint.activate([
            manualMeasureButton.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -20),
            manualMeasureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            manualMeasureButton.widthAnchor.constraint(equalToConstant: 120),
            manualMeasureButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupARSCNView() {
        // Create ARSCNView
        sceneView = ARSCNView(frame: arSceneView.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Configure scene view
        sceneView.delegate = self
        sceneView.session.delegate = self  // Set session delegate for frame updates
        sceneView.showsStatistics = false
        sceneView.debugOptions = []
        
        // Enable default lighting
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        // Add to container view
        arSceneView.addSubview(sceneView)
        arSceneView.sendSubviewToBack(sceneView)
        
        // Verify setup
        print("✅ ARSCNView setup complete:")
        print("   Frame: \(sceneView.frame)")
        print("   Delegate: \(sceneView.delegate != nil ? "✅" : "❌")")
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
        // Initialize ARManager with the scene view
        arManager = ARManager(arView: sceneView)
        arManager?.delegate = self
        
        // Initialize core components
        objectDetector = ObjectDetector()
        measurementCalculator = MeasurementCalculator()
        referenceObjectManager = ReferenceObjectManager.shared
        
        // Initialize real-time measurement manager
        var realtimeConfig = RealtimeMeasurementConfiguration()
        realtimeConfig.useCachedResults = true
        realtimeConfig.enableSmoothing = true
        realtimeConfig.smoothingWindowSize = 5
        realtimeConfig.filterType = .movingAverage
        realtimeConfig.enableOutlierDetection = true
        
        realtimeMeasurementManager = RealtimeMeasurementManager(
            targetFPS: 8.0,
            objectDetector: objectDetector,
            measurementCalculator: measurementCalculator,
            configuration: realtimeConfig
        )
        
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
        guard ARWorldTrackingConfiguration.isSupported else {
            updateStatusLabel("此裝置不支援 AR 功能")
            handleError(.arSessionFailed)
            return
        }
        
        arManager?.startARSession()
        updateStatusLabel("正在初始化 AR 會話...")
    }
    
    private func stopARSession() {
        arManager?.stopARSession()
        updateStatusLabel("相機測量系統已停止")
    }
    

    
    // MARK: - Actions
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        // Navigate to settings page
        performSegue(withIdentifier: "showSettings", sender: nil)
    }
    
    /// Navigate to Manual Measurement feature
    @objc private func showManualMeasurement() {
        let manualMeasurementVC = ManualMeasurementViewController()
        manualMeasurementVC.modalPresentationStyle = .fullScreen
        present(manualMeasurementVC, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Navigation logic for other segues if needed
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


// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Frame processing removed - no automatic detection
    }
    
    // ARSessionDelegate method - alternative to renderer
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Frame processing removed - no automatic detection
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("AR 會話錯誤")
            self?.handleError(.arSessionFailed)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("AR 會話已中斷")
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("AR 會話已恢復")
            self?.startARSession()
        }
    }
}

// MARK: - ARManagerDelegate

extension ViewController: ARManagerDelegate {
    
    func arManagerDidStartSession(_ manager: ARManager) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("AR 會話已啟動")
            self?.showGuidance("移動裝置以偵測平面")
        }
    }
    
    func arManagerDidStopSession(_ manager: ARManager) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("AR 會話已停止")
        }
    }
    
    func arManager(_ manager: ARManager, didDetectPlane plane: ARPlaneAnchor) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("已偵測到平面")
            
            // Update guidance after first plane detection
            if self?.settingsManager.shouldShowGuidance == true {
                self?.updateGuidance("平面已偵測，可以開始手動測量")
            }
        }
    }
    
    func arManager(_ manager: ARManager, didUpdatePlane plane: ARPlaneAnchor) {
        // Plane updated - no UI update needed
    }
    
    func arManager(_ manager: ARManager, didRemovePlane plane: ARPlaneAnchor) {
        // Plane removed - no UI update needed
    }
    
    func arManager(_ manager: ARManager, didPlaceVirtualObject object: VirtualObject, at position: SCNVector3) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("已放置虛擬物件")
        }
    }
    
    func arManager(_ manager: ARManager, didFailWithError error: MeasurementError) {
        DispatchQueue.main.async { [weak self] in
            self?.handleError(error)
        }
    }
    
    func arManager(_ manager: ARManager, didChangeTrackingState state: ARTrackingState) {
        DispatchQueue.main.async { [weak self] in
            print("📍 Tracking state changed: \(state)")
            
            switch state {
            case .normal:
                print("   ✅ Tracking normal")
                self?.updateStatusLabel("追蹤正常")
                
                if self?.settingsManager.shouldShowGuidance == true {
                    self?.showGuidance("追蹤正常，可以開始手動測量")
                }
                
            case .notAvailable:
                print("   ❌ Tracking not available")
                self?.updateStatusLabel("追蹤不可用")
                self?.showGuidance("AR 追蹤暫時不可用")
                
            case .limited(let reason):
                switch reason {
                case .initializing:
                    self?.updateStatusLabel("正在初始化...")
                    self?.showGuidance("移動裝置以初始化 AR")
                    print("⚠️ Tracking limited: initializing")
                    
                case .excessiveMotion:
                    self?.updateStatusLabel("移動過快")
                    self?.showGuidance("請放慢移動速度")
                    
                case .insufficientFeatures:
                    self?.updateStatusLabel("特徵點不足")
                    self?.showGuidance("請對準有更多細節的區域")
                    
                case .relocalizing:
                    self?.updateStatusLabel("正在重新定位...")
                    self?.showGuidance("移動裝置以重新定位")
                }
            }
        }
    }
    
    func arManagerSessionWasInterrupted(_ manager: ARManager) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("AR 會話已中斷")
            self?.showGuidance("AR 會話已中斷，請稍候")
        }
    }
    
    func arManagerSessionInterruptionEnded(_ manager: ARManager) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel("AR 會話已恢復")
            self?.hideGuidance()
        }
    }
}
