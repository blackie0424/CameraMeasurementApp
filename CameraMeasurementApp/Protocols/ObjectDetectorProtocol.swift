//
//  ObjectDetectorProtocol.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation
import UIKit
import Vision

protocol ObjectDetectorProtocol {
    func detectObjects(in image: UIImage) -> [DetectedObject]
    func classifyObject(_ object: DetectedObject) -> ObjectType
    func getBoundingBox(for object: DetectedObject) -> CGRect
}

// Object types that can be detected
enum ObjectType: String, CaseIterable {
    // Electronics
    case phone = "phone"
    case laptop = "laptop"
    case tablet = "tablet"
    case monitor = "monitor"
    case watch = "watch"
    
    // Everyday items
    case lighter = "lighter"
    case creditCard = "credit_card"
    case book = "book"
    case bottle = "bottle"
    case cup = "cup"
    case box = "box"
    case key = "key"
    
    // Currency
    case coin = "coin"
    case bill = "bill"
    
    // Stationery
    case pen = "pen"
    case pencil = "pencil"
    case notebook = "notebook"
    case ruler = "ruler"
    
    // Furniture
    case chair = "chair"
    case table = "table"
    case desk = "desk"
    
    // Unknown
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .phone: return "手機"
        case .laptop: return "筆記型電腦"
        case .tablet: return "平板電腦"
        case .monitor: return "顯示器"
        case .watch: return "手錶"
        case .lighter: return "打火機"
        case .creditCard: return "信用卡"
        case .book: return "書本"
        case .bottle: return "瓶子"
        case .cup: return "杯子"
        case .box: return "盒子"
        case .key: return "鑰匙"
        case .coin: return "硬幣"
        case .bill: return "紙鈔"
        case .pen: return "原子筆"
        case .pencil: return "鉛筆"
        case .notebook: return "筆記本"
        case .ruler: return "尺"
        case .chair: return "椅子"
        case .table: return "桌子"
        case .desk: return "書桌"
        case .unknown: return "未知物體"
        }
    }
    
    var category: ObjectCategory {
        switch self {
        case .phone, .laptop, .tablet, .monitor, .watch:
            return .electronics
        case .lighter, .creditCard, .book, .bottle, .cup, .box, .key:
            return .everyday
        case .coin, .bill:
            return .currency
        case .pen, .pencil, .notebook, .ruler:
            return .stationery
        case .chair, .table, .desk:
            return .furniture
        case .unknown:
            return .unknown
        }
    }
}