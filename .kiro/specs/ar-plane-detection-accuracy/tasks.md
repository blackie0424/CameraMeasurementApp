# 實作計畫

- [x] 1. 建立平面偵測基礎架構

  - 建立 `PlaneDetection` 目錄結構（Managers, Models, Renderers）
  - 定義 `PlaneDetectionState` 枚舉和 `PlaneInfo` 資料模型
  - 建立 `AnchoredMeasurementPoint` 結構，包含平面錨點引用和局部座標
  - 實作 `worldPosition()` 方法使用 transform 矩陣計算世界座標
  - _需求：4.1, 4.2, 4.3_

- [x] 2. 實作 PlaneDetectionManager

  - [x] 2.1 建立 PlaneDetectionManager 類別基礎結構

    - 實作平面追蹤（addPlane, updatePlane, removePlane）
    - 實作平面面積計算（使用 extent.x \* extent.z）
    - 實作平面數量統計
    - _需求：1.3, 2.1, 2.4_

  - [x] 2.2 實作測量啟用條件邏輯

    - 實作 `checkReadyCondition()` 方法
    - 檢查條件：平面數量 ≥ 2 或總面積 ≥ 0.5 平方公尺
    - 實作狀態轉換（detecting → ready → measurementMode）
    - _需求：1.5, 7.2_

  - [x] 2.3 撰寫 property test 驗證啟用條件
    - **Property 1: 平面偵測啟用條件**
    - **Validates: Requirements 1.5, 7.2**
    - 生成隨機平面集合，驗證啟用邏輯正確性

- [x] 3. 擴展 ARManager 支援平面錨點

  - [x] 3.1 實作平面優先的 hit test

    - 實作 `performHitTestOnPlanes(at:)` 方法
    - 只使用 existingPlaneUsingExtent 類型
    - 返回 hit result 和對應的 ARPlaneAnchor
    - _需求：3.1, 3.2_

  - [x] 3.2 實作測量點錨定功能

    - 實作 `createAnchoredPoint(on:at:)` 方法
    - 將世界座標轉換為平面局部座標（使用逆矩陣）
    - 創建 AnchoredMeasurementPoint 實例
    - _需求：4.1, 4.3_

  - [x] 3.3 撰寫 property test 驗證 hit test 優先順序

    - **Property 5: Hit test 優先平面**
    - **Validates: Requirements 3.1**

  - [x] 3.4 撰寫 property test 驗證座標穩定性
    - **Property 10: 相機角度改變時座標穩定性**
    - **Validates: Requirements 4.2**
    - 生成隨機相機角度，驗證測量點世界座標保持不變

- [x] 4. 實作 TrackingQualityMonitor

  - [x] 4.1 建立 TrackingQualityMonitor 類別

    - 定義 TrackingQuality 枚舉（normal, limited, notAvailable）
    - 實作 `updateTrackingState(_:)` 方法監控 ARCamera.trackingState
    - 實作 `isMeasurementAllowed()` 方法判斷是否允許測量
    - 實作 `getWarningMessage()` 方法生成警告訊息
    - _需求：5.1, 5.2, 5.3_

  - [x] 4.2 撰寫 property test 驗證追蹤品質行為
    - **Property 14: 追蹤品質不佳時的行為**
    - **Validates: Requirements 5.2, 5.3**
    - 生成隨機追蹤狀態，驗證警告和功能禁用邏輯

