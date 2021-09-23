//
//  APMWebViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/9/21.
//

import Foundation
import WebKit

protocol APMViewController: UIViewController {
    var name: String { get }
    var request: APMRequest! { get set }
    var completionHandler: ((_ response: [String: String]?, _ err: Error?) -> Void)? { get set }
}

class APMWebViewController: PrimerViewController, APMViewController, WKNavigationDelegate {
    
    var name: String
    var request: APMRequest!
    private var redirectUrlSchemePrefix: String?
    private var allowedHosts: [String]?
    var completionHandler: ((_ response: [String: String]?, _ err: Error?) -> Void)?
    
    private var webView: WKWebView!
    
    init(name: String, request: APMRequest, redirectUrlSchemePrefix: String?, allowedHosts: [String]?) throws {
        self.name = name
        self.request = request
        self.redirectUrlSchemePrefix = redirectUrlSchemePrefix
        self.allowedHosts = allowedHosts
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func loadView() {
        webView = WKWebView()
        webView.isAccessibilityElement = false
        webView.accessibilityIdentifier = "primer_webview"
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        view = webView
        webView.load(request as! URLRequest)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        log(logLevel: .info, message: "🚀 \(navigationAction.request.url?.host ?? "n/a")")
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if let redirectUrlSchemePrefix = redirectUrlSchemePrefix,
           var urlStr = navigationAction.request.url?.absoluteString,
           urlStr.hasPrefix(redirectUrlSchemePrefix)
        {
            // This is a redirect to the another app
 
            if urlStr.contains("redirect=null"),
               let urlScheme = settings.urlScheme
            {
                // If our URL scheme (that we want to pass to the other app) is not present, use the URL scheme from the settings
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
        
        if let url = navigationAction.request.url, let host = url.host, (allowedHosts ?? []).contains(host) {
            if name == ConfigPaymentMethodType.klarna.rawValue {
                if let urlStateParameter = url.queryParameterValue(for: "state"), urlStateParameter == "cancel" {
                    let err = PrimerError.userCancelled
                    completionHandler?(nil, err)
                    completionHandler = nil
                    decisionHandler(.cancel)
                    return
                }
                
                if let token = url.queryParameterValue(for: "token") {
                    if token.isEmpty || token == "undefined" || token == "null" {
                        let err = PrimerError.userCancelled
                        completionHandler?(nil, err)
                        completionHandler = nil
                        decisionHandler(.cancel)
                        return
                    }
                    
                    log(logLevel: .info, message: "🚀🚀 \(url)")
                    log(logLevel: .info, message: "🚀🚀 token \(token)")

                    completionHandler?(url.queryParameters!, nil)
                    completionHandler = nil
                    decisionHandler(.cancel)
                    return
                    
                } else {
                    decisionHandler(.allow)
                }
                
            } else if name == ConfigPaymentMethodType.apaya.rawValue {
                completionHandler?(navigationAction.request.url!.queryParameters!, nil)
                decisionHandler(.cancel)
                
            } else {
                // Allow navigation to continue
                decisionHandler(.allow)
            }
            
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
            completionHandler?(nil, error)
            completionHandler = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        completionHandler?(nil, error)
        completionHandler = nil
    }
    
}
