//
//  MeasurementRenderer.swift
//  CameraMeasurementApp
//
//  負責所有測量視覺元素的渲染
//

import UIKit
import SceneKit
import ARKit

/// 游標狀態枚舉
/// 需求: 3.4, 3.5
enum ReticleState {
    case onPlane        // 對準平面 - 綠色
    case offPlane       // 未對準平面 - 紅色
    case disabled       // 禁用 - 灰色
}

class MeasurementRenderer {
    // MARK: - Properties
    
    /// ARSCNView 引用
    private weak var sceneView: ARSCNView?
    
    /// 測量線節點
    private var lineNode: SCNNode?
    
    /// 起點標記節點
    private var startMarkerNode: SCNNode?
    
    /// 終點標記節點
    private var endMarkerNode: SCNNode?
    
    /// 中心游標視圖
    private var reticleView: UIView?
    
    /// 距離標籤節點
    private var distanceLabelNode: SCNNode?
    
    /// 儲存起點位置（用於更新線條）
    private var startPosition: SCNVector3?
    
    /// 平面視覺化節點字典（key: plane anchor UUID）
    private var planeNodes: [UUID: SCNNode] = [:]
    
    // MARK: - Initialization
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
}

// MARK: - Center Reticle

extension MeasurementRenderer {
    /// 在視圖中心顯示白色圓形游標
    /// - Parameter view: 要添加游標的父視圖
    func showCenterReticle(on view: UIView) {
        // 如果已存在游標，先移除
        reticleView?.removeFromSuperview()
        
        // 建立白色圓形游標
        let diameter: CGFloat = 10
        let reticle = UIView(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        reticle.backgroundColor = .white
        reticle.alpha = 0.8
        reticle.layer.cornerRadius = diameter / 2
        reticle.isUserInteractionEnabled = false
        
        // 固定在螢幕中心
        reticle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reticle)
        
        NSLayoutConstraint.activate([
            reticle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reticle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            reticle.widthAnchor.constraint(equalToConstant: diameter),
            reticle.heightAnchor.constraint(equalToConstant: diameter)
        ])
        
        self.reticleView = reticle
    }
    
    /// 隱藏中心游標
    func hideCenterReticle() {
        reticleView?.removeFromSuperview()
        reticleView = nil
    }
    
    /// 設定游標狀態
    /// 根據狀態自動更新游標顏色
    /// - Parameter state: 游標狀態
    /// 需求: 3.4, 3.5
    func setReticleState(_ state: ReticleState) {
        let color: UIColor
        
        switch state {
        case .onPlane:
            // 對準平面時顯示綠色
            color = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
        case .offPlane:
            // 未對準平面時顯示紅色
            color = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)
        case .disabled:
            // 禁用時顯示灰色
            color = UIColor(white: 0.5, alpha: 0.5)
        }
        
        updateReticleColor(color)
    }
    
    /// 更新游標顏色
    /// - Parameter color: 要設定的顏色
    /// 需求: 3.4, 3.5
    func updateReticleColor(_ color: UIColor) {
        guard let reticleView = reticleView else { return }
        
        // 使用動畫平滑過渡顏色變化
        UIView.animate(withDuration: 0.2) {
            reticleView.backgroundColor = color
        }
    }
}

// MARK: - Measurement Markers

extension MeasurementRenderer {
    /// 在指定位置添加測量點標記
    /// - Parameters:
    ///   - position: 3D 世界座標位置
    ///   - color: 標記顏色
    /// - Returns: 建立的標記節點
    @discardableResult
    func addMarker(at position: SCNVector3, color: UIColor) -> SCNNode {
        // 建立球體幾何體（半徑 0.01 米）
        let sphere = SCNSphere(radius: 0.01)
        sphere.firstMaterial?.diffuse.contents = color
        sphere.firstMaterial?.lightingModel = .constant
        
        // 建立節點
        let markerNode = SCNNode(geometry: sphere)
        markerNode.position = position
        
        // 添加到場景
        sceneView?.scene.rootNode.addChildNode(markerNode)
        
        return markerNode
    }
    
    /// 添加起點標記
    /// - Parameter position: 起點位置
    func addStartMarker(at position: SCNVector3) {
        // 移除舊的起點標記
        startMarkerNode?.removeFromParentNode()
        
        // 建立黃色標記
        startMarkerNode = addMarker(at: position, color: .yellow)
        startPosition = position
    }
    
