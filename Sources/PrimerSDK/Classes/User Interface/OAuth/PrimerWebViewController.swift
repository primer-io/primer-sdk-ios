//
//  PrimerWebViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 28/07/2021.
//

#if canImport(UIKit)

import UIKit
import WebKit

internal class PrimerWebViewController: PrimerViewController, WKNavigationDelegate {
    weak var delegate: ReloadDelegate?
    weak var viewModel: PrimerWebViewModelProtocol?

    init(with viewModel: PrimerWebViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let allowedHosts: [String] = ["primer.io"]
    let headerFields = [
        "Content-Type": "application/json",
        "Primer-SDK-Version": "1.0.0-beta.0",
        "Primer-SDK-Client": "IOS_NATIVE"
    ]
    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        renderWebView()
    }
    //
    private func renderWebView() {
        let webView = WKWebView()
        webView.isAccessibilityElement = false
        webView.accessibilityIdentifier = "primer_webview"
        webView.scrollView.bounces = false
        webView.navigationDelegate = self // Control which sites can be visited
        view = webView
        if let url = url {
            var request = URLRequest(url: url)
            request.timeoutInterval = 60
            request.allHTTPHeaderFields = headerFields
            webView.load(request)
        }
    }
    //
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if
            let url = navigationAction.request.url,
            let host = url.host, allowedHosts.contains(host)
        {
            viewModel?.onRedirect(with: url)
            delegate?.reload()
            decisionHandler(.cancel)
            dismiss(animated: true, completion: nil)
        } else {
            decisionHandler(.allow)
        }
    }
}

#endif
