# 實作計畫

- [x] 1. 建立專案結構與核心介面

  - 建立 `ManualMeasurement` 目錄結構（ViewControllers, Managers, Models, Renderers）
  - 定義 `MeasurementState` 枚舉與相關資料模型
  - 建立 `MeasurementPoint` 和 `MeasurementResult` 結構
  - _需求：1, 2, 3, 4, 5_

- [-] 2. 實作 AR 管理器

  - [x] 2.1 建立 `ManualARManager` 類別
    - 實作 AR Session 初始化與配置（啟用水平和垂直平面檢測）
    - 實作 `performHitTest(at:)` 方法，優先順序為 existingPlaneUsingExtent > featurePoint
    - 實作 `worldPosition(from:)` 座標轉換方法
    - 實作 Session 啟動與暫停方法
    - _需求：2.1, 2.2, 3.1, 4.1_

- [x] 3. 實作測量狀態管理器

  - [x] 3.1 建立 `MeasurementStateManager` 類別
    - 實作狀態枚舉（initial, startPointRecorded, measurementComplete）
    - 實作 `recordStartPoint(_:)` 方法記錄起點
    - 實作 `recordEndPoint(_:)` 方法記錄終點
    - 實作 `calculateDistance(from:to:)` 使用歐幾里得距離公式
    - 實作 `reset()` 方法清除測量狀態
    - _需求：2.2, 2.5, 4.2, 4.4, 5.3_

- [x] 4. 實作測量渲染器

  - [x] 4.1 建立 `MeasurementRenderer` 類別基礎結構

    - 初始化 SCNView 引用和節點屬性
    - _需求：1, 2, 3, 4_

  - [x] 4.2 實作中心游標渲染

    - 實作 `showCenterReticle(on:)` 方法
    - 建立白色圓形 UIView（直徑 10 像素，透明度 0.8）
    - 固定游標在螢幕中心位置
    - _需求：1.1, 1.2, 1.3, 1.4_

  - [x] 4.3 實作測量點標記渲染

    - 實作 `addMarker(at:color:)` 方法
    - 建立黃色球體 SCNNode（半徑 0.01 米）
    - 將標記節點添加到場景中
    - _需求：2.3, 4.3_

  - [x] 4.4 實作測量線渲染

    - 實作 `drawLine(from:to:color:)` 方法建立黃色圓柱體連接兩點
    - 實作 `updateLine(to:)` 方法更新線條端點（用於即時預覽）
    - 優化：更新現有節點而非重建
    - _需求：3.2, 3.3, 3.5_

  - [x] 4.5 實作距離顯示

    - 實作 `showDistance(_:at:)` 方法在 3D 空間顯示距離標籤
    - 實作 `updateDistanceLabel(_:)` 方法更新距離數值
    - 格式化距離為公分，保留一位小數
    - 使用 billboard constraint 讓標籤面向相機
    - _需求：3.4, 4.6_

  - [x] 4.6 實作清除功能
    - 實作 `clearAllVisuals()` 方法移除所有測量節點和標記
    - _需求：5.2_

- [x] 5. 實作主視圖控制器

  - [x] 5.1 建立 `ManualMeasurementViewController` 基礎結構

    - 設置 ARSCNView
    - 建立測量按鈕 UI
    - 初始化 ARManager、StateManager 和 Renderer
    - _需求：1, 2, 3, 4, 5_

  - [x] 5.2 實作 AR Session 設置

    - 實作 `setupARSession()` 方法
    - 配置 ARWorldTrackingConfiguration
    - 啟動 AR Session
    - 顯示中心游標
    - _需求：1.1_

  - [x] 5.3 實作測量按鈕點擊處理

    - 實作 `onMeasureButtonTapped()` 方法
    - 根據當前狀態執行不同邏輯：
      - Initial 狀態：執行 hit test 並記錄起點
      - StartPointRecorded 狀態：執行 hit test 並記錄終點
      - MeasurementComplete 狀態：清除並重置
    - 處理 hit test 失敗情況（顯示提示訊息）
    - _需求：2.1, 2.4, 4.1, 5.2_

  - [x] 5.4 實作即時預覽更新
    - 實作 `updateRealtimePreview()` 方法
    - 在 ARSCNViewDelegate 的 `renderer(_:updateAtTime:)` 中調用
    - 當處於 StartPointRecorded 狀態時，每幀執行 hit test
    - 更新測量線和距離顯示
    - 實作節流機制限制為 30 FPS
    - _需求：3.1, 3.2, 3.4, 3.5_

- [x] 6. 實作錯誤處理

  - [x] 6.1 定義錯誤類型

    - 建立 `ManualMeasurementError` 枚舉
    - 定義錯誤類型：arSessionFailed, hitTestFailed, invalidMeasurementPoint, insufficientTracking
    - _需求：2.4_

  - [x] 6.2 實作錯誤處理邏輯
    - 處理 AR Session 失敗（顯示錯誤訊息和重試按鈕）
    - 處理 Hit Test 失敗（顯示提示並保持當前狀態）
    - 監控追蹤品質並顯示警告
    - 驗證測量點有效性（距離範圍檢查）
    - _需求：2.4_

- [-] 7. 整合與測試

  - [x] 7.1 整合所有組件

    - 確保 ViewController 正確協調各組件
    - 驗證狀態轉換流程
    - 測試完整的測量流程（起點 → 即時預覽 → 終點 → 重置）
    - _需求：1, 2, 3, 4, 5_

  - [x] 7.2 效能測試與優化

    - 監控即時預覽幀率（目標 30+ FPS）
    - 檢查記憶體使用（避免節點洩漏）
    - 驗證長時間運行穩定性
    - _需求：3.5_

  - [x] 7.3 準確性驗證
    - 使用實體尺規測量已知距離
    - 比對應用程式測量結果
    - 驗證誤差在 ± 2% 範圍內
    - _需求：4.4_
