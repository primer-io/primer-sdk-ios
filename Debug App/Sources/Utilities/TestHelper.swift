//
//  TestHelper.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
import PrimerSDK
import SafariServices

class TestHelper {

    // MARK: Deep linking

    static func handle(url: URL) {
        // Handles sdk-demo test links as deepLinks
        if url.host == "sdk-demo.primer.io" {
            SDKDemoUrlHandler.handleUrl(url)
            return
        }
        
        guard url.host == "ui-tests" else {
            return
        }

        if url.pathComponents.count > 1 {
            let rootPath = url.pathComponents[1]
            if rootPath == "dismiss" {
                dismissWebViewControllers()
            }
            if rootPath == "set-client-token" {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                guard let token = components?.queryItems?.first(where: { $0.name == "token" })?.value else {
                    return
                }
                updateClientToken(token)
            }
        }
    }

    private static func dismissWebViewControllers() {

        let vcs = windows.compactMap { $0.rootViewController?.presentedViewController as? SFSafariViewController }
        vcs.forEach { vc in
            vc.dismiss(animated: true) {
                vc.delegate?.safariViewControllerDidFinish?(vc)
            }
        }
    }

    private static var windows: [UIWindow] {
        return UIApplication.shared.windows
    }

    private static var keyWindow: UIWindow? {
        return UIApplication.shared.keyWindow
    }

    // MARK: Client Token handling

    static func updateClientToken(_ token: String) {
        let nc = keyWindow?.rootViewController as? UINavigationController

        guard let vc = nc?.topViewController as? MerchantSessionAndSettingsViewController else {
            return
        }

        vc.clientTokenTextField.text = token
    }
}
