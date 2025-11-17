//
//  ReferenceObject.swift
//  CameraMeasurementApp
//
//  Created by Camera Measurement System
//

import Foundation

struct ReferenceObject {
    let name: String
    let standardDimensions: ObjectDimensions
    let modelFileName: String
    let category: ObjectCategory
    let isCommonlyUsed: Bool
    
    init(name: String, 
         standardDimensions: ObjectDimensions, 
         modelFileName: String, 
         category: ObjectCategory, 
         isCommonlyUsed: Bool = true) {
        self.name = name
        self.standardDimensions = standardDimensions
        self.modelFileName = modelFileName
        self.category = category
        self.isCommonlyUsed = isCommonlyUsed
    }
}

extension ReferenceObject {
    // Predefined reference objects
    static let lighter = ReferenceObject(
        name: "打火機",
        standardDimensions: ObjectDimensions(length: 7.5, width: 2.5, height: 1.2, accuracy: 0.95),
        modelFileName: "lighter.scn",
        category: .everyday
    )
    
    static let coin = ReferenceObject(
        name: "硬幣",
        standardDimensions: ObjectDimensions(length: 2.4, width: 2.4, height: 0.2, accuracy: 0.98),
        modelFileName: "coin.scn",
        category: .currency
    )
    
    static let creditCard = ReferenceObject(
        name: "信用卡",
        standardDimensions: ObjectDimensions(length: 8.5, width: 5.4, height: 0.08, accuracy: 0.99),
        modelFileName: "credit_card.scn",
        category: .everyday
    )
    
    static let iPhone = ReferenceObject(
        name: "iPhone",
        standardDimensions: ObjectDimensions(length: 14.7, width: 7.1, height: 0.8, accuracy: 0.95),
        modelFileName: "iphone.scn",
        category: .electronics
    )
    
    static let pen = ReferenceObject(
        name: "原子筆",
        standardDimensions: ObjectDimensions(length: 14.0, width: 1.0, height: 1.0, accuracy: 0.90),
        modelFileName: "pen.scn",
        category: .stationery
    )
    
    // Default reference objects collection
    static let defaultObjects: [ReferenceObject] = [
        .lighter, .coin, .creditCard, .iPhone, .pen
    ]
}