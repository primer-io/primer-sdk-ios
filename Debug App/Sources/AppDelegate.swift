//
//  AppDelegate.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 03/12/2021.
//  Copyright (c) 2021 Evangelos Pittas. All rights reserved.
//

import PrimerSDK
import UIKit
import Primer3DS
import PrimerKlarnaSDK
import PrimerNolPaySDK
import PrimerStripeSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    override init() {
        super.init()
        _ = PrimerSDK.DefaultLogger()
        _ = Primer3DS.version()
        _ = PrimerKlarnaSDK.PrimerKlarnaProvider(clientToken: "", paymentCategory: "")
        _ = PrimerNolPay.version
        _ = PrimerStripeSDK.PrimerStripeStatus.canceled
    }

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
            let handled = AppetizeUrlHandler.handleUrl(url)
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
