//
//  WebViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 10/5/21.
//

#if canImport(UIKit)

import UIKit
import WebKit

internal class WebViewController: PrimerViewController, WKNavigationDelegate {

    weak var delegate: ReloadDelegate?

    let webView = WKWebView()

    var url: URL?
    // Maybe refactor to delegate.
    var klarnaWebViewCompletion: ((_ klarnaToken: String?, _ error: Error?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.isAccessibilityElement = false
        webView.accessibilityIdentifier = "primer_webview"
        
        webView.scrollView.bounces = false
        
        // Control which sites can be visited
        webView.navigationDelegate = self
        
        self.view = webView
        
        if let url = url {
            var request = URLRequest(url: url)
            request.timeoutInterval = 60
            request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Primer-SDK-Version": "1.0.0-beta.0",
                "Primer-SDK-Client": "IOS_NATIVE"
            ]
            webView.load(request)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isBeingDismissed && klarnaWebViewCompletion != nil {
            let err = PrimerError.userCancelled
            klarnaWebViewCompletion?(nil, err)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        log(logLevel: .info, message: "🚀 \(navigationAction.request.url?.host ?? "n/a")")
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if var urlStr = navigationAction.request.url?.absoluteString,
           urlStr.hasPrefix("bankid://") == true {
            // This is a redirect to the BankId app
            
            
            if urlStr.contains("redirect=null"), let urlScheme = settings.urlScheme {
                // Klarna's redirect param should contain our URL scheme, replace null with urlScheme if we have a urlScheme if present.
                urlStr = urlStr.replacingOccurrences(of: "redirect=null", with: "redirect=\(urlScheme)")
            }
            
            // The bankid redirection URL looks like the one below
            /// bankid:///?autostarttoken=197701116050-fa74-49cf-b98c-bfe651f9a7c6&redirect=null
            if UIApplication.shared.canOpenURL(URL(string: urlStr)!) {
                decisionHandler(.allow)
                UIApplication.shared.open(URL(string: urlStr)!, options: [:]) { (isFinished) in

                }
                return
            }
        }
        
        let allowedHosts: [String] = [
            "primer.io",
//            "api.playground.klarna.com",
//            "api.sandbox.primer.io"
        ]

        if let url = navigationAction.request.url, let host = url.host, allowedHosts.contains(host) {
            let urlStateParameter = url.queryParameterValue(for: "state")
            if urlStateParameter == "cancel" {
                let err = PrimerError.userCancelled
                klarnaWebViewCompletion?(nil, err)
                klarnaWebViewCompletion = nil
                decisionHandler(.cancel)
                return
            }
            
            let val = url.queryParameterValue(for: "token")
            
            if (val ?? "").isEmpty || val == "undefined" || val == "null" {
                let err = PrimerError.clientTokenNull
                klarnaWebViewCompletion?(nil, err)
                klarnaWebViewCompletion = nil
                decisionHandler(.cancel)
                return
            }

            log(logLevel: .info, message: "🚀🚀 \(url)")
            log(logLevel: .info, message: "🚀🚀 token \(val)")
            
            let state: AppStateProtocol = DependencyContainer.resolve()

            // FIXME: WebView should be agnostic of state and not set it. Debug what happens on
            state.authorizationToken = val
            klarnaWebViewCompletion?(val, nil)
            klarnaWebViewCompletion = nil

            log(logLevel: .info, message: "🚀🚀🚀 \(state.authorizationToken ?? "n/a")")

            // Cancels navigation
            decisionHandler(.cancel)
            
        } else {
            // Allow navigation to continue
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if !(nsError.domain == "NSURLErrorDomain" && nsError.code == -1002) {
            // Code -1002 means bad URL redirect. Klarna is redirecting to bankid:// which is considered a bad URL
            // Not sure yet if we have to do that only for bankid://
            klarnaWebViewCompletion?(nil, error)
            klarnaWebViewCompletion = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        klarnaWebViewCompletion?(nil, error)
        klarnaWebViewCompletion = nil
    }
    
}

#endif
