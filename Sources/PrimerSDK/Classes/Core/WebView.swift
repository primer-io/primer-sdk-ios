//
//  WebView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import WebKit

private let appReturnURL = "https://sdk-demo.primer.io"

private let bridgeJS = """
window.PrimerHostAppBridge = {
  getContext: function () {
    return Promise.resolve({
      appUrl: "\(appReturnURL)",
      osType: "IOS",
      osVersion: "\(UIDevice.current.systemVersion)"
    });
  },
  openApprovalUrl: function (url) {
    window.webkit.messageHandlers.openApprovalUrl.postMessage(url);
  }
};
"""

struct WebView: UIViewRepresentable {
    let url: URL?
    @Binding var logs: [String]
    @Binding var returnURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let userScript = WKUserScript(
            source: bridgeJS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)
        config.userContentController.add(context.coordinator, name: "openApprovalUrl")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.webView = webView

        if let url {
            context.coordinator.lastLoadedURL = url
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url, url != context.coordinator.lastLoadedURL {
            context.coordinator.lastLoadedURL = url
            webView.load(URLRequest(url: url))
        }

        if let returnURL {
            context.coordinator.handlePayPalReturn(returnURL)
            DispatchQueue.main.async {
                self.returnURL = nil
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let parent: WebView
        var lastLoadedURL: URL?
        weak var webView: WKWebView?

        init(_ parent: WebView) {
            self.parent = parent
        }

        // MARK: - JS bridge

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "openApprovalUrl",
                  let urlString = message.body as? String,
                  let url = URL(string: urlString) else { return }

            addLog("openApprovalUrl: \(urlString)")
            UIApplication.shared.open(url) { success in
                self.addLog("Open PayPal approval \(success ? "OK" : "FAILED")")
            }
        }

        // MARK: - PayPal return

        func handlePayPalReturn(_ url: URL) {
            addLog("PayPal return: \(url.absoluteString)")

            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let orderId = components?.queryItems?.first(where: { $0.name == "token" })?.value ?? ""

            if orderId.isEmpty {
                addLog("WARNING: No 'token' in return URL")
            }

            let js = """
            document.dispatchEvent(new CustomEvent('primer:resume-app-switch', {
              detail: { orderId: '\(orderId)' }
            }));
            """
            addLog("Resuming app switch, orderId=\(orderId)")
            webView?.evaluateJavaScript(js) { _, error in
                if let error {
                    self.addLog("Resume error: \(error.localizedDescription)")
                }
            }
        }

        // MARK: - Navigation

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""

            if scheme == "http" || scheme == "https" || scheme == "about" {
                addLog("Loading: \(url.absoluteString)")
                decisionHandler(.allow)
                return
            }

            addLog("External scheme: \(url.absoluteString)")
            UIApplication.shared.open(url) { success in
                self.addLog("External scheme \(success ? "OK" : "FAILED")")
            }
            decisionHandler(.cancel)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url {
                addLog("Loaded: \(url.absoluteString)")
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            addLog("Failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            addLog("Failed: \(error.localizedDescription)")
        }

        // MARK: - UI delegate

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                addLog("Popup: \(url.absoluteString)")
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        // MARK: - Logging

        private func addLog(_ message: String) {
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            DispatchQueue.main.async {
                self.parent.logs.append("[\(timestamp)] \(message)")
            }
        }
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
