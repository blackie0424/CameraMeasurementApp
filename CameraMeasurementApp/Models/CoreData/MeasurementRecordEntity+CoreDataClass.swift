//
//  MeasurementRecordEntity+CoreDataClass.swift
//  CameraMeasurementApp
//
//  Created by Core Data Generator
//

import Foundation
import CoreData
import UIKit
import CoreLocation

@objc(MeasurementRecordEntity)
public class MeasurementRecordEntity: NSManagedObject {
    
    /// 將 UIImage 轉換為 Data 並儲存
    func setImage(_ image: UIImage?) {
        guard let image = image else {
            imageData = nil
            return
        }
        imageData = image.jpegData(compressionQuality: 0.8)
    }
    
    /// 從 Data 轉換回 UIImage
    func getImage() -> UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    /// 設定位置資訊
    func setLocation(_ location: CLLocation?) {
        guard let location = location else {
            latitude = 0
            longitude = 0
            return
        }
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }
    
    /// 取得位置資訊
    func getLocation() -> CLLocation? {
        if latitude == 0 && longitude == 0 {
            return nil
        }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}
