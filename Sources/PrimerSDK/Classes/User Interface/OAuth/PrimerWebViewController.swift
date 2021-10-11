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

    var viewModel: PrimerWebViewModelProtocol?

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(with viewModel: PrimerWebViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        renderWebView()
    }

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
            request.allHTTPHeaderFields = PrimerAPI.headers
            webView.load(request)
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if
            let url = navigationAction.request.url,
            let host = url.host,
            WebViewUtil.isPrimerDomain(host)
        {
            viewModel?.onRedirect(with: url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && webView.url == nil {
            viewModel?.onError(error)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
    
}

#endif
