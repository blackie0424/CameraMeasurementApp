# 需求文件

## 簡介

移除手動測量模式中顯示的 ARKit 特徵點（動態黃點），以改善使用者體驗。這些特徵點是開發除錯功能，不應在正式使用時顯示給使用者。

## 術語表

- **MeasurementApp**：相機測量應用程式系統
- **Feature Points**：ARKit 偵測到的環境特徵點，用於追蹤和定位
- **Debug Options**：ARKit 提供的視覺化除錯選項
- **Center Reticle**：畫面中心的白色圓點游標（應保留）

## 需求

### 需求 1

**使用者故事：** 作為使用者，我想要在手動測量模式中只看到必要的視覺元素，以便我可以專注於測量任務而不被干擾

#### 驗收標準

1. WHEN 使用者進入手動測量模式，THE MeasurementApp SHALL 不顯示 ARKit 特徵點
2. THE MeasurementApp SHALL 保持顯示中心白色游標（Center Reticle）
3. THE MeasurementApp SHALL 保持顯示測量點標記（黃色圓點）
4. THE MeasurementApp SHALL 保持顯示測量線和距離標籤
5. THE MeasurementApp SHALL 移除所有 ARKit 除錯視覺化選項

### 需求 2

**使用者故事：** 作為開發者，我想要在需要時能夠啟用除錯視覺化，以便進行問題診斷和開發

#### 驗收標準

1. WHEN 開發者需要除錯，THE MeasurementApp SHALL 提供方式啟用特徵點顯示
2. THE MeasurementApp SHALL 確保除錯選項不會在正式版本中啟用
3. WHERE 除錯模式啟用，THE MeasurementApp SHALL 允許顯示特徵點和其他除錯資訊