- [x] 5. 實作平面視覺化渲染

  - [x] 5.1 擴展 MeasurementRenderer 支援平面視覺化

    - 實作 `visualizePlane(_:)` 方法創建平面視覺化節點
    - 使用 SCNPlane 幾何體，大小匹配 anchor.extent
    - 實作平面類型到顏色的映射（水平=藍色，垂直=綠色）
    - 設定透明度為 0.3
    - _需求：2.1, 2.2, 2.3_

  - [x] 5.2 實作平面視覺化更新

    - 實作 `updatePlaneVisualization(_:)` 方法
    - 根據 anchor.extent 更新節點大小和位置
    - 實作 `removePlaneVisualization(_:)` 方法，包含 2 秒淡出動畫
    - _需求：2.4, 2.5_

  - [x] 5.3 實作追蹤品質視覺回饋

    - 實作 `setPlaneColor(_:for:)` 方法
    - 追蹤品質不佳時將所有平面變為黃色
    - _需求：5.5_

  - [x] 5.4 撰寫 property test 驗證平面顏色映射

    - **Property 3: 平面類型到顏色映射**
    - **Validates: Requirements 2.2, 2.3**
    - 生成隨機平面類型，驗證顏色正確性

  - [x] 5.5 撰寫 property test 驗證追蹤品質視覺回饋
    - **Property 15: 追蹤品質不佳時平面變黃色**
    - **Validates: Requirements 5.5**

- [x] 6. 實作游標狀態回饋

  - [x] 6.1 擴展游標渲染支援狀態顏色

    - 定義 ReticleState 枚舉（onPlane, offPlane, disabled）
    - 實作 `setReticleState(_:)` 方法
    - 實作 `updateReticleColor(_:)` 方法
    - 對準平面時顯示綠色，未對準時顯示紅色
    - _需求：3.4, 3.5_

  - [x] 6.2 撰寫 property test 驗證游標顏色回饋
    - **Property 8: 游標顏色回饋**
    - **Validates: Requirements 3.4, 3.5**
    - 生成隨機游標狀態，驗證顏色映射

- [x] 7. 實作測量點放置邏輯

  - [x] 7.1 更新測量點放置流程

    - 修改 `onMeasureButtonTapped()` 使用 `performHitTestOnPlanes(at:)`
    - 只在命中平面時放置測量點
    - 未命中平面時顯示提示訊息「請將游標對準已偵測的平面」
    - 使用 `createAnchoredPoint(on:at:)` 創建錨定測量點
    - _需求：3.2, 3.3, 4.1_

  - [x] 7.2 實作即時游標狀態更新

    - 在 `updateRealtimePreview()` 中執行 hit test
    - 根據是否命中平面更新游標顏色
    - _需求：3.4, 3.5_

  - [x] 7.3 撰寫 property test 驗證測量點放置邏輯

    - **Property 6: 平面命中時放置測量點**
    - **Validates: Requirements 3.2**

  - [x] 7.4 撰寫 property test 驗證測量點拒絕邏輯
    - **Property 7: 平面未命中時拒絕測量點**
    - **Validates: Requirements 3.3**

- [ ] 8. 實作距離計算改進

  - [x] 8.1 更新距離計算使用錨定測量點

    - 修改 `calculateDistance(from:to:)` 接受 AnchoredMeasurementPoint
    - 使用 `worldPosition()` 動態獲取當前世界座標
    - 使用歐幾里得距離公式：sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)
    - _需求：6.1, 6.2, 6.3_

  - [x] 8.2 實作距離格式化

    - 轉換為公分單位（\* 100）
    - 格式化為一位小數（例如 "45.3 cm"）
    - _需求：6.5_

  - [x] 8.3 撰寫 property test 驗證 3D 距離計算

    - **Property 16: 3D 距離計算**
    - **Validates: Requirements 6.1, 6.2, 6.3**
    - 生成隨機測量點，驗證距離計算公式正確性（誤差 < 0.1mm）

  - [x] 8.4 撰寫 property test 驗證跨平面距離計算

    - **Property 17: 跨平面距離計算**
    - **Validates: Requirements 6.4**
    - 生成位於不同平面的測量點，驗證距離計算

  - [x] 8.5 撰寫 property test 驗證距離格式化
    - **Property 18: 距離格式化**
    - **Validates: Requirements 6.5**
    - 生成隨機距離值，驗證格式化輸出

