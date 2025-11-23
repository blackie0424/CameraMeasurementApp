#!/usr/bin/env python3
"""
YOLOv5 Core ML 模型下載和轉換腳本
使用方法：python3 download_yolov5_model.py
"""

import os
import sys

def check_dependencies():
    """檢查必要的依賴"""
    try:
        import torch
        print("✅ PyTorch 已安裝")
    except ImportError:
        print("❌ PyTorch 未安裝")
        print("安裝指令：pip install torch torchvision")
        return False
    
    try:
        import ultralytics
        print("✅ Ultralytics 已安裝")
    except ImportError:
        print("❌ Ultralytics 未安裝")
        print("安裝指令：pip install ultralytics")
        return False
    
    return True

def download_and_convert_model(model_size='n'):
    """
    下載並轉換 YOLOv5 模型到 Core ML 格式
    
    Args:
        model_size: 模型大小 ('n', 's', 'm', 'l', 'x')
                   n = nano (最小，~4MB)
                   s = small (小，~14MB)
                   m = medium (中，~40MB)
                   l = large (大，~90MB)
                   x = xlarge (超大，~170MB)
    """
    from ultralytics import YOLO
    
    model_name = f'yolov5{model_size}'
    print(f"\n📥 正在下載 {model_name} 模型...")
    
    try:
        # 載入模型（會自動下載）
        model = YOLO(f'{model_name}.pt')
        print(f"✅ {model_name} 模型下載成功")
        
        # 轉換為 Core ML 格式
        print(f"\n🔄 正在轉換為 Core ML 格式...")
        model.export(format='coreml', nms=True, imgsz=640)
        
        # 重命名檔案
        original_name = f'{model_name}.mlmodel'
        target_name = 'YOLOv5.mlmodel'
        
        if os.path.exists(original_name):
            if os.path.exists(target_name):
                os.remove(target_name)
            os.rename(original_name, target_name)
            print(f"\n✅ 模型轉換成功！")
            print(f"📁 檔案位置：{os.path.abspath(target_name)}")
            print(f"\n📋 下一步：")
            print(f"1. 在 Xcode 中右鍵點擊 CameraMeasurementApp 資料夾")
            print(f"2. 選擇 'Add Files to CameraMeasurementApp...'")
            print(f"3. 選擇 {target_name} 檔案")
            print(f"4. 確保勾選 'Copy items if needed' 和 'Add to targets'")
            print(f"5. 重新編譯並運行")
            return True
        else:
            print(f"❌ 找不到轉換後的模型檔案")
            return False
            
    except Exception as e:
        print(f"❌ 錯誤：{e}")
        return False

def main():
    print("=" * 60)
    print("YOLOv5 Core ML 模型下載器")
    print("=" * 60)
    
    # 檢查依賴
    print("\n🔍 檢查依賴...")
    if not check_dependencies():
        print("\n❌ 請先安裝必要的依賴：")
        print("pip install torch torchvision ultralytics")
        sys.exit(1)
    
    # 選擇模型大小
    print("\n📊 選擇模型大小：")
    print("  n - Nano   (~4 MB)  - 最快，適合實時檢測")
    print("  s - Small  (~14 MB) - 推薦，平衡效能和準確度")
    print("  m - Medium (~40 MB) - 更準確，稍慢")
    print("  l - Large  (~90 MB) - 很準確，較慢")
    
    model_size = input("\n請選擇 (預設 n): ").strip().lower() or 'n'
    
    if model_size not in ['n', 's', 'm', 'l', 'x']:
        print("❌ 無效的選擇，使用預設值 'n'")
        model_size = 'n'
    
    # 下載和轉換
    success = download_and_convert_model(model_size)
    
    if success:
        print("\n✅ 完成！")
    else:
        print("\n❌ 轉換失敗")
        sys.exit(1)

if __name__ == "__main__":
    main()
