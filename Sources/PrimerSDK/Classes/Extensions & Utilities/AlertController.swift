//
//  AlertController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 17/3/21.
//

#if canImport(UIKit)

import UIKit

class AlertController: UIAlertController {

    /// The UIWindow that will be at the top of the window hierarchy. The DBAlertController instance is presented on the rootViewController of this window.
    private lazy var alertWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
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

private class ClearViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIApplication.shared.statusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        return UIApplication.shared.isStatusBarHidden
    }

}

#endif
