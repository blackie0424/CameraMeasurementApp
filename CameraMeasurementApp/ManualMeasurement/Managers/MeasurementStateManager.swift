//
//  MeasurementStateManager.swift
//  CameraMeasurementApp
//
//  Manual AR Measurement - State Management
//

import Foundation
import SceneKit

/// 管理測量狀態和測量點資料
class MeasurementStateManager {
    
    // MARK: - Properties
    
    /// 當前測量狀態
    private(set) var currentState: MeasurementState = .initial
    
    // MARK: - Computed Properties
    
    /// 取得起點座標（如果已記錄）
    var startPoint: SCNVector3? {
        switch currentState {
        case .initial:
            return nil
        case .startPointRecorded(let position):
            return position
        case .measurementComplete(let start, _, _):
            return start
        }
    }
    
    /// 取得終點座標（如果已記錄）
    var endPoint: SCNVector3? {
        switch currentState {
        case .initial, .startPointRecorded:
            return nil
        case .measurementComplete(_, let end, _):
            return end
        }
    }
    
    // MARK: - Public Methods
    
    /// 記錄測量起點
    /// - Parameter position: 起點的 3D 世界座標
    func recordStartPoint(_ position: SCNVector3) {
        currentState = .startPointRecorded(position)
    }
    
    /// 記錄測量終點並計算距離
    /// - Parameter position: 終點的 3D 世界座標
    func recordEndPoint(_ position: SCNVector3) {
        guard let start = startPoint else {
            return
        }
        
        let distance = calculateDistance(from: start, to: position)
        currentState = .measurementComplete(start: start, end: position, distance: distance)
    }
    
    /// 計算兩點之間的歐幾里得距離
    /// - Parameters:
    ///   - start: 起點座標
    ///   - end: 終點座標
    /// - Returns: 距離（單位：公尺）
    func calculateDistance(from start: SCNVector3, to end: SCNVector3) -> Float {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    /// 重置測量狀態，清除所有測量資料
    func reset() {
        currentState = .initial
    }
}
