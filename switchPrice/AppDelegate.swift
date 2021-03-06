//
//  AppDelegate.swift
//  switchPrice
//
//  Created by YuKai on 2019/3/21.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        let serialQueue: DispatchQueue = DispatchQueue(label: "serialQueue")
        serialQueue.async {
            //創建資料庫
            if DBManager.shared.createDatabase(){
                //彙整US_GAME讀取資料到存入資料庫
                if !DBManager.shared.isGameUSDatabase(){
                    DBManager.shared.loadGameUS()
                }
                
                //彙整EU_GAME讀取資料到存入資料庫
                if !DBManager.shared.isGameEUDatabase(){
                    DBManager.shared.createEUGameToDatabase()
                }
                //彙整JP_GAME讀取資料到存入資料庫
                if !DBManager.shared.isGameJPDatabase(){
                    DBManager.shared.createJPGameToDatabase()
                    
                }
                
            }else{
                //彙整US_GAME讀取資料到存入資料庫
                if !DBManager.shared.isGameUSDatabase(){
                    DBManager.shared.loadGameUS()
                }else{
                    DBManager.shared.isFinishUS = true
                    NotificationCenter.default.post(name: Notification.Name("GET_DATA"), object: nil)
                }
                
                //彙整EU_GAME讀取資料到存入資料庫
                if !DBManager.shared.isGameEUDatabase(){
                    DBManager.shared.createEUGameToDatabase()
                }else{
                    DBManager.shared.isFinishEU = true
                    NotificationCenter.default.post(name: Notification.Name("GET_DATA"), object: nil)
                }
                
                //彙整JP_GAME讀取資料到存入資料庫
                if !DBManager.shared.isGameJPDatabase(){
                    DBManager.shared.createJPGameToDatabase()
                }else{
                    DBManager.shared.isFinishJP = true
                    NotificationCenter.default.post(name: Notification.Name("GET_DATA"), object: nil)
                }
                
                print("DB is created.")
            }
        }
        
        
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

