//
//  AnnotationPreviewViewController.swift
//  CameraMeasurementApp
//
//  標註預覽視圖控制器
//  展示如何使用影像標註系統
//

import UIKit

class AnnotationPreviewViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let layoutSegmentedControl = UISegmentedControl(items: ["覆蓋", "側邊欄", "上下", "最小"])
    private let styleSegmentedControl = UISegmentedControl(items: ["預設", "專業", "鮮豔", "最小"])
    private let exportButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Properties
    var measurementRecord: MeasurementRecord? {
        didSet {
            updateAnnotatedImage()
        }
    }
    
    private var currentLayout: AnnotationLayout = .overlay
    private var currentStyle: AnnotationStyle = .default
    private var annotationService: ImageAnnotationService
    
    // MARK: - Initialization
    init() {
        self.annotationService = ImageAnnotationService()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.annotationService = ImageAnnotationService()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "標註預覽"
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .secondarySystemBackground
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        // Image View
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        scrollView.addSubview(imageView)
        
        // Layout Segmented Control
        layoutSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        layoutSegmentedControl.selectedSegmentIndex = 0
        layoutSegmentedControl.addTarget(self, action: #selector(layoutChanged), for: .valueChanged)
        view.addSubview(layoutSegmentedControl)
        
        // Style Segmented Control
        styleSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        styleSegmentedControl.selectedSegmentIndex = 0
        styleSegmentedControl.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        view.addSubview(styleSegmentedControl)
        
        // Export Button
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.setTitle("匯出", for: .normal)
        exportButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        view.addSubview(exportButton)
        
        // Share Button
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setTitle("分享", for: .normal)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        view.addSubview(shareButton)
        
        // Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Layout Segmented Control
            layoutSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            layoutSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            layoutSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Style Segmented Control
            styleSegmentedControl.topAnchor.constraint(equalTo: layoutSegmentedControl.bottomAnchor, constant: 10),
            styleSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            styleSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: styleSegmentedControl.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: exportButton.topAnchor, constant: -10),
            
            // Image View
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Export Button
            exportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            exportButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            exportButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Share Button
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            shareButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func layoutChanged() {
        switch layoutSegmentedControl.selectedSegmentIndex {
        case 0:
            currentLayout = .overlay
        case 1:
            currentLayout = .sidebar
        case 2:
            currentLayout = .topBottom
        case 3:
            currentLayout = .minimal
        default:
            currentLayout = .overlay
        }
        
        updateAnnotatedImage()
    }
    
    @objc private func styleChanged() {
        switch styleSegmentedControl.selectedSegmentIndex {
        case 0:
            currentStyle = .default
        case 1:
            currentStyle = .professional
        case 2:
            currentStyle = .vibrant
        case 3:
            currentStyle = .minimal
        default:
            currentStyle = .default
        }
        
        updateAnnotatedImage()
    }
    
    @objc private func exportTapped() {
        guard let record = measurementRecord else {
            showAlert(title: "錯誤", message: "沒有可匯出的測量記錄")
            return
        }
        
        activityIndicator.startAnimating()
        exportButton.isEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let urls = try ExportManager.shared.exportAnnotatedPackage(
                    record: record,
                    includeTextFile: true
                )
                
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.exportButton.isEnabled = true
                    self?.showAlert(
                        title: "匯出成功",
                        message: "已匯出 \(urls.count) 個檔案到文件目錄"
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.exportButton.isEnabled = true
                    self?.showAlert(
                        title: "匯出失敗",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    @objc private func shareTapped() {
        guard let image = imageView.image else {
            showAlert(title: "錯誤", message: "沒有可分享的影像")
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    // MARK: - Helper Methods
    private func updateAnnotatedImage() {
        guard let record = measurementRecord else { return }
        
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 更新標註服務配置
            self.annotationService.updateLayout(self.currentLayout)
            self.annotationService.updateStyle(self.currentStyle)
            
            // 建立標註影像
            let annotatedImage = self.annotationService.createAnnotatedImage(from: record)
            
            DispatchQueue.main.async {
                self.imageView.image = annotatedImage
                self.activityIndicator.stopAnimating()
                
                // 更新 scroll view content size
                if let image = annotatedImage {
                    self.imageView.frame.size = image.size
                    self.scrollView.contentSize = image.size
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension AnnotationPreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

// MARK: - Public Interface

extension AnnotationPreviewViewController {
    /// 設定測量記錄並顯示標註預覽
    func configure(with record: MeasurementRecord) {
        self.measurementRecord = record
    }
    
    /// 設定初始佈局
    func setInitialLayout(_ layout: AnnotationLayout) {
        self.currentLayout = layout
        
        switch layout {
        case .overlay:
            layoutSegmentedControl.selectedSegmentIndex = 0
        case .sidebar:
            layoutSegmentedControl.selectedSegmentIndex = 1
        case .topBottom:
            layoutSegmentedControl.selectedSegmentIndex = 2
        case .minimal:
            layoutSegmentedControl.selectedSegmentIndex = 3
        }
    }
    
    /// 設定初始樣式
    func setInitialStyle(_ style: AnnotationStyle) {
        self.currentStyle = style
        
        // 根據樣式設定 segmented control
        if style.primaryColor == AnnotationStyle.professional.primaryColor {
            styleSegmentedControl.selectedSegmentIndex = 1
        } else if style.primaryColor == AnnotationStyle.vibrant.primaryColor {
            styleSegmentedControl.selectedSegmentIndex = 2
        } else if style.lineWidth == AnnotationStyle.minimal.lineWidth {
            styleSegmentedControl.selectedSegmentIndex = 3
        } else {
            styleSegmentedControl.selectedSegmentIndex = 0
        }
    }
}
