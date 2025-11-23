#!/bin/bash

# YOLOv5 Core ML 模型下載腳本
# 使用方法：bash download_yolov5_model.sh

echo "======================================"
echo "YOLOv5 Core ML 模型下載器"
echo "======================================"

# 檢查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安裝"
    exit 1
fi

echo "✅ Python3 已安裝"

# 檢查並安裝 pip 套件
echo ""
echo "🔍 檢查依賴..."

if ! python3 -c "import ultralytics" 2>/dev/null; then
    echo "📦 安裝 ultralytics..."
    pip3 install ultralytics
fi

# 選擇模型大小
echo ""
echo "📊 選擇模型大小："
echo "  1) Nano   (~4 MB)  - 最快，適合實時檢測"
echo "  2) Small  (~14 MB) - 推薦，平衡效能和準確度"
echo "  3) Medium (~40 MB) - 更準確，稍慢"
echo ""
read -p "請選擇 (預設 1): " choice

case $choice in
    2)
        MODEL="yolov5s"
        ;;
    3)
        MODEL="yolov5m"
        ;;
    *)
        MODEL="yolov5n"
        ;;
esac

echo ""
echo "📥 下載並轉換 $MODEL 模型..."

# 使用 Python 下載和轉換
python3 << EOF
from ultralytics import YOLO
import os

try:
    print("正在載入模型...")
    model = YOLO('${MODEL}.pt')
    
    print("正在轉換為 Core ML 格式...")
    model.export(format='coreml', nms=True, imgsz=640)
    
    # 重命名
    if os.path.exists('${MODEL}.mlmodel'):
        if os.path.exists('YOLOv5.mlmodel'):
            os.remove('YOLOv5.mlmodel')
        os.rename('${MODEL}.mlmodel', 'YOLOv5.mlmodel')
        print("\n✅ 轉換成功！")
        print(f"📁 檔案：{os.path.abspath('YOLOv5.mlmodel')}")
    else:
        print("❌ 轉換失敗")
        exit(1)
        
except Exception as e:
    print(f"❌ 錯誤：{e}")
    exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 完成！"
    echo ""
    echo "📋 下一步："
    echo "1. 在 Xcode 中右鍵點擊 CameraMeasurementApp 資料夾"
    echo "2. 選擇 'Add Files to CameraMeasurementApp...'"
    echo "3. 選擇 YOLOv5.mlmodel 檔案"
    echo "4. 確保勾選 'Copy items if needed' 和 'Add to targets'"
    echo "5. 重新編譯並運行"
else
    echo "❌ 下載失敗"
    exit 1
fi
