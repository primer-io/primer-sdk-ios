//
//  SceneDelegate.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateInitialViewController()
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()

        // Handle URL context if app was launched via URL
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }

        // Handle user activity if app was launched via universal link
        if let userActivity = connectionOptions.userActivities.first {
            handleUserActivity(userActivity)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleURL(url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }

    private func handleURL(_ url: URL) {
        #if DEBUG
        TestHelper.handle(url: url)
        #endif
        _ = Primer.shared.application(UIApplication.shared, open: url, options: [:])
    }

    private func handleUserActivity(_ userActivity: NSUserActivity) {
        if let url = userActivity.webpageURL {
            let handled = SDKDemoUrlHandler.handleUrl(url)
            if handled {
                return
            }
        }
        _ = Primer.shared.application(UIApplication.shared, continue: userActivity, restorationHandler: { _ in })
    }
}
