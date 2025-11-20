//
//  MeasurementRenderer.swift
//  CameraMeasurementApp
//
//  負責所有測量視覺元素的渲染
//

import UIKit
import SceneKit
import ARKit

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
