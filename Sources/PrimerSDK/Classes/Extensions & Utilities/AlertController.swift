//
//  AlertController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 17/3/21.
//



import UIKit

internal class AlertController: UIAlertController {

    private lazy var alertWindow: UIWindow = {
        var window: UIWindow!
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive }).first as? UIWindowScene {
                window = UIWindow(windowScene: windowScene)
            } else {
                // Not opted-in in UISceneDelegate
                window = UIWindow(frame: UIScreen.main.bounds)
            }
        } else {
            // Fallback on earlier versions
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        window.rootViewController = ClearViewController()
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.alert
        return window
    }()

    internal func show(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        if let rootViewController = alertWindow.rootViewController {
            alertWindow.makeKeyAndVisible()
            rootViewController.present(self, animated: flag, completion: completion)
        }
    }

}

internal class ClearViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIApplication.shared.statusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        return UIApplication.shared.isStatusBarHidden
    }

}


