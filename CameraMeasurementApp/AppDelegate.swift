//
//  AppDelegate.swift
//  CameraMeasurementApp
//
//  Created by 吳崇岳 on 2025/10/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 初始化 Core Data
        _ = CoreDataStack.shared.persistentContainer
        
        // 驗證資料模型
        if CoreDataStack.shared.validateDataModel() {
            print("✅ Core Data 資料模型驗證成功")
        } else {
            print("❌ Core Data 資料模型驗證失敗")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Core Data Support
    
    func applicationWillTerminate(_ application: UIApplication) {
        // 在應用程式終止前儲存 Core Data 變更
        CoreDataStack.shared.saveContext()
    }


}

