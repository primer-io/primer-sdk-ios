//
//  PrimerWebViewController.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
import WebKit

final class PrimerWebViewController: PrimerViewController {

    private let webView: WKWebView! = WKWebView()
    internal private(set) var url: URL
    var navigationDelegate: WKNavigationDelegate? {
        didSet {
            webView?.navigationDelegate = navigationDelegate
        }
    }
    private let allowedHosts: [String] = [
        "primer.io",
        "livedemostore.primer.io"
    ]

    init(with url: URL) {
        self.url = url
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        renderWebView()
    }

    private func renderWebView() {
        webView.isAccessibilityElement = false
        webView.accessibilityIdentifier = "primer_webview"
        webView.scrollView.bounces = false
        webView.navigationDelegate = navigationDelegate

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true

        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.allHTTPHeaderFields = PrimerAPI.headers
        webView.load(request)
    }

}
