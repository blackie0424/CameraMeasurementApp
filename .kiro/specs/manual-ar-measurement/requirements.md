# 需求文件

## 簡介

本功能實現類似 Apple 測距儀的手動 AR 測量功能，允許使用者在相機畫面中透過放置測量點來測量真實世界物體的距離。使用者可以看到一個中心白點作為測量游標，透過按鈕操作來記錄起點和終點，系統會即時繪製測量線條並計算距離。

## 術語表

- **MeasurementApp**：相機測量應用程式系統
- **AR Session**：ARKit 提供的擴增實境會話
- **Measurement Point**：使用者在 3D 空間中標記的測量點
- **Center Reticle**：畫面中心的白色圓點游標
- **Measurement Line**：連接兩個測量點的視覺化線條
- **World Tracking**：ARKit 的世界追蹤功能
- **Hit Test**：從螢幕座標到 3D 世界座標的射線檢測

## 需求

### 需求 1

**使用者故事：** 作為使用者，我想要在相機畫面中心看到一個白色圓點游標，以便我知道當前測量點會放置在哪裡

#### 驗收標準

1. WHEN AR Session 啟動，THE MeasurementApp SHALL 在畫面中心顯示一個白色圓形游標
2. THE MeasurementApp SHALL 保持 Center Reticle 固定在螢幕中心位置，不受相機移動影響
3. THE MeasurementApp SHALL 將 Center Reticle 渲染為半透明白色圓點，直徑為 8-12 像素
4. WHILE AR Session 運行中，THE MeasurementApp SHALL 持續顯示 Center Reticle

### 需求 2

**使用者故事：** 作為使用者，我想要按下按鈕來記錄測量起點，以便開始測量物體

#### 驗收標準

1. WHEN 使用者點擊測量按鈕且尚未記錄起點，THE MeasurementApp SHALL 執行 Hit Test 從 Center Reticle 位置到 3D 空間
2. IF Hit Test 成功偵測到平面或特徵點，THEN THE MeasurementApp SHALL 在該 3D 位置建立 Measurement Point 作為起點
3. WHEN 起點建立成功，THE MeasurementApp SHALL 在該位置顯示視覺標記（黃色圓點）
4. IF Hit Test 未偵測到有效表面，THEN THE MeasurementApp SHALL 顯示提示訊息要求使用者移動裝置
5. THE MeasurementApp SHALL 儲存起點的 3D 世界座標供後續計算使用

### 需求 3

**使用者故事：** 作為使用者，我想要在記錄起點後移動手機時看到即時繪製的測量線，以便我可以調整測量終點位置

#### 驗收標準

1. WHILE 起點已記錄且終點尚未確認，THE MeasurementApp SHALL 每幀執行 Hit Test 從 Center Reticle 到 3D 空間
2. WHEN Hit Test 偵測到有效位置，THE MeasurementApp SHALL 繪製從起點到當前位置的直線
3. THE MeasurementApp SHALL 將測量線渲染為黃色實線，線寬為 2-3 像素
4. THE MeasurementApp SHALL 在測量線旁即時顯示當前距離數值，單位為公分
5. WHILE 使用者移動裝置，THE MeasurementApp SHALL 以至少 30 FPS 更新測量線和距離顯示

### 需求 4

**使用者故事：** 作為使用者，我想要再次按下按鈕來確認測量終點，以便完成距離測量

#### 驗收標準

1. WHEN 使用者點擊測量按鈕且起點已記錄，THE MeasurementApp SHALL 執行 Hit Test 從 Center Reticle 位置確定終點
2. IF Hit Test 成功，THEN THE MeasurementApp SHALL 在該位置建立 Measurement Point 作為終點
3. WHEN 終點建立成功，THE MeasurementApp SHALL 在該位置顯示視覺標記（黃色圓點）
4. THE MeasurementApp SHALL 計算起點與終點之間的歐幾里得距離
5. THE MeasurementApp SHALL 將測量線從臨時狀態轉為確認狀態（保持顯示但停止更新）
6. THE MeasurementApp SHALL 在測量線旁顯示最終測量距離，精確到小數點後一位

### 需求 5

**使用者故事：** 作為使用者，我想要在完成一次測量後能夠開始新的測量，以便測量不同的距離

#### 驗收標準

1. WHEN 一次測量完成（起點和終點都已確認），THE MeasurementApp SHALL 顯示最終測量結果
2. WHEN 使用者再次點擊測量按鈕，THE MeasurementApp SHALL 清除前一次的測量線和標記
3. WHEN 開始新測量，THE MeasurementApp SHALL 重置測量狀態並等待新的起點記錄
4. THE MeasurementApp SHALL 一次只顯示一條測量線
