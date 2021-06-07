//
//  AppDelegate.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 03/12/2021.
//  Copyright (c) 2021 Evangelos Pittas. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        customizeAppearance()
        return true
    }
    
    private func customizeAppearance() {
        
        if #available(iOS 13.0, *) {
            UINavigationBar.appearance().barTintColor = .systemBackground
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)]
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
            UINavigationBar.appearance().shadowImage = UIImage()
            UIBarButtonItem.appearance().tintColor = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
        } else {
            UINavigationBar.appearance().barTintColor = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
            UIBarButtonItem.appearance().tintColor = .white
        }
    }

}
