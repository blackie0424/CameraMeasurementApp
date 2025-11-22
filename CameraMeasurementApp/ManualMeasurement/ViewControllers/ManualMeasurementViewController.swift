//
//  ManualMeasurementViewController.swift
//  CameraMeasurementApp
//
//  Manual AR Measurement - Main View Controller
//

import UIKit
import ARKit
import SceneKit
import AVFoundation

/// 主視圖控制器，負責整合所有組件並處理使用者互動
class ManualMeasurementViewController: UIViewController {
    
    // MARK: - UI Components
    
    /// AR Scene View
    private var arView: ARSCNView!
    
    /// 測量按鈕
    private var measureButton: UIButton!
    
    /// 狀態標籤
    private var statusLabel: UILabel!
    
    /// 偵測進度標籤
    private var detectionProgressLabel: UILabel!
    
    /// 重新偵測平面按鈕
    private var redetectButton: UIButton!
    
    /// 關閉按鈕
    private var closeButton: UIButton!
    
    // MARK: - Core Components
    
    /// AR 管理器
    private var arManager: ManualARManager!
    
    /// 狀態管理器
    private var stateManager: MeasurementStateManager!
    
    /// 渲染器
    private var renderer: MeasurementRenderer!
    
    /// 平面偵測管理器
    private var planeDetectionManager: PlaneDetectionManager!
    
    /// 追蹤品質監控器
    private var trackingQualityMonitor: TrackingQualityMonitor!
    
    /// 效能監控器
    private let performanceMonitor = PerformanceMonitor.shared
    
    // MARK: - Properties
    
    /// 上次更新時間（用於節流）
    private var lastUpdateTime: TimeInterval = 0
    
    /// 更新間隔（30 FPS = 1/30 秒）
    private let updateInterval: TimeInterval = 1.0 / 30.0
    
    /// 追蹤品質警告視圖
    private var trackingWarningView: UIView?
    
    /// 重試按鈕（用於 AR Session 失敗）
    private var retryButton: UIButton?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARView()
        setupUI()
        initializeComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupARSession()
        
        // Start performance monitoring
        performanceMonitor.startMonitoring()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arManager.pauseSession()
        
