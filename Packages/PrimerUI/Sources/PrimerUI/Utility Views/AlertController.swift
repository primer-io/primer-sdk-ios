//
//  AlertController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public final class AlertController: UIAlertController {

    private lazy var alertWindow: UIWindow = {
        var window: UIWindow!
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
        } else {
            // Not opted-in in UISceneDelegate
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        window.rootViewController = ClearViewController()
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.alert
        return window
    }()

    public func show(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        if let rootViewController = alertWindow.rootViewController {
            alertWindow.makeKeyAndVisible()
            rootViewController.present(self, animated: flag, completion: completion)
        }
    }

}

public final class ClearViewController: UIViewController {

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        let statusBarManager = view.window?.windowScene?.statusBarManager
        return statusBarManager?.statusBarStyle ?? .default
    }

    override public var prefersStatusBarHidden: Bool {
        let statusBarManager = view.window?.windowScene?.statusBarManager
        return statusBarManager?.isStatusBarHidden ?? false
    }
}
