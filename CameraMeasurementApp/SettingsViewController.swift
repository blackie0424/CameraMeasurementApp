//
//  SettingsViewController.swift
//  CameraMeasurementApp
//
//  Created by Kiro on 2024-11-17.
//

import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var unitSegmentedControl: UISegmentedControl!
    @IBOutlet weak var defaultReferenceTableView: UITableView!
    @IBOutlet weak var showGuidanceSwitch: UISwitch!
    @IBOutlet weak var autoSaveSwitch: UISwitch!
    @IBOutlet weak var exportAllButton: UIButton!
    @IBOutlet weak var exportCSVButton: UIButton!
    @IBOutlet weak var exportImagesButton: UIButton!
    
    // MARK: - Properties
    private let settingsManager = SettingsManager.shared
    
    private let referenceObjects = [
        "打火機",
        "硬幣",
        "信用卡",
        "iPhone",
        "原子筆"
    ]
    
    private var selectedReferenceIndex: Int = 0
    private var hasUnsavedChanges = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadSettings()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "設定"
        view.backgroundColor = .systemBackground
        
        // Add navigation bar buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        // Add reset button
        let resetButton = UIBarButtonItem(
            title: "重置",
            style: .plain,
            target: self,
            action: #selector(resetButtonTapped)
        )
        resetButton.tintColor = .systemRed
        
        navigationItem.leftBarButtonItems = [
            navigationItem.leftBarButtonItem!,
            resetButton
        ]
    }
    
    private func setupTableView() {
        defaultReferenceTableView.delegate = self
        defaultReferenceTableView.dataSource = self
        defaultReferenceTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReferenceCell")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: .settingsDidChange,
            object: nil
        )
    }
    
    private func loadSettings() {
        // Load measurement unit preference
        let unit = settingsManager.measurementUnit
        unitSegmentedControl.selectedSegmentIndex = unit.rawValue
        
        // Load default reference object
        selectedReferenceIndex = settingsManager.defaultReferenceIndex
        
        // Load guidance preference
        showGuidanceSwitch.isOn = settingsManager.shouldShowGuidance
        
        // Load auto-save preference
        autoSaveSwitch.isOn = settingsManager.shouldAutoSave
        
        // Reload table view to show selected reference
        defaultReferenceTableView.reloadData()
        
        hasUnsavedChanges = false
    }
    
    private func saveSettings() {
        // Save measurement unit
        if let unit = UserDefaults.MeasurementUnit(rawValue: unitSegmentedControl.selectedSegmentIndex) {
            settingsManager.measurementUnit = unit
        }
        
        // Save default reference object
        settingsManager.defaultReferenceIndex = selectedReferenceIndex
        
        // Save guidance preference
        settingsManager.shouldShowGuidance = showGuidanceSwitch.isOn
        
        // Save auto-save preference
        settingsManager.shouldAutoSave = autoSaveSwitch.isOn
        
        hasUnsavedChanges = false
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        if hasUnsavedChanges {
            showUnsavedChangesAlert()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func saveButtonTapped() {
        saveSettings()
        
        // Show confirmation
        let alert = UIAlertController(
            title: "設定已儲存",
            message: "您的偏好設定已成功儲存",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func resetButtonTapped() {
        let alert = UIAlertController(
            title: "重置設定",
            message: "您確定要將所有設定重置為預設值嗎？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "重置全部", style: .destructive) { [weak self] _ in
            self?.resetAllSettings()
        })
        
        alert.addAction(UIAlertAction(title: "僅重置測量設定", style: .default) { [weak self] _ in
            self?.resetMeasurementSettings()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func handleSettingsChange() {
        // Settings changed externally, reload
        loadSettings()
    }
    
    @IBAction func unitSegmentedControlChanged(_ sender: UISegmentedControl) {
        hasUnsavedChanges = true
    }
    
    @IBAction func showGuidanceSwitchChanged(_ sender: UISwitch) {
        hasUnsavedChanges = true
    }
    
    @IBAction func autoSaveSwitchChanged(_ sender: UISwitch) {
        hasUnsavedChanges = true
    }
    
    @IBAction func exportAllButtonTapped(_ sender: UIButton) {
        exportAllData()
    }
    
    @IBAction func exportCSVButtonTapped(_ sender: UIButton) {
        exportCSVOnly()
    }
    
    @IBAction func exportImagesButtonTapped(_ sender: UIButton) {
        exportImagesOnly()
    }
    
    // MARK: - Helper Methods
    private func resetAllSettings() {
        settingsManager.resetToDefaults()
        loadSettings()
        
        let alert = UIAlertController(
            title: "重置完成",
            message: "所有設定已重置為預設值",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    private func resetMeasurementSettings() {
        settingsManager.resetMeasurementSettings()
        loadSettings()
        
        let alert = UIAlertController(
            title: "重置完成",
            message: "測量設定已重置為預設值",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    private func showUnsavedChangesAlert() {
        let alert = UIAlertController(
            title: "未儲存的變更",
            message: "您有未儲存的變更，是否要儲存？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "儲存", style: .default) { [weak self] _ in
            self?.saveSettings()
            self?.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(UIAlertAction(title: "放棄", style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Export Methods
    
    private func exportAllData() {
        showLoadingIndicator()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Fetch all records
                let records = try DataManager.shared.fetchAllRecords()
                
                guard !records.isEmpty else {
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator()
                        self?.showAlert(title: "無資料", message: "沒有可匯出的測量記錄")
                    }
                    return
                }
                
                // Export all data (CSV + images)
                let exportedURLs = try ExportManager.shared.batchExport(records: records, exportImages: true)
                
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.showExportSuccess(urls: exportedURLs, recordCount: records.count)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.showAlert(title: "匯出失敗", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func exportCSVOnly() {
        showLoadingIndicator()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Fetch all records
                let records = try DataManager.shared.fetchAllRecords()
                
                guard !records.isEmpty else {
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator()
                        self?.showAlert(title: "無資料", message: "沒有可匯出的測量記錄")
                    }
                    return
                }
                
                // Export CSV only
                let csvString = try ExportManager.shared.exportToCSV(records: records)
                let fileURL = try ExportManager.shared.saveCSVToFile(csvString)
                
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.showExportSuccess(urls: [fileURL], recordCount: records.count)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.showAlert(title: "匯出失敗", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func exportImagesOnly() {
        showLoadingIndicator()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Fetch all records
                let records = try DataManager.shared.fetchAllRecords()
                
                guard !records.isEmpty else {
                    DispatchQueue.main.async {
                        self?.hideLoadingIndicator()
                        self?.showAlert(title: "無資料", message: "沒有可匯出的測量記錄")
                    }
                    return
                }
                
                // Export annotated images
                var exportedURLs: [URL] = []
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestamp = dateFormatter.string(from: Date())
                
                for (index, record) in records.enumerated() {
                    let annotatedImage = try ExportManager.shared.createAnnotatedImage(from: record)
                    let filename = "measurement_\(timestamp)_\(index + 1).jpg"
                    let imageURL = try ExportManager.shared.saveAnnotatedImageToFile(annotatedImage, filename: filename)
                    exportedURLs.append(imageURL)
                }
                
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.showExportSuccess(urls: exportedURLs, recordCount: records.count)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.showAlert(title: "匯出失敗", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showExportSuccess(urls: [URL], recordCount: Int) {
        let message = "已成功匯出 \(recordCount) 筆測量記錄\n共 \(urls.count) 個檔案"
        
        let alert = UIAlertController(title: "匯出成功", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "分享檔案", style: .default) { [weak self] _ in
            self?.shareExportedFiles(urls)
        })
        
        alert.addAction(UIAlertAction(title: "完成", style: .default))
        
        present(alert, animated: true)
    }
    
    private func shareExportedFiles(_ urls: [URL]) {
        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = exportAllButton
            popover.sourceRect = exportAllButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    private func showLoadingIndicator() {
        // Simple loading indicator
        let alert = UIAlertController(title: nil, message: "正在匯出資料...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true)
    }
    
    private func hideLoadingIndicator() {
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return referenceObjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReferenceCell", for: indexPath)
        cell.textLabel?.text = referenceObjects[indexPath.row]
        
        // Show checkmark for selected reference object
        if indexPath.row == selectedReferenceIndex {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Update selected reference object
        selectedReferenceIndex = indexPath.row
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "預設參考物件"
    }
}