- [ ] 9. 實作測量線渲染改進

  - [ ] 9.1 更新測量線渲染使用錨定測量點

    - 修改 `drawLine(from:to:)` 接受 AnchoredMeasurementPoint
    - 使用 `worldPosition()` 獲取端點座標
    - 確保兩個端點都有有效的平面錨點
    - _需求：4.5_

  - [ ] 9.2 撰寫 property test 驗證測量線錨定
    - **Property 13: 測量線兩端都錨定**
    - **Validates: Requirements 4.5**

- [ ] 10. 實作 UI 狀態管理

  - [ ] 10.1 實作平面偵測階段 UI

    - 在偵測階段禁用測量按鈕，顯示「偵測中...」
    - 實作偵測進度指示器，顯示「已偵測 X 個平面」
    - 當滿足啟用條件時啟用測量按鈕
    - _需求：1.1, 1.2, 7.1, 7.3_

  - [ ] 10.2 實作狀態提示訊息

    - 偵測中顯示「正在偵測平面，請緩慢移動裝置」
    - 偵測到第一個平面後顯示「已偵測到平面，繼續移動以改善準確度」
    - 追蹤品質不佳時顯示警告訊息
    - _需求：1.2, 1.4, 5.2_

  - [ ] 10.3 實作測量模式轉換

    - 實作「開始測量」按鈕功能
    - 點擊後固定當前平面，停止新平面視覺化
    - 實作「重新偵測平面」選項
    - _需求：7.4, 7.5_

  - [ ] 10.4 撰寫 property test 驗證偵測進度顯示
    - **Property 19: 偵測進度顯示**
    - **Validates: Requirements 7.3**
    - 生成隨機平面數量，驗證顯示文字正確

- [ ] 11. 整合 ARSessionDelegate

  - [ ] 11.1 實作平面錨點事件處理

    - 實作 `session(_:didAdd:)` 處理新平面
    - 實作 `session(_:didUpdate:)` 處理平面更新
    - 實作 `session(_:didRemove:)` 處理平面移除
    - 連接 PlaneDetectionManager 和 Renderer
    - _需求：2.1, 2.4, 2.5_

  - [ ] 11.2 實作追蹤狀態監控

    - 在 `session(_:cameraDidChangeTrackingState:)` 中更新 TrackingQualityMonitor
    - 根據追蹤品質更新 UI 和平面顏色
    - _需求：5.1, 5.2, 5.5_

  - [ ] 11.3 撰寫 property test 驗證平面更新時測量點跟隨
    - **Property 12: 平面更新時測量點跟隨**
    - **Validates: Requirements 4.4**
    - 模擬平面更新，驗證測量點座標相應調整

- [ ] 12. Checkpoint - 確保所有測試通過

  - 執行所有 property-based tests
  - 執行所有 unit tests
  - 確保編譯無錯誤
  - 如有問題請詢問使用者

- [ ] 13. 手動測試與調整

  - [ ] 13.1 平面偵測流程測試

    - 測試平面偵測和視覺化
    - 驗證啟用條件正確觸發
    - 測試狀態轉換流程
    - _需求：1, 2, 7_

  - [ ] 13.2 測量準確性測試

    - 使用實體尺規驗證測量準確度
    - 測試相機角度改變時線條穩定性
    - 測試跨平面測量
    - 目標誤差 < 2%
    - _需求：4, 6_

  - [ ] 13.3 使用者體驗測試
    - 測試游標顏色回饋
    - 測試追蹤品質警告
    - 測試提示訊息顯示
    - 驗證視覺效果和動畫
    - _需求：3, 5_

- [ ] 14. 效能優化

  - [ ] 14.1 渲染效能優化

    - 限制平面視覺化數量（最多 10 個）
    - 實作更新節流（平面更新 30 FPS，游標 60 FPS）
    - 優化平面幾何體複雜度
    - _需求：2.4_

  - [ ] 14.2 記憶體管理
    - 確保移除的平面視覺化及時釋放
    - 檢查循環引用
    - 測試長時間運行穩定性
    - _需求：2.5_

- [ ] 15. 最終 Checkpoint - 確保所有測試通過
  - 執行完整測試套件
  - 驗證所有需求已實作
  - 確認無已知 bug
  - 如有問題請詢問使用者
