//
//  MerchantSessionAndSettingsViewController+DeepLink.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI
import UIKit

extension MerchantSessionAndSettingsViewController {

    /// Lives in the always-visible button stack so a failed link is diagnosable in every render mode.
    func setupDeepLinkErrorLabel() {
        deepLinkErrorLabel.font = .preferredFont(forTextStyle: .footnote)
        deepLinkErrorLabel.textColor = .systemRed
        deepLinkErrorLabel.numberOfLines = 0
        deepLinkErrorLabel.isHidden = true
        deepLinkErrorLabel.accessibilityIdentifier = "deep_link_error_label"
        bottomButtonHolderStackView.insertArrangedSubview(deepLinkErrorLabel, at: 0)
    }

    func clearDeepLinkFailure() {
        deepLinkErrorLabel.text = nil
        deepLinkErrorLabel.isHidden = true
    }

    /// The text keeps a fixed prefix so a page object can read it back and fail fast.
    func reportDeepLinkFailure(_ reason: String) {
        deepLinkErrorLabel.text = "deep link error: \(reason)"
        deepLinkErrorLabel.isHidden = false
        PrimerLogging.shared.logger.warn(message: "[DeepLink] \(reason)")
    }

    /// Presents the deep-linked demo once this screen is on screen. A link that arrives before the
    /// first appearance (cold start) or while another screen is pushed on top waits here for
    /// `viewDidAppear`; UIKit drops presentations from a controller that is not in a window.
    func presentPendingDeepLinkDemoIfPossible() {
        guard let demo = pendingDeepLinkDemo else { return }
        guard viewIfLoaded?.window != nil else {
            if let navigationController, navigationController.topViewController !== self {
                navigationController.popToRootViewController(animated: false)
            }
            return
        }
        pendingDeepLinkDemo = nil

        guard #available(iOS 15.0, *) else { return reportDeepLinkFailure("CheckoutComponents requires iOS 15") }
        guard let key = DemoKey(rawValue: demo) else { return reportDeepLinkFailure("unknown demo key \"\(demo)\"") }
        guard let deepLinkClientToken else { return reportDeepLinkFailure("clientToken missing") }
        guard let deepLinkSettings else { return reportDeepLinkFailure("settings missing or invalid") }

        let configuration = DemoConfiguration(
            settings: deepLinkSettings,
            apiVersion: deepLinkSettings.apiVersion,
            clientSession: nil,
            clientToken: deepLinkClientToken
        )
        guard let demoView = DemoRegistry.createDemo(key: key, configuration: configuration) else {
            return reportDeepLinkFailure("demo \"\(demo)\" is not registered")
        }

        let host = UIHostingController(rootView: demoView)
        let presenter = navigationController ?? self
        if let presented = presenter.presentedViewController {
            presented.dismiss(animated: false) { presenter.present(host, animated: true) }
        } else {
            presenter.present(host, animated: true)
        }
    }
}
