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
    
    // MARK: - Properties
    private let referenceObjects = [
        "打火機",
        "硬幣",
        "信用卡",
        "iPhone",
        "原子筆"
    ]
    
    private var selectedReferenceIndex: Int = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
        setupTableView()
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
    }
    
    private func setupTableView() {
        defaultReferenceTableView.delegate = self
        defaultReferenceTableView.dataSource = self
        defaultReferenceTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReferenceCell")
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Set default values if this is the first launch
        if !defaults.bool(forKey: "hasLaunchedBefore") {
            defaults.set(0, forKey: "measurementUnit") // Default to cm
            defaults.set(0, forKey: "defaultReferenceIndex") // Default to lighter
            defaults.set(true, forKey: "showGuidance") // Show guidance by default
            defaults.set(false, forKey: "autoSave") // Don't auto-save by default
            defaults.set(true, forKey: "hasLaunchedBefore")
            defaults.synchronize()
        }
        
        // Load measurement unit preference (0 = cm, 1 = inch)
        let unitIndex = defaults.integer(forKey: "measurementUnit")
        unitSegmentedControl.selectedSegmentIndex = unitIndex
        
        // Load default reference object
        selectedReferenceIndex = defaults.integer(forKey: "defaultReferenceIndex")
        
        // Load guidance preference
        let showGuidance = defaults.bool(forKey: "showGuidance")
        showGuidanceSwitch.isOn = showGuidance
        
        // Load auto-save preference
        let autoSave = defaults.bool(forKey: "autoSave")
        autoSaveSwitch.isOn = autoSave
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        
        // Save measurement unit
        defaults.set(unitSegmentedControl.selectedSegmentIndex, forKey: "measurementUnit")
        
        // Save default reference object
        defaults.set(selectedReferenceIndex, forKey: "defaultReferenceIndex")
        
        // Save guidance preference
        defaults.set(showGuidanceSwitch.isOn, forKey: "showGuidance")
        
        // Save auto-save preference
        defaults.set(autoSaveSwitch.isOn, forKey: "autoSave")
        
        defaults.synchronize()
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
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
    
    @IBAction func unitSegmentedControlChanged(_ sender: UISegmentedControl) {
        // Unit changed, will be saved when user taps save
    }
    
    @IBAction func showGuidanceSwitchChanged(_ sender: UISwitch) {
        // Guidance preference changed, will be saved when user taps save
    }
    
    @IBAction func autoSaveSwitchChanged(_ sender: UISwitch) {
        // Auto-save preference changed, will be saved when user taps save
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
