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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let nc = UINavigationController()
        nc.navigationBar.barTintColor = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
        nc.navigationBar.tintColor = .white
        nc.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        let vc = ViewController()
        nc.viewControllers = [vc]
        window?.rootViewController = nc
        window?.makeKeyAndVisible()
        return true
    }

}