        // Stop performance monitoring and generate report
        performanceMonitor.stopMonitoring()
    }
    
    // MARK: - Setup Methods
    
    /// 設置 ARSCNView
    private func setupARView() {
        arView = ARSCNView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.delegate = self
        
        // Set session delegate to monitor AR session events
        arView.session.delegate = self
        
        // 移除除錯選項以改善使用者體驗
        // ARKit 特徵點顯示已移除，使用者只會看到：
        // - 中心白色游標（Center Reticle）
        // - 測量點標記（黃色圓點）
        // - 測量線和距離標籤
        // 如需除錯，可臨時添加：arView.debugOptions = [.showFeaturePoints]
        
        view.addSubview(arView)
        print("✅ ViewController: ARView setup complete")
    }
    
    /// 設置 UI 元素
    private func setupUI() {
        // 測量按鈕
        measureButton = UIButton(type: .system)
        measureButton.translatesAutoresizingMaskIntoConstraints = false
        measureButton.setTitle("開始測量", for: .normal)
        measureButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        measureButton.backgroundColor = UIColor.systemBlue
        measureButton.setTitleColor(.white, for: .normal)
        measureButton.layer.cornerRadius = 30
        measureButton.addTarget(self, action: #selector(onMeasureButtonTapped), for: .touchUpInside)
        view.addSubview(measureButton)
        
        // 狀態標籤
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "正在偵測平面，請緩慢移動裝置"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        statusLabel.layer.cornerRadius = 8
        statusLabel.clipsToBounds = true
        statusLabel.numberOfLines = 0
        view.addSubview(statusLabel)
        
        // 偵測進度標籤
        detectionProgressLabel = UILabel()
        detectionProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        detectionProgressLabel.text = "已偵測 0 個平面"
        detectionProgressLabel.textAlignment = .center
        detectionProgressLabel.textColor = .white
        detectionProgressLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        detectionProgressLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        detectionProgressLabel.layer.cornerRadius = 6
        detectionProgressLabel.clipsToBounds = true
        view.addSubview(detectionProgressLabel)
        
        // 重新偵測平面按鈕
        redetectButton = UIButton(type: .system)
        redetectButton.translatesAutoresizingMaskIntoConstraints = false
        redetectButton.setTitle("重新偵測平面", for: .normal)
        redetectButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        redetectButton.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.8)
        redetectButton.setTitleColor(.white, for: .normal)
        redetectButton.layer.cornerRadius = 6
        redetectButton.addTarget(self, action: #selector(redetectPlanes), for: .touchUpInside)
        redetectButton.isHidden = true  // 初始隱藏
        view.addSubview(redetectButton)
        
        // 關閉按鈕
        closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // 設置約束
        NSLayoutConstraint.activate([
            // 測量按鈕
            measureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            measureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            measureButton.widthAnchor.constraint(equalToConstant: 200),
            measureButton.heightAnchor.constraint(equalToConstant: 60),
            
            // 狀態標籤
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            // 偵測進度標籤
            detectionProgressLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            detectionProgressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detectionProgressLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            detectionProgressLabel.heightAnchor.constraint(equalToConstant: 32),
            
            // 重新偵測平面按鈕
            redetectButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            redetectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            redetectButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            redetectButton.heightAnchor.constraint(equalToConstant: 32),
            
            // 關閉按鈕
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    /// 初始化核心組件
    private func initializeComponents() {
        print("🔧 ViewController: Initializing components...")
        
        // 初始化 AR 管理器
        arManager = ManualARManager(session: arView.session, sceneView: arView)
        
        // 初始化狀態管理器
        stateManager = MeasurementStateManager()
        
        // 初始化渲染器
        renderer = MeasurementRenderer(sceneView: arView)
        
        // 初始化平面偵測管理器
        planeDetectionManager = PlaneDetectionManager()
        setupPlaneDetectionCallbacks()
        
        // 初始化追蹤品質監控器
        trackingQualityMonitor = TrackingQualityMonitor()
        setupTrackingQualityCallbacks()
        
        // 初始化 UI 狀態（偵測階段）
        updateUIForDetectionState(.detecting)
        
        print("✅ ViewController: Components initialized")
    }
    
    /// 設置平面偵測回調
    private func setupPlaneDetectionCallbacks() {
        // 狀態變更回調
        planeDetectionManager.onStateChanged = { [weak self] newState in
            DispatchQueue.main.async {
                self?.updateUIForDetectionState(newState)
            }
        }
        
        // 平面新增回調
        planeDetectionManager.onPlaneAdded = { [weak self] planeInfo in
            DispatchQueue.main.async {
                self?.updateDetectionProgress()
            }
        }
        
        // 平面更新回調
        planeDetectionManager.onPlaneUpdated = { [weak self] planeInfo in
            DispatchQueue.main.async {
                self?.updateDetectionProgress()
            }
        }
        
        // 平面移除回調
        planeDetectionManager.onPlaneRemoved = { [weak self] identifier in
            DispatchQueue.main.async {
                self?.updateDetectionProgress()
            }
        }
    }
    
    /// 設置追蹤品質回調
    private func setupTrackingQualityCallbacks() {
        trackingQualityMonitor.onQualityChanged = { [weak self] quality in
            DispatchQueue.main.async {
                self?.handleTrackingQualityChange(quality)
            }
        }
    }
    
    /// 更新 UI 以反映平面偵測狀態
    /// 需求: 1.1, 1.2, 7.1, 7.3, 7.4, 7.5
    private func updateUIForDetectionState(_ state: PlaneDetectionState) {
        switch state {
        case .detecting:
            // 偵測階段：禁用測量按鈕，顯示「偵測中...」
            measureButton.isEnabled = false
            measureButton.setTitle("偵測中...", for: .normal)
            measureButton.backgroundColor = UIColor.systemGray
            statusLabel.text = "正在偵測平面，請緩慢移動裝置"
            detectionProgressLabel.isHidden = false
            redetectButton.isHidden = true
            
        case .ready:
            // 準備測量：啟用測量按鈕
            measureButton.isEnabled = true
            measureButton.setTitle("開始測量", for: .normal)
            measureButton.backgroundColor = UIColor.systemBlue
            
            let planeCount = planeDetectionManager.getPlaneCount()
            if planeCount == 1 {
                statusLabel.text = "已偵測到平面，繼續移動以改善準確度"
            } else {
                statusLabel.text = "已偵測到足夠平面，可以開始測量"
            }
            detectionProgressLabel.isHidden = false
            redetectButton.isHidden = true
            
        case .measurementMode:
            // 測量模式：保持按鈕啟用，更新文字，顯示重新偵測按鈕
            // 需求: 7.4 - 固定當前平面，停止新平面視覺化
            measureButton.isEnabled = true
            measureButton.setTitle("開始測量", for: .normal)
            measureButton.backgroundColor = UIColor.systemBlue
            statusLabel.text = "移動裝置以選擇測量點"
            detectionProgressLabel.isHidden = true
            redetectButton.isHidden = false  // 需求: 7.5 - 顯示重新偵測選項
        }
    }
    
    /// 更新偵測進度顯示
    /// 需求: 7.3
    private func updateDetectionProgress() {
        let planeCount = planeDetectionManager.getPlaneCount()
        detectionProgressLabel.text = "已偵測 \(planeCount) 個平面"
        
        // 如果偵測到第一個平面，更新狀態訊息
        if planeCount == 1 && planeDetectionManager.state == .detecting {
            statusLabel.text = "已偵測到平面，繼續移動以改善準確度"
        }
    }
    
    /// 處理追蹤品質變更
    /// 需求: 5.2
    private func handleTrackingQualityChange(_ quality: TrackingQuality) {
        if let warningMessage = trackingQualityMonitor.getWarningMessage() {
            showTrackingWarning(warningMessage)
        } else {
            hideTrackingWarning()
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    /// 重新偵測平面
    /// 需求: 7.5
    @objc private func redetectPlanes() {
        // 清除當前測量
        renderer.clearAllVisuals()
        stateManager.reset()
        
        // 重置平面偵測
        planeDetectionManager.resetDetection()
        
        // 重新顯示中心游標
        renderer.showCenterReticle(on: view)
        
        // 觸覺回饋
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 處理測量按鈕點擊
    /// 需求: 2.1, 2.4, 4.1, 5.2, 7.4
    @objc private func onMeasureButtonTapped() {
        // 檢查平面偵測狀態
        if planeDetectionManager.state == .ready {
            // 從 ready 狀態進入測量模式
            // 需求: 7.4 - 固定當前平面，停止新平面視覺化
            planeDetectionManager.enterMeasurementMode()
            return
        }
        
        // 取得螢幕中心點
        let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        
        // 根據當前測量狀態執行不同邏輯
        switch stateManager.currentState {
        case .initial:
            // Initial 狀態：執行 hit test 並記錄起點
            handleInitialState(screenCenter: screenCenter)
            
        case .startPointRecorded:
            // StartPointRecorded 狀態：執行 hit test 並記錄終點
            handleStartPointRecordedState(screenCenter: screenCenter)
            
        case .measurementComplete:
            // MeasurementComplete 狀態：清除並重置
            handleMeasurementCompleteState()
        }
        
        // 觸覺回饋
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 處理 Initial 狀態的按鈕點擊
    /// 需求: 3.2, 3.3, 4.1
    private func handleInitialState(screenCenter: CGPoint) {
        // 檢查追蹤品質
        if !isTrackingQualitySufficient() {
            handleError(.insufficientTracking)
            return
        }
        
        // 執行平面優先的 hit test
        // 需求: 3.1 - 優先檢測已偵測的平面
        guard let (hitResult, planeAnchor) = arManager.performHitTestOnPlanes(at: screenCenter) else {
            // 未命中平面，顯示提示訊息
            // 需求: 3.3 - 未命中平面時拒絕放置測量點
            updateStatusLabel("請將游標對準已偵測的平面")
            showHitTestFailureAnimation()
            return
        }
        
        // 創建錨定測量點
        // 需求: 4.1 - 將測量點錨定到 Plane Anchor
        let anchoredPoint = arManager.createAnchoredPoint(on: planeAnchor, at: hitResult)
        
        // 取得世界座標用於顯示標記
        let position = anchoredPoint.worldPosition()
        
        // 驗證測量點有效性
        do {
            try validateMeasurementPoint(position)
        } catch {
            handleError(error as? ManualMeasurementError ?? .invalidMeasurementPoint)
            return
        }
        
        // 記錄起點（儲存錨定測量點）
        stateManager.recordStartPoint(position)
        
        // 顯示起點標記
        renderer.addStartMarker(at: position)
        
        // 更新 UI
        updateStatusLabel("移動裝置以選擇終點")
        updateMeasureButton(title: "記錄終點")
    }
    
    /// 處理 StartPointRecorded 狀態的按鈕點擊
    /// 需求: 3.2, 3.3, 4.1
    private func handleStartPointRecordedState(screenCenter: CGPoint) {
        // 檢查追蹤品質
        if !isTrackingQualitySufficient() {
            handleError(.insufficientTracking)
            return
        }
        
        // 執行平面優先的 hit test
        // 需求: 3.1 - 優先檢測已偵測的平面
        guard let (hitResult, planeAnchor) = arManager.performHitTestOnPlanes(at: screenCenter) else {
            // 未命中平面，顯示提示訊息
            // 需求: 3.3 - 未命中平面時拒絕放置測量點
            updateStatusLabel("請將游標對準已偵測的平面")
            showHitTestFailureAnimation()
            return
        }
        
        // 創建錨定測量點
        // 需求: 4.1 - 將測量點錨定到 Plane Anchor
        let anchoredPoint = arManager.createAnchoredPoint(on: planeAnchor, at: hitResult)
        
        // 取得世界座標用於顯示標記
        let position = anchoredPoint.worldPosition()
        
        // 驗證測量點有效性
        do {
            try validateMeasurementPoint(position)
            
            // 驗證測量距離
            if case .startPointRecorded(let startPosition) = stateManager.currentState {
                let distance = stateManager.calculateDistance(from: startPosition, to: position)
                try validateMeasurementDistance(distance)
            }
        } catch {
            handleError(error as? ManualMeasurementError ?? .invalidMeasurementPoint)
            return
        }
        
        // 記錄終點
        stateManager.recordEndPoint(position)
        
        // 顯示終點標記
        renderer.addEndMarker(at: position)
        
        // 取得最終距離
        if case .measurementComplete(let start, let end, let distance) = stateManager.currentState {
            // 繪製最終測量線
            renderer.drawLine(from: start, to: end, color: .yellow)
            
            // 計算中點位置
            let midpoint = SCNVector3(
                (start.x + end.x) / 2,
                (start.y + end.y) / 2,
                (start.z + end.z) / 2
            )
            
            // 顯示最終距離
            renderer.showDistance(distance, at: midpoint)
            
            // 更新 UI
            let distanceInCm = distance * 100
            updateStatusLabel(String(format: "測量完成：%.1f cm", distanceInCm))
            updateMeasureButton(title: "重新測量")
        }
    }
    
    /// 處理 MeasurementComplete 狀態的按鈕點擊
    private func handleMeasurementCompleteState() {
        // 清除視覺元素
        renderer.clearAllVisuals()
        
        // 重置狀態
        stateManager.reset()
        
        // 重新顯示中心游標
        renderer.showCenterReticle(on: view)
        
        // 更新 UI
        updateStatusLabel("移動裝置以偵測表面")
        updateMeasureButton(title: "開始測量")
    }
    
    /// 顯示 hit test 失敗的視覺回饋
    private func showHitTestFailureAnimation() {
        // 簡單的震動動畫
        UIView.animate(withDuration: 0.1, animations: {
            self.measureButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.measureButton.transform = .identity
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// 處理錯誤並顯示適當的使用者回饋
    /// 需求: 2.4
    private func handleError(_ error: ManualMeasurementError) {
        switch error {
        case .arSessionFailed:
            // AR Session 失敗：顯示錯誤訊息和重試按鈕
            updateStatusLabel(error.localizedDescription ?? "AR Session 失敗")
            showRetryButton()
            
        case .hitTestFailed:
            // Hit Test 失敗：顯示提示並保持當前狀態
            updateStatusLabel(error.localizedDescription ?? "無法偵測表面")
            showHitTestFailureAnimation()
            
        case .invalidMeasurementPoint:
            // 無效測量點：顯示錯誤訊息
            updateStatusLabel(error.localizedDescription ?? "測量點無效")
            showHitTestFailureAnimation()
            
        case .insufficientTracking:
            // 追蹤品質不足：顯示警告
            showTrackingWarning(error.localizedDescription ?? "追蹤品質不足")
        }
    }
    
    /// 檢查追蹤品質是否足夠
    /// 需求: 2.4
    private func isTrackingQualitySufficient() -> Bool {
        guard let trackingState = arManager.trackingState else {
            return false
        }
        
        switch trackingState {
        case .normal:
            // 追蹤正常，隱藏警告
            hideTrackingWarning()
            return true
            
        case .limited(let reason):
            // 追蹤受限，顯示警告但允許繼續
            var warningMessage = "追蹤品質受限"
            switch reason {
            case .excessiveMotion:
                warningMessage = "移動過快，請放慢速度"
            case .insufficientFeatures:
                warningMessage = "特徵點不足，請移動到特徵豐富的環境"
            case .initializing:
                warningMessage = "正在初始化追蹤..."
            case .relocalizing:
                warningMessage = "正在重新定位..."
            @unknown default:
                break
            }
            showTrackingWarning(warningMessage)
            return false
            
        case .notAvailable:
            // 追蹤不可用
            showTrackingWarning("追蹤不可用")
            return false
        }
    }
    
    /// 驗證測量點有效性
    /// 需求: 2.4
    private func validateMeasurementPoint(_ position: SCNVector3) throws {
        // 檢查座標是否有效（不是 NaN 或 Inf）
        guard position.x.isFinite && position.y.isFinite && position.z.isFinite else {
            throw ManualMeasurementError.invalidMeasurementPoint
        }
        
        // 檢查點是否在合理範圍內（距離相機不超過 10 公尺）
        guard let cameraPosition = arView.pointOfView?.position else {
            throw ManualMeasurementError.invalidMeasurementPoint
        }
        
        let distanceFromCamera = stateManager.calculateDistance(from: cameraPosition, to: position)
        guard distanceFromCamera <= 10.0 else {
            throw ManualMeasurementError.invalidMeasurementPoint
        }
    }
    
    /// 驗證測量距離有效性
    /// 需求: 2.4
    private func validateMeasurementDistance(_ distance: Float) throws {
        // 檢查距離是否在合理範圍內（1 公分 - 10 公尺）
        let minDistance: Float = 0.01  // 1 公分
        let maxDistance: Float = 10.0  // 10 公尺
        
        guard distance >= minDistance && distance <= maxDistance else {
            throw ManualMeasurementError.invalidMeasurementPoint
        }
    }
    
    /// 顯示追蹤品質警告
    private func showTrackingWarning(_ message: String) {
        DispatchQueue.main.async {
            if self.trackingWarningView == nil {
                // 建立警告視圖
                let warningView = UIView()
                warningView.translatesAutoresizingMaskIntoConstraints = false
                warningView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
                warningView.layer.cornerRadius = 8
                
                let warningLabel = UILabel()
                warningLabel.translatesAutoresizingMaskIntoConstraints = false
                warningLabel.textColor = .white
                warningLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                warningLabel.textAlignment = .center
                warningLabel.numberOfLines = 0
                warningLabel.tag = 100  // 用於後續更新文字
                
                warningView.addSubview(warningLabel)
                self.view.addSubview(warningView)
                
                NSLayoutConstraint.activate([
                    warningView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                    warningView.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 10),
                    warningView.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: 20),
                    warningView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -20),
                    
                    warningLabel.topAnchor.constraint(equalTo: warningView.topAnchor, constant: 8),
                    warningLabel.bottomAnchor.constraint(equalTo: warningView.bottomAnchor, constant: -8),
                    warningLabel.leadingAnchor.constraint(equalTo: warningView.leadingAnchor, constant: 12),
                    warningLabel.trailingAnchor.constraint(equalTo: warningView.trailingAnchor, constant: -12)
                ])
                
                self.trackingWarningView = warningView
            }
            
            // 更新警告訊息
            if let warningLabel = self.trackingWarningView?.viewWithTag(100) as? UILabel {
                warningLabel.text = message
            }
        }
    }
    
    /// 隱藏追蹤品質警告
    private func hideTrackingWarning() {
        DispatchQueue.main.async {
            self.trackingWarningView?.removeFromSuperview()
            self.trackingWarningView = nil
        }
    }
    
    /// 顯示重試按鈕（用於 AR Session 失敗）
    private func showRetryButton() {
        DispatchQueue.main.async {
            if self.retryButton == nil {
                // 創建重試按鈕
                let button = UIButton(type: .system)
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setTitle("重試", for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                button.backgroundColor = UIColor.systemBlue
                button.setTitleColor(.white, for: .normal)
                button.layer.cornerRadius = 8
                button.addTarget(self, action: #selector(self.retryARSession), for: .touchUpInside)
                
                self.view.addSubview(button)
                
                NSLayoutConstraint.activate([
                    button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -70),
                    button.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 20),
                    button.widthAnchor.constraint(equalToConstant: 120),
                    button.heightAnchor.constraint(equalToConstant: 44)
                ])
                
                self.retryButton = button
                
                // 創建診斷按鈕
                let diagButton = UIButton(type: .system)
                diagButton.translatesAutoresizingMaskIntoConstraints = false
                diagButton.setTitle("診斷", for: .normal)
                diagButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                diagButton.backgroundColor = UIColor.systemOrange
                diagButton.setTitleColor(.white, for: .normal)
                diagButton.layer.cornerRadius = 8
                diagButton.addTarget(self, action: #selector(self.showDiagnostics), for: .touchUpInside)
                diagButton.tag = 999 // 用於識別診斷按鈕
                
                self.view.addSubview(diagButton)
                
                NSLayoutConstraint.activate([
                    diagButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 70),
                    diagButton.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 20),
                    diagButton.widthAnchor.constraint(equalToConstant: 120),
                    diagButton.heightAnchor.constraint(equalToConstant: 44)
                ])
            }
        }
    }
    
    /// 隱藏重試按鈕
    private func hideRetryButton() {
        DispatchQueue.main.async {
            self.retryButton?.removeFromSuperview()
            self.retryButton = nil
            
            // 同時移除診斷按鈕
            self.view.subviews.first(where: { $0.tag == 999 })?.removeFromSuperview()
        }
    }
    
    /// 重試 AR Session
    @objc private func retryARSession() {
        hideRetryButton()
        setupARSession()
    }
    
    /// 顯示診斷資訊
    @objc private func showDiagnostics() {
        let diagnostics = diagnoseARTrackingIssue()
        
        let alert = UIAlertController(
            title: "AR 追蹤診斷",
            message: diagnostics,
            preferredStyle: .alert
        )
        
        // 如果相機權限被拒絕，提供前往設定的選項
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .denied || cameraStatus == .restricted {
            alert.addAction(UIAlertAction(title: "前往設定", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        
        present(alert, animated: true)
    }
    
    // MARK: - AR Session Setup
    
    /// 設置並啟動 AR Session
    /// 需求: 1.1
    private func setupARSession() {
        // 1. 檢查裝置是否支援 ARKit
        guard ARWorldTrackingConfiguration.isSupported else {
            handleError(.arSessionFailed)
            showAlert(title: "不支援 AR", message: "此裝置不支援 AR 功能，需要 A9 或更新的處理器。")
            return
        }
        
        // 2. 檢查相機權限
        checkCameraPermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                // 權限已授予，啟動 AR Session
                self.startARSessionWithConfiguration()
            } else {
                // 權限被拒絕
                self.handleError(.arSessionFailed)
                self.showCameraPermissionAlert()
            }
        }
    }
    
    /// 檢查相機權限
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // 已授權
            completion(true)
            
        case .notDetermined:
            // 尚未詢問，請求權限
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            // 被拒絕或受限
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
    
    /// 啟動 AR Session（權限已確認）
    private func startARSessionWithConfiguration() {
        print("🎬 ViewController: Starting AR session with configuration...")
        print("   - Device: \(UIDevice.current.model)")
        print("   - iOS: \(UIDevice.current.systemVersion)")
        print("   - ARKit supported: \(ARWorldTrackingConfiguration.isSupported)")
        
        // 確保 session delegate 已設置
        print("   - Session delegate: \(arView.session.delegate != nil ? "✅ Set" : "❌ Not set")")
        if arView.session.delegate == nil {
            print("⚠️ Setting session delegate...")
            arView.session.delegate = self
        }
        
        // 先暫停任何現有的 session
        print("⏸️ Pausing any existing session...")
        arView.session.pause()
        
        // 等待一下確保 session 完全停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            print("🔧 Configuring AR session...")
            
            // 配置 ARWorldTrackingConfiguration
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.isLightEstimationEnabled = true
            
            // 不要啟用 scene depth，可能導致問題
            // if #available(iOS 13.0, *) {
            //     if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            //         configuration.frameSemantics = .sceneDepth
            //     }
            // }
            
            print("   - Plane detection: horizontal, vertical")
            print("   - Light estimation: enabled")
            
            // 使用重置選項重啟 session
            print("🚀 Running AR session with reset options...")
            
            // iOS 16 相容的選項
            var runOptions: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
            
            // iOS 16+ 支援 resetSceneReconstruction
            if #available(iOS 16.0, *) {
                runOptions.insert(.resetSceneReconstruction)
                print("   - Using resetSceneReconstruction (iOS 16+)")
            }
            
            self.arView.session.run(configuration, options: runOptions)
            
            print("✅ AR session run command executed")
            
            // 等待 session 真正啟動
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                
                print("🔍 Checking if session started...")
                
                // 檢查是否有 frame
                if self.arView.session.currentFrame != nil {
                    print("✅ Session has frames - camera is working")
                } else {
                    print("❌ No frames yet - camera may not be working")
                    print("🔄 Attempting to restart session...")
                    
                    // 嘗試再次啟動
                    self.arView.session.run(configuration, options: [.resetTracking])
                }
                
                // 顯示中心游標
                self.renderer.showCenterReticle(on: self.view)
                
                // 更新狀態（初始為偵測階段）
                self.updateUIForDetectionState(.detecting)
                
                // 開始定期檢查
                self.startTrackingStateMonitoring()
            }
        }
    }
    
    /// 開始追蹤狀態監控
    private func startTrackingStateMonitoring() {
        print("📊 Starting tracking state monitoring...")
        
        var checkCount = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            checkCount += 1
            print("🔍 Tracking check #\(checkCount)...")
            self.checkTrackingState()
            
            // 如果追蹤正常，停止檢查
            if let frame = self.arView.session.currentFrame,
               case .normal = frame.camera.trackingState {
                print("✅ Tracking is normal, stopping checks")
                timer.invalidate()
                return
            }
            
            if checkCount >= 15 {
                timer.invalidate()
                print("⏹️ Stopped tracking state checks after 15 attempts")
                
                // 如果還是不行，顯示錯誤
                if self.arView.session.currentFrame == nil {
                    print("❌ CRITICAL: No frames after 15 seconds")
                    print("💡 This usually means:")
                    print("   1. Camera is being used by another app")
                    print("   2. Device needs to be restarted")
                    print("   3. iOS bug - try closing and reopening the app")
                    
                    DispatchQueue.main.async {
                        self.showCriticalError()
                    }
                }
            }
        }
    }
    
    /// 顯示嚴重錯誤訊息
    private func showCriticalError() {
        let alert = UIAlertController(
            title: "相機無法啟動",
            message: """
            AR 相機無法啟動。請嘗試：
            
            1. 完全關閉此應用程式
            2. 關閉其他使用相機的應用程式
            3. 重新啟動 iPhone
            4. 重新開啟此應用程式
            
            如果問題持續，可能是 iOS 系統問題。
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "關閉應用程式", style: .destructive) { _ in
            exit(0)
        })
        
        alert.addAction(UIAlertAction(title: "重試", style: .default) { [weak self] _ in
            self?.setupARSession()
        })
        
        present(alert, animated: true)
    }
    
    /// 檢查並輸出當前追蹤狀態
    private func checkTrackingState() {
        guard let frame = arView.session.currentFrame else {
            print("   ❌ No current frame available")
            return
        }
        
        let camera = frame.camera
        let stateDescription = arManager.getTrackingStateDescription()
        
        print("   📍 Tracking state: \(stateDescription)")
        
        switch camera.trackingState {
        case .normal:
            print("      ✅ Normal tracking")
        case .limited(let reason):
            print("      ⚠️ Limited: \(reason)")
            switch reason {
            case .excessiveMotion:
                print("         → Move slower")
            case .insufficientFeatures:
                print("         → Point at textured surface")
            case .initializing:
                print("         → Wait for initialization")
            case .relocalizing:
                print("         → Relocalizing...")
            @unknown default:
                print("         → Unknown reason")
            }
        case .notAvailable:
            print("      ❌ Not available")
            
            // 詳細診斷
            let cameraAuth = AVCaptureDevice.authorizationStatus(for: .video)
            print("         → Camera permission: \(cameraAuth)")
            print("         → ARKit supported: \(ARWorldTrackingConfiguration.isSupported)")
        }
        
        // 檢查平面檢測
        let anchors = frame.anchors
        let planeAnchors = anchors.compactMap { $0 as? ARPlaneAnchor }
        print("   🎯 Detected planes: \(planeAnchors.count)")
    }
    
    /// 顯示相機權限提示
    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "需要相機權限",
            message: "此應用程式需要相機權限才能使用 AR 測量功能。請在「設定」中開啟相機權限。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "前往設定", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    /// 顯示一般提示訊息
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Realtime Preview
    
    /// 更新即時預覽
    /// 需求: 3.1, 3.2, 3.4, 3.5
    private func updateRealtimePreview() {
        // 取得螢幕中心點
        let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        
        // 執行平面優先的 hit test 來更新游標狀態
        // 需求: 3.4, 3.5 - 根據是否命中平面更新游標顏色
        if let (hitResult, _) = arManager.performHitTestOnPlanes(at: screenCenter) {
            // 命中平面，游標顯示綠色
            renderer.setReticleState(.onPlane)
            
            // 只在 StartPointRecorded 狀態時更新測量線預覽
            if case .startPointRecorded(let startPosition) = stateManager.currentState {
                // 取得當前位置
                let currentPosition = arManager.worldPosition(from: hitResult)
                
                // 更新測量線
                renderer.updateLine(to: currentPosition)
                
                // 計算當前距離
                let distance = stateManager.calculateDistance(from: startPosition, to: currentPosition)
                
                // 計算中點位置
                let midpoint = SCNVector3(
                    (startPosition.x + currentPosition.x) / 2,
                    (startPosition.y + currentPosition.y) / 2,
                    (startPosition.z + currentPosition.z) / 2
                )
                
                // 更新距離顯示
                renderer.showDistance(distance, at: midpoint)
            }
        } else {
            // 未命中平面，游標顯示紅色
            renderer.setReticleState(.offPlane)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 更新狀態標籤文字
    private func updateStatusLabel(_ text: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = text
        }
    }
    
    /// 更新測量按鈕文字
    private func updateMeasureButton(title: String) {
        DispatchQueue.main.async {
            self.measureButton.setTitle(title, for: .normal)
        }
    }
    
    /// 顯示錯誤提示
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "錯誤", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - ARSCNViewDelegate

extension ManualMeasurementViewController: ARSCNViewDelegate {
    
    /// 每幀更新回調，用於即時預覽
    /// 實作節流機制限制為 30 FPS
    /// 需求: 3.1, 3.5
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Update performance monitoring (FPS tracking)
        performanceMonitor.updateFPS(at: time)
        
        // 節流機制：限制更新頻率為 30 FPS
        guard time - lastUpdateTime >= updateInterval else {
            return
        }
        
        lastUpdateTime = time
        
        // Update node count for leak detection (every 30 frames)
        if Int(time * 30) % 30 == 0 {
            performanceMonitor.updateNodeCount(from: arView)
        }
        
        // 在主執行緒更新即時預覽和追蹤品質監控
        DispatchQueue.main.async { [weak self] in
            self?.updateRealtimePreview()
            self?.monitorTrackingQuality()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // 處理 AR Session 失敗
        // 需求: 2.4
        print("❌ ARSession failed with error: \(error.localizedDescription)")
        
        if let arError = error as? ARError {
            print("   - ARError code: \(arError.code.rawValue)")
            print("   - ARError description: \(arError.localizedDescription)")
            
            switch arError.code {
            case .cameraUnauthorized:
                print("   - Reason: Camera unauthorized")
            case .unsupportedConfiguration:
                print("   - Reason: Unsupported configuration")
            case .sensorUnavailable:
                print("   - Reason: Sensor unavailable")
            case .sensorFailed:
                print("   - Reason: Sensor failed")
            default:
                print("   - Reason: Other (\(arError.code))")
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.handleError(.arSessionFailed)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("⏸️ ARSession was interrupted")
        updateStatusLabel("AR Session 已中斷")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("▶️ ARSession interruption ended")
        updateStatusLabel("AR Session 已恢復")
        hideRetryButton()
        // 重新啟動 session
        setupARSession()
    }
}

// MARK: - ARSessionDelegate

extension ManualMeasurementViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let stateDescription = arManager.getTrackingStateDescription()
        print("📍 Tracking state changed: \(stateDescription)")
        
        // 更新追蹤品質監控器
        trackingQualityMonitor.updateTrackingState(camera)
        
        switch camera.trackingState {
        case .normal:
            print("   ✅ Tracking is working normally")
        case .limited(let reason):
            print("   ⚠️ Tracking is limited: \(reason)")
        case .notAvailable:
            print("   ❌ Tracking is not available")
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("➕ Added \(anchors.count) anchor(s)")
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                print("   - Plane anchor: \(planeAnchor.alignment)")
                // 只在非測量模式下接受新平面
                // 需求: 7.4 - 測量模式下停止新平面視覺化
                if planeDetectionManager.state != .measurementMode {
                    planeDetectionManager.addPlane(planeAnchor)
                }
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // 更新平面錨點（即使在測量模式下也允許更新現有平面）
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                planeDetectionManager.updatePlane(planeAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("➖ Removed \(anchors.count) anchor(s)")
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                planeDetectionManager.removePlane(planeAnchor)
            }
        }
    }
    
    /// 監控追蹤品質並顯示警告
    /// 需求: 2.4
    private func monitorTrackingQuality() {
        guard let trackingState = arManager.trackingState else {
            showTrackingWarning("無法取得追蹤狀態")
            return
        }
        
        switch trackingState {
        case .normal:
            // 追蹤正常，隱藏警告
            hideTrackingWarning()
            
        case .limited(let reason):
            // 追蹤受限，顯示警告
            var warningMessage = "追蹤品質受限"
            switch reason {
            case .excessiveMotion:
                warningMessage = "移動過快，請放慢速度"
            case .insufficientFeatures:
                warningMessage = "特徵點不足，請移動到特徵豐富的環境"
            case .initializing:
                warningMessage = "正在初始化追蹤..."
            case .relocalizing:
                warningMessage = "正在重新定位..."
            @unknown default:
                warningMessage = "追蹤品質受限"
            }
            showTrackingWarning(warningMessage)
            
        case .notAvailable:
            // 追蹤不可用 - 提供詳細診斷
            let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            var warningMessage = "追蹤不可用"
            
            switch cameraStatus {
            case .denied, .restricted:
                warningMessage = "追蹤不可用：相機權限被拒絕\n請前往「設定」開啟權限"
            case .notDetermined:
                warningMessage = "追蹤不可用：等待相機權限"
            case .authorized:
                // 權限已授予但追蹤仍不可用，可能是其他問題
                if !ARWorldTrackingConfiguration.isSupported {
                    warningMessage = "追蹤不可用：裝置不支援 AR"
                } else {
                    warningMessage = "追蹤不可用：請重新啟動應用程式"
                }
            @unknown default:
                warningMessage = "追蹤不可用：未知錯誤"
            }
            
            showTrackingWarning(warningMessage)
        }
    }
    
    /// 診斷 AR 追蹤問題
    private func diagnoseARTrackingIssue() -> String {
        var diagnostics: [String] = []
        
        // 1. 檢查裝置支援
        if !ARWorldTrackingConfiguration.isSupported {
            diagnostics.append("❌ 裝置不支援 ARKit")
        } else {
            diagnostics.append("✅ 裝置支援 ARKit")
        }
        
        // 2. 檢查相機權限
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .authorized:
            diagnostics.append("✅ 相機權限已授予")
        case .denied:
            diagnostics.append("❌ 相機權限被拒絕")
        case .restricted:
            diagnostics.append("❌ 相機權限受限")
        case .notDetermined:
            diagnostics.append("⚠️ 相機權限未確定")
        @unknown default:
            diagnostics.append("❓ 相機權限狀態未知")
        }
        
        // 3. 檢查追蹤狀態
        if let trackingState = arManager.trackingState {
            switch trackingState {
            case .normal:
                diagnostics.append("✅ 追蹤狀態正常")
            case .limited(let reason):
                diagnostics.append("⚠️ 追蹤受限：\(reason)")
            case .notAvailable:
                diagnostics.append("❌ 追蹤不可用")
            }
        } else {
            diagnostics.append("❌ 無法取得追蹤狀態")
        }
        
        return diagnostics.joined(separator: "\n")
    }
}
