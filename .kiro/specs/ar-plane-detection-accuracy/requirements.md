# 需求文件

## 簡介

本功能改進現有的 AR 測量系統，加入類似 Apple 測距儀的完整平面偵測流程。目前系統存在兩個主要問題：(1) 測量線條在相機角度改變時會飄移到不正確的位置，(2) 測量數據嚴重不準確（例如實際 20 公分的物體只顯示 5 公分）。這些問題源於系統缺少穩定的空間參考平面建立流程。本功能將實作完整的平面偵測與視覺化，確保使用者在開始測量前已建立可靠的空間錨點。

## 術語表

- **MeasurementApp**：相機測量應用程式系統
- **AR Session**：ARKit 提供的擴增實境會話
- **Plane Detection**：ARKit 偵測真實世界平面（水平或垂直表面）的過程
- **Plane Anchor**：ARKit 偵測到的平面錨點，代表真實世界中的穩定表面
- **Plane Visualization**：平面的視覺化呈現，通常為半透明網格或輪廓
- **Tracking Quality**：AR 追蹤品質，影響測量準確度
- **World Origin**：AR 世界座標系統的原點
- **Feature Points**：ARKit 偵測到的環境特徵點，用於追蹤和平面檢測

## 需求

### 需求 1

**使用者故事：** 作為使用者，我想要在開始測量前看到系統正在偵測平面，以便我知道何時可以開始進行準確的測量

#### 驗收標準

1. WHEN AR Session 啟動，THE MeasurementApp SHALL 進入平面偵測模式並顯示偵測狀態提示
2. WHILE 平面偵測進行中，THE MeasurementApp SHALL 顯示「正在偵測平面，請緩慢移動裝置」的指示訊息
3. THE MeasurementApp SHALL 持續掃描環境直到至少偵測到一個有效平面
4. WHEN 偵測到第一個平面，THE MeasurementApp SHALL 更新提示訊息為「已偵測到平面，繼續移動以改善準確度」
5. THE MeasurementApp SHALL 在偵測到足夠平面後（至少 2 個平面或單一平面面積 > 0.5 平方公尺），啟用測量功能

### 需求 2

**使用者故事：** 作為使用者，我想要看到偵測到的平面視覺化呈現，以便我了解系統已識別哪些表面可用於測量

#### 驗收標準

1. WHEN 系統偵測到新平面，THE MeasurementApp SHALL 在該平面位置渲染半透明視覺化網格
2. THE MeasurementApp SHALL 將水平平面渲染為藍色半透明網格，透明度為 0.3
3. THE MeasurementApp SHALL 將垂直平面渲染為綠色半透明網格，透明度為 0.3
4. WHILE 平面持續更新，THE MeasurementApp SHALL 即時調整視覺化網格的大小和形狀以匹配偵測到的平面範圍
5. WHEN 平面不再被追蹤，THE MeasurementApp SHALL 在 2 秒後淡出並移除該平面的視覺化

### 需求 3

**使用者故事：** 作為使用者，我想要測量點只能放置在已偵測的平面上，以便確保測量的準確性

#### 驗收標準

1. WHEN 使用者嘗試放置測量點，THE MeasurementApp SHALL 執行 hit test 優先檢測已偵測的平面
2. IF hit test 命中已偵測的平面，THEN THE MeasurementApp SHALL 在該平面上放置測量點
3. IF hit test 未命中任何已偵測平面，THEN THE MeasurementApp SHALL 拒絕放置測量點並顯示「請將游標對準已偵測的平面」提示
4. THE MeasurementApp SHALL 在游標對準有效平面時，將游標顏色變更為綠色以提供視覺回饋
5. THE MeasurementApp SHALL 在游標未對準有效平面時，將游標顏色變更為紅色以提供視覺回饋

### 需求 4

**使用者故事：** 作為使用者，我想要測量線條錨定在偵測到的平面上，以便在改變相機角度時線條保持在正確的 3D 位置

#### 驗收標準

1. WHEN 測量點被放置，THE MeasurementApp SHALL 將該點錨定到對應的 Plane Anchor 上
2. WHILE 相機角度改變，THE MeasurementApp SHALL 保持測量點和測量線在原始 3D 世界座標位置
3. THE MeasurementApp SHALL 使用 Plane Anchor 的座標系統計算測量點位置，而非僅使用 hit test 結果
4. WHEN 平面更新其範圍或位置，THE MeasurementApp SHALL 相應調整錨定在該平面上的測量點位置
5. THE MeasurementApp SHALL 確保測量線的兩個端點都錨定在穩定的平面上

### 需求 5

**使用者故事：** 作為使用者，我想要系統監控追蹤品質，以便在測量準確度可能受影響時得到警告

#### 驗收標準

1. THE MeasurementApp SHALL 持續監控 ARCamera 的 trackingState
2. WHEN trackingState 為 limited 或 notAvailable，THE MeasurementApp SHALL 顯示警告訊息「追蹤品質不佳，請改善光線或移動到特徵豐富的環境」
3. WHILE trackingState 為 limited 或 notAvailable，THE MeasurementApp SHALL 禁用測量點放置功能
4. WHEN trackingState 恢復為 normal，THE MeasurementApp SHALL 隱藏警告訊息並重新啟用測量功能
5. THE MeasurementApp SHALL 在追蹤品質不佳時，將所有平面視覺化變更為黃色以提供額外視覺警告

### 需求 6

**使用者故事：** 作為使用者，我想要測量距離使用平面上的實際 3D 距離計算，以便獲得準確的測量結果

#### 驗收標準

1. WHEN 計算兩個測量點之間的距離，THE MeasurementApp SHALL 使用兩點在 AR 世界座標系統中的 3D 位置
2. THE MeasurementApp SHALL 使用歐幾里得距離公式計算：sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)
3. THE MeasurementApp SHALL 考慮平面的實際方向和位置，而非僅使用螢幕空間投影
4. WHEN 測量點位於不同平面上，THE MeasurementApp SHALL 計算跨平面的真實 3D 距離
5. THE MeasurementApp SHALL 將距離結果精確到毫米級別（顯示到小數點後一位公分）

### 需求 7

**使用者故事：** 作為使用者，我想要在測量前確認平面偵測已充分完成，以便確保測量的可靠性

#### 驗收標準

1. THE MeasurementApp SHALL 在平面偵測階段禁用測量按鈕，並顯示「偵測中...」狀態
2. WHEN 偵測到的平面總面積達到 0.5 平方公尺或偵測到至少 2 個不同平面，THE MeasurementApp SHALL 啟用測量按鈕
3. THE MeasurementApp SHALL 在測量按鈕旁顯示偵測進度指示器（例如「已偵測 X 個平面」）
4. WHEN 使用者點擊「開始測量」按鈕，THE MeasurementApp SHALL 固定當前偵測到的平面並停止新平面的視覺化
5. THE MeasurementApp SHALL 提供「重新偵測平面」選項，允許使用者在測量過程中重新掃描環境
