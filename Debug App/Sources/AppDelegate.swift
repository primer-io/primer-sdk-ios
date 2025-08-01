//
//  AppDelegate.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        customizeAppearance()
        PrimerLogging.shared.logger = DefaultLogger(logLevel: .debug)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        #if DEBUG
        TestHelper.handle(url: url)
        #endif
        return Primer.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            let handled = SDKDemoUrlHandler.handleUrl(url)
            if handled == true {
                return handled
            }
        }
        return Primer.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    private func customizeAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance().tintColor = .black
        UINavigationBar.appearance().tintColor = .white

        if #available(iOS 15.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithDefaultBackground()
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        }
    }
}
