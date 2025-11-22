//
//  PlaneDetectionManager.swift
//  CameraMeasurementApp
//
//  Created for AR Plane Detection Accuracy feature
//

import Foundation
import ARKit

// Note: PlaneDetectionState, PlaneInfo, and PlaneType are defined in the Models folder
// and will be accessible when compiled as part of the same target

/// 管理平面偵測流程、狀態和啟用條件
/// 負責追蹤所有偵測到的平面並判斷測量功能的啟用條件
class PlaneDetectionManager {
    
    // MARK: - Properties
    
    /// 當前偵測狀態
    private(set) var state: PlaneDetectionState = .detecting
    
    /// 已偵測到的平面資訊字典，使用 UUID 作為 key
    private var detectedPlanes: [UUID: PlaneInfo] = [:]
    
    /// 狀態變更回調
    var onStateChanged: ((PlaneDetectionState) -> Void)?
    
    /// 平面新增回調
    var onPlaneAdded: ((PlaneInfo) -> Void)?
    
    /// 平面更新回調
    var onPlaneUpdated: ((PlaneInfo) -> Void)?
    
    /// 平面移除回調
    var onPlaneRemoved: ((UUID) -> Void)?
    
    // MARK: - Constants
    
    /// 啟用測量功能所需的最小平面數量
    private let minimumPlaneCount = 2
    
    /// 啟用測量功能所需的最小總面積（平方公尺）
    private let minimumTotalArea: Float = 0.5
    
    // MARK: - Initialization
    
    init() {
        // 初始化為偵測狀態
        self.state = .detecting
    }
    
    // MARK: - Plane Management
    
    /// 新增偵測到的平面
    /// - Parameter anchor: ARKit 偵測到的平面錨點
    func addPlane(_ anchor: ARPlaneAnchor) {
        let area = calculatePlaneArea(anchor)
        let type = determinePlaneType(anchor)
        
        let planeInfo = PlaneInfo(
            anchor: anchor,
            area: area,
            type: type,
            detectionTime: Date()
        )
        
        detectedPlanes[anchor.identifier] = planeInfo
        onPlaneAdded?(planeInfo)
        
        // 檢查是否滿足啟用條件
        checkAndUpdateState()
    }
    
    /// 更新已存在的平面
    /// - Parameter anchor: 更新後的平面錨點
    func updatePlane(_ anchor: ARPlaneAnchor) {
        guard let existingPlane = detectedPlanes[anchor.identifier] else {
            return
        }
        
        let area = calculatePlaneArea(anchor)
        let type = determinePlaneType(anchor)
        
        let updatedPlaneInfo = PlaneInfo(
            anchor: anchor,
            area: area,
            type: type,
            detectionTime: existingPlane.detectionTime
        )
        
        detectedPlanes[anchor.identifier] = updatedPlaneInfo
        onPlaneUpdated?(updatedPlaneInfo)
        
        // 檢查是否滿足啟用條件（面積可能改變）
        checkAndUpdateState()
    }
    
    /// 移除不再追蹤的平面
    /// - Parameter anchor: 被移除的平面錨點
    func removePlane(_ anchor: ARPlaneAnchor) {
        detectedPlanes.removeValue(forKey: anchor.identifier)
        onPlaneRemoved?(anchor.identifier)
        
        // 檢查是否仍滿足啟用條件
        checkAndUpdateState()
    }
    
    // MARK: - Area Calculation
    
    /// 計算平面面積
    /// - Parameter anchor: 平面錨點
    /// - Returns: 平面面積（平方公尺）
    private func calculatePlaneArea(_ anchor: ARPlaneAnchor) -> Float {
        // 使用 extent.x * extent.z 計算面積
        return anchor.extent.x * anchor.extent.z
    }
    
    /// 判斷平面類型
    /// - Parameter anchor: 平面錨點
    /// - Returns: 平面類型（水平或垂直）
    private func determinePlaneType(_ anchor: ARPlaneAnchor) -> PlaneType {
        return anchor.alignment == .horizontal ? .horizontal : .vertical
    }
    
    // MARK: - Statistics
    
    /// 獲取已偵測的平面數量
    /// - Returns: 平面數量
    func getPlaneCount() -> Int {
        return detectedPlanes.count
    }
    
    /// 獲取所有平面的總面積
    /// - Returns: 總面積（平方公尺）
    func getTotalPlaneArea() -> Float {
        return detectedPlanes.values.reduce(0) { $0 + $1.area }
    }
    
    /// 獲取所有已偵測的平面資訊
    /// - Returns: 平面資訊陣列
    func getAllPlanes() -> [PlaneInfo] {
        return Array(detectedPlanes.values)
    }
    
    /// 根據 UUID 獲取平面資訊
    /// - Parameter identifier: 平面錨點的 UUID
    /// - Returns: 平面資訊，如果不存在則返回 nil
    func getPlane(by identifier: UUID) -> PlaneInfo? {
        return detectedPlanes[identifier]
    }
    
    // MARK: - State Management
    
    /// 檢查是否滿足測量啟用條件
    /// 條件：平面數量 ≥ 2 或總面積 ≥ 0.5 平方公尺
    /// - Returns: 是否滿足條件
    func checkReadyCondition() -> Bool {
        let planeCount = getPlaneCount()
        let totalArea = getTotalPlaneArea()
        
        return planeCount >= minimumPlaneCount || totalArea >= minimumTotalArea
    }
    
    /// 檢查並更新狀態
    private func checkAndUpdateState() {
        // 只在 detecting 狀態下檢查是否可以轉換到 ready
        if state == .detecting && checkReadyCondition() {
            transitionToState(.ready)
        }
        // 如果在 ready 狀態但不再滿足條件，回到 detecting
        else if state == .ready && !checkReadyCondition() {
            transitionToState(.detecting)
        }
    }
    
    /// 進入測量模式
    /// 固定當前偵測到的平面，停止接受新平面
    func enterMeasurementMode() {
        guard state == .ready else {
            return
        }
        transitionToState(.measurementMode)
    }
    
    /// 重置偵測
    /// 清除所有平面並回到偵測狀態
    func resetDetection() {
        detectedPlanes.removeAll()
        transitionToState(.detecting)
    }
    
    /// 狀態轉換
    /// - Parameter newState: 新狀態
    private func transitionToState(_ newState: PlaneDetectionState) {
        guard state != newState else {
            return
        }
        
        state = newState
        onStateChanged?(newState)
    }
}
