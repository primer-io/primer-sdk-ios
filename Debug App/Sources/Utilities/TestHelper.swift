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

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let queryItems = components?.queryItems else {
            return
        }

        handle(queryItems: queryItems)
    }

    private static func handle(queryItems: [URLQueryItem]) {
        if let item = queryItems.first(where: { $0.name == "set-pasteboard" }) {
            UIPasteboard.general.string = item.value
        }
    }

    private static func dismissWebViewControllers() {

        let vcs = windows.compactMap { $0.rootViewController?.presentedViewController as? SFSafariViewController }
        vcs.forEach { $0.dismiss(animated: true) }
    }

    private static var windows: [UIWindow] {
        return UIApplication.shared.windows
    }
}
