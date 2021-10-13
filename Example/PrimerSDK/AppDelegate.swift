//
//  AppDelegate.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 03/12/2021.
//  Copyright (c) 2021 Evangelos Pittas. All rights reserved.
//

import PrimerSDK
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        customizeAppearance()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return Primer.shared.application(app, open: url, options: options)
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return Primer.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    private func customizeAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance().tintColor = .white
        UINavigationBar.appearance().tintColor = .white
    }

}
