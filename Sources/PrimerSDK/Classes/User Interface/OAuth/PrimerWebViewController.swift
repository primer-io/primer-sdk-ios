//
//  PrimerWebViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 28/07/2021.
//

#if canImport(UIKit)

import UIKit
import WebKit

internal class PrimerWebViewController: PrimerViewController {
    
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

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self.self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(with url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        view = webView
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.allHTTPHeaderFields = PrimerAPI.headers
        webView.load(request)
    }
    
}

#endif
