# 實作計畫

- [x] 1. 移除 ARKit 除錯選項

  - 開啟 `CameraMeasurementApp/ManualMeasurement/ViewControllers/ManualMeasurementViewController.swift`
  - 在 `setupARView()` 方法中找到並移除以下程式碼區塊：
    ```swift
    // Enable debug options in development
    #if DEBUG
    arView.debugOptions = [.showFeaturePoints]
    #endif
    ```
  - 添加註解說明為何移除此選項
  - _需求：1.1, 1.5, 2.2_

- [ ] 2. 驗證視覺元素完整性

  - 在實體裝置上啟動應用程式
  - 進入手動測量模式
  - 確認中心白色游標正常顯示
  - 確認沒有動態黃色特徵點出現
  - 執行完整測量流程，確認測量點標記、測量線和距離標籤正常顯示
  - _需求：1.1, 1.2, 1.3, 1.4_

- [ ] 3. 測試不同環境場景
  - 在特徵豐富的環境測試（桌面、書架等）
  - 在特徵稀少的環境測試（白牆、空曠空間）
  - 在不同光線條件下測試（明亮、昏暗）
  - 確認所有場景下都沒有特徵點顯示
  - 確認測量功能在所有場景下正常運作
  - _需求：1.1, 1.2, 1.3, 1.4_