    /// 添加終點標記
    /// - Parameter position: 終點位置
    func addEndMarker(at position: SCNVector3) {
        // 移除舊的終點標記
        endMarkerNode?.removeFromParentNode()
        
        // 建立黃色標記
        endMarkerNode = addMarker(at: position, color: .yellow)
    }
}

// MARK: - Measurement Line

extension MeasurementRenderer {
    /// 繪製連接兩點的測量線
    /// - Parameters:
    ///   - start: 起點位置
    ///   - end: 終點位置
    ///   - color: 線條顏色
    func drawLine(from start: SCNVector3, to end: SCNVector3, color: UIColor) {
        // 移除舊的線條
        lineNode?.removeFromParentNode()
        
        // 建立新的線條節點
        lineNode = createLineNode(from: start, to: end, color: color)
        
        // 添加到場景
        if let lineNode = lineNode {
            sceneView?.scene.rootNode.addChildNode(lineNode)
        }
    }
    
    /// 更新測量線的終點位置（用於即時預覽）
    /// - Parameter currentPosition: 新的終點位置
    func updateLine(to currentPosition: SCNVector3) {
        guard let startPosition = startPosition else { return }
        
        // 優化：更新現有節點而非重建
        if let existingLine = lineNode {
            updateLineGeometry(node: existingLine, from: startPosition, to: currentPosition)
        } else {
            // 如果線條不存在，建立新的
            drawLine(from: startPosition, to: currentPosition, color: .yellow)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// 建立線條節點
    private func createLineNode(from start: SCNVector3, to end: SCNVector3, color: UIColor) -> SCNNode {
        // 計算兩點之間的距離
        let distance = start.distance(to: end)
        
        // 建立圓柱體作為線條（半徑 0.002 米）
        let cylinder = SCNCylinder(radius: 0.002, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = color
        cylinder.firstMaterial?.lightingModel = .constant
        
        // 建立節點
        let lineNode = SCNNode(geometry: cylinder)
        
        // 計算中點位置
        let midpoint = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        lineNode.position = midpoint
        
        // 計算旋轉角度使圓柱體對齊兩點
        let direction = SCNVector3(
            end.x - start.x,
            end.y - start.y,
            end.z - start.z
        )
        lineNode.look(at: end, up: sceneView?.scene.rootNode.worldUp ?? SCNVector3(0, 1, 0), localFront: SCNVector3(0, 1, 0))
        
        return lineNode
    }
    
    /// 更新現有線條節點的幾何體
    private func updateLineGeometry(node: SCNNode, from start: SCNVector3, to end: SCNVector3) {
        // 計算新的距離
        let distance = start.distance(to: end)
        
        // 更新圓柱體高度
        if let cylinder = node.geometry as? SCNCylinder {
            cylinder.height = CGFloat(distance)
        }
        
        // 更新位置到新的中點
        let midpoint = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        node.position = midpoint
        
        // 更新旋轉
        node.look(at: end, up: sceneView?.scene.rootNode.worldUp ?? SCNVector3(0, 1, 0), localFront: SCNVector3(0, 1, 0))
    }
}

// MARK: - SCNVector3 Extension

extension SCNVector3 {
    /// 計算到另一個向量的歐幾里得距離
    func distance(to vector: SCNVector3) -> Float {
        let dx = x - vector.x
        let dy = y - vector.y
        let dz = z - vector.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}

// MARK: - Distance Display

extension MeasurementRenderer {
    /// 在 3D 空間顯示距離標籤
    /// - Parameters:
    ///   - distance: 距離（單位：公尺）
    ///   - midpoint: 標籤顯示位置（通常是測量線中點）
    func showDistance(_ distance: Float, at midpoint: SCNVector3) {
        // 移除舊的距離標籤
        distanceLabelNode?.removeFromParentNode()
        
        // 建立距離標籤節點
        distanceLabelNode = createDistanceLabelNode(distance: distance, at: midpoint)
        
        // 添加到場景
        if let labelNode = distanceLabelNode {
            sceneView?.scene.rootNode.addChildNode(labelNode)
        }
    }
    
    /// 更新距離標籤的數值
    /// - Parameter distance: 新的距離值（單位：公尺）
    func updateDistanceLabel(_ distance: Float) {
        guard let labelNode = distanceLabelNode,
              let textGeometry = labelNode.geometry as? SCNText else {
            return
        }
        
        // 格式化距離為公分，保留一位小數
        let distanceInCm = distance * 100
        textGeometry.string = String(format: "%.1f cm", distanceInCm)
    }
    
    /// 更新距離標籤的位置
    /// - Parameter position: 新的位置
    func updateDistanceLabelPosition(_ position: SCNVector3) {
        distanceLabelNode?.position = position
    }
    
    // MARK: - Private Helper Methods
    
    /// 建立距離標籤節點
    private func createDistanceLabelNode(distance: Float, at position: SCNVector3) -> SCNNode {
        // 格式化距離為公分，保留一位小數
        let distanceInCm = distance * 100
        let distanceText = String(format: "%.1f cm", distanceInCm)
        
        // 建立 3D 文字
        let text = SCNText(string: distanceText, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        text.flatness = 0.1
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.firstMaterial?.lightingModel = .constant
        
        // 建立文字節點
        let textNode = SCNNode(geometry: text)
        
        // 調整文字大小和位置（縮小以適應 3D 空間）
        let scale: Float = 0.01
        textNode.scale = SCNVector3(scale, scale, scale)
        
        // 將文字中心對齊
        let min = text.boundingBox.min
        let max = text.boundingBox.max
        let dx = min.x + (max.x - min.x) / 2
        let dy = min.y + (max.y - min.y) / 2
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)
        
        // 建立容器節點
        let containerNode = SCNNode()
        containerNode.position = position
        containerNode.addChildNode(textNode)
        
        // 添加 billboard constraint 讓標籤始終面向相機
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = [.X, .Y, .Z]
        containerNode.constraints = [billboardConstraint]
        
        // 添加半透明背景（可選，提高可讀性）
        addBackgroundToLabel(textNode: textNode, text: text)
        
        return containerNode
    }
    
    /// 為文字標籤添加半透明背景
    private func addBackgroundToLabel(textNode: SCNNode, text: SCNText) {
        let min = text.boundingBox.min
        let max = text.boundingBox.max
        
        // 計算背景尺寸（稍微大於文字）
        let width = CGFloat(max.x - min.x) * 1.2
        let height = CGFloat(max.y - min.y) * 1.4
        
        // 建立背景平面
        let background = SCNPlane(width: width, height: height)
        background.cornerRadius = height * 0.2
        background.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.6)
        background.firstMaterial?.lightingModel = .constant
        
        // 建立背景節點
        let backgroundNode = SCNNode(geometry: background)
        backgroundNode.position = SCNVector3(
            (min.x + max.x) / 2,
            (min.y + max.y) / 2,
            -0.01  // 稍微往後放，避免 z-fighting
        )
        
        // 添加到文字節點
        textNode.addChildNode(backgroundNode)
    }
}

// MARK: - Clear Functionality

extension MeasurementRenderer {
    /// 清除所有測量視覺元素
    func clearAllVisuals() {
        // 移除測量線
        lineNode?.removeFromParentNode()
        lineNode = nil
        
        // 移除起點標記
        startMarkerNode?.removeFromParentNode()
        startMarkerNode = nil
        
        // 移除終點標記
        endMarkerNode?.removeFromParentNode()
        endMarkerNode = nil
        
        // 移除距離標籤
        distanceLabelNode?.removeFromParentNode()
        distanceLabelNode = nil
        
        // 清除起點位置
        startPosition = nil
    }
    
    /// 清除測量線和距離標籤（保留標記點）
    func clearLineAndLabel() {
        lineNode?.removeFromParentNode()
        lineNode = nil
        
        distanceLabelNode?.removeFromParentNode()
        distanceLabelNode = nil
    }
    
    /// 清除所有標記點
    func clearMarkers() {
        startMarkerNode?.removeFromParentNode()
        startMarkerNode = nil
        
        endMarkerNode?.removeFromParentNode()
        endMarkerNode = nil
        
        startPosition = nil
    }
}

// MARK: - Plane Visualization

extension MeasurementRenderer {
    /// 視覺化平面
    /// 創建半透明網格節點並添加到場景中
    /// - Parameter anchor: 要視覺化的 ARPlaneAnchor
    /// 需求: 2.1, 2.2, 2.3
    func visualizePlane(_ anchor: ARPlaneAnchor) {
        guard let sceneView = sceneView else { return }
        
        // 如果已存在該平面的視覺化，先移除
        if let existingNode = planeNodes[anchor.identifier] {
            existingNode.removeFromParentNode()
        }
        
        // 創建平面幾何體，大小匹配 anchor.extent
        let width = CGFloat(anchor.extent.x)
        let height = CGFloat(anchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 根據平面類型設定顏色
        let color = colorForPlane(anchor)
        plane.firstMaterial?.diffuse.contents = color
        plane.firstMaterial?.lightingModel = .constant
        plane.firstMaterial?.isDoubleSided = true
        
        // 創建平面節點
        let planeNode = SCNNode(geometry: plane)
        
        // 設定平面位置和旋轉
        // ARPlaneAnchor 的 transform 已包含位置和旋轉信息
        planeNode.simdTransform = anchor.transform
        
        // 水平平面需要旋轉 90 度，因為 SCNPlane 默認是垂直的
        if anchor.alignment == .horizontal {
            planeNode.eulerAngles.x = -.pi / 2
        }
        
        // 添加到場景
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        // 儲存節點引用
        planeNodes[anchor.identifier] = planeNode
    }
    
    /// 更新平面視覺化
    /// 根據 anchor.extent 更新節點大小和位置
    /// - Parameter anchor: 更新的 ARPlaneAnchor
    /// 需求: 2.4
    func updatePlaneVisualization(_ anchor: ARPlaneAnchor) {
        guard let planeNode = planeNodes[anchor.identifier],
              let planeGeometry = planeNode.geometry as? SCNPlane else {
            // 如果節點不存在，創建新的視覺化
            visualizePlane(anchor)
            return
        }
        
        // 更新平面幾何體大小
        let width = CGFloat(anchor.extent.x)
        let height = CGFloat(anchor.extent.z)
        planeGeometry.width = width
        planeGeometry.height = height
        
        // 更新平面位置和旋轉
        planeNode.simdTransform = anchor.transform
        
        // 水平平面需要旋轉 90 度
        if anchor.alignment == .horizontal {
            planeNode.eulerAngles.x = -.pi / 2
        }
    }
    
    /// 移除平面視覺化
    /// 包含 2 秒淡出動畫
    /// - Parameter anchor: 要移除的 ARPlaneAnchor
    /// 需求: 2.5
    func removePlaneVisualization(_ anchor: ARPlaneAnchor) {
        guard let planeNode = planeNodes[anchor.identifier] else {
            return
        }
        
        // 創建淡出動畫（2 秒）
        let fadeOut = SCNAction.fadeOut(duration: 2.0)
        let remove = SCNAction.removeFromParentNode()
        let sequence = SCNAction.sequence([fadeOut, remove])
        
        // 執行動畫
        planeNode.runAction(sequence)
        
        // 從字典中移除引用
        planeNodes.removeValue(forKey: anchor.identifier)
    }
    
    /// 設定特定平面的顏色
    /// 用於追蹤品質視覺回饋
    /// - Parameters:
    ///   - color: 要設定的顏色
    ///   - anchor: 目標 ARPlaneAnchor
    /// 需求: 5.5
    func setPlaneColor(_ color: UIColor, for anchor: ARPlaneAnchor) {
        guard let planeNode = planeNodes[anchor.identifier],
              let material = planeNode.geometry?.firstMaterial else {
            return
        }
        
        material.diffuse.contents = color
    }
    
    /// 設定所有平面的顏色
    /// 用於追蹤品質不佳時將所有平面變為黃色
    /// - Parameter color: 要設定的顏色
    /// 需求: 5.5
    func setAllPlanesColor(_ color: UIColor) {
        for (_, planeNode) in planeNodes {
            if let material = planeNode.geometry?.firstMaterial {
                material.diffuse.contents = color
            }
        }
    }
    
    /// 根據平面類型返回對應的顏色
    /// - Parameter anchor: ARPlaneAnchor
    /// - Returns: 水平平面返回藍色，垂直平面返回綠色，透明度 0.3
    /// 需求: 2.2, 2.3
    private func colorForPlane(_ anchor: ARPlaneAnchor) -> UIColor {
        switch anchor.alignment {
        case .horizontal:
            // 藍色 (RGB: 0.2, 0.5, 1.0)，透明度 0.3
            return UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3)
        case .vertical:
            // 綠色 (RGB: 0.2, 1.0, 0.5)，透明度 0.3
            return UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.3)
        @unknown default:
            // 預設使用藍色
            return UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3)
        }
    }
}
