//
//  TestHelper.swift
//  Debug App
//
//  Created by Jack Newcombe on 20/06/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK
import SafariServices

class TestHelper {

    static func handle(url: URL) {
        guard url.host == "ui-tests" else {
            return
        }

        if url.pathComponents.count > 1, url.pathComponents[1] == "dismiss" {
            dismissWebViewControllers()
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
}
