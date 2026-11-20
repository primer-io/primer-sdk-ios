//
//  PrimerBDCWebViewEngine.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver
import WebKit

@available(iOS 15.0, *)
@MainActor @_spi(PrimerInternal)
public final class PrimerBDCWebViewEngine: NSObject, EngineScriptRunning {
    let webView: WKWebView

    private let files: EngineFiles
    private var loading: Task<Void, Error>?
    private var pageLoad: CheckedContinuation<Void, Error>?

    public convenience init(manifest: Manifest) async throws {
        try await self.init(files: EngineFilesDownloader().download(manifest))
    }

    init(files: EngineFiles) async throws {
        self.files = files
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        try await load()
    }

    func run(_ script: EngineScript) async throws -> Data {
        try await load()
        let result = try await webView.callAsyncJavaScript(script.body, arguments: script.arguments, in: nil, contentWorld: .page)
        guard let json = result as? String else { throw EngineError.jsonToDataFailed }
        return Data(json.utf8)
    }
}

@available(iOS 15.0, *)
extension PrimerBDCWebViewEngine: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishPageLoad(with: .success(()))
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishPageLoad(with: .failure(error))
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finishPageLoad(with: .failure(error))
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loading = nil
        finishPageLoad(with: .failure(EngineError.loadFailed("The web content process was terminated")))
    }
}

@available(iOS 15.0, *)
private extension PrimerBDCWebViewEngine {
    func load() async throws {
        let task = loading ?? Task {
            try await loadPage()
            try await define(files.celWrapperJS)
            try await define(files.stateProcessorJS)
            try await instantiate()
        }
        loading = task
        do {
            try await task.value
        } catch {
            loading = nil
            throw error
        }
    }

    func loadPage() async throws {
        try await withCheckedThrowingContinuation { continuation in
            pageLoad = continuation
            webView.loadHTMLString("<!DOCTYPE html>", baseURL: nil)
        }
    }

    func finishPageLoad(with result: Result<Void, Error>) {
        pageLoad?.resume(with: result)
        pageLoad = nil
    }

    func define(_ script: String) async throws {
        _ = try await webView.evaluateJavaScript(script + nonNilCompletionValue, in: nil, contentWorld: .page)
    }

    func instantiate() async throws {
        do {
            let wasm = files.celWrapperWASM.base64EncodedString()
            _ = try await webView.callAsyncJavaScript(instantiateScript, arguments: ["wasm": wasm], in: nil, contentWorld: .page)
        } catch {
            throw EngineError.loadFailed(error.javaScriptMessage)
        }
    }
}

private extension Error {
    var javaScriptMessage: String {
        (self as NSError).userInfo["WKJavaScriptExceptionMessage"] as? String ?? "\(self)"
    }
}
