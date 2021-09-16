//
//  PrimerWebViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 05/08/2021.
//

#if canImport(UIKit)

import UIKit

internal protocol PrimerWebViewModelProtocol: ReloadDelegate {
    func onRedirect(with url: URL)
    func onDismiss()
}

internal class ApayaWebViewModel: PrimerWebViewModelProtocol {

    var result: Result<Apaya.WebViewResult, ApayaException>?
    var onCompletion: ((Result<Apaya.WebViewResult, ApayaException>) -> Void)?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    private func setResult(_ value: Result<Apaya.WebViewResult, ApayaException>?) {
        result = value
    }

    func onRedirect(with url: URL) {
        setResult(Apaya.WebViewResult.create(from: url))
    }

    func onDismiss() {
        let result = result ?? .failure(ApayaException.webViewFlowCancelled)
        onCompletion?(result)
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.setApayaResult(result)
        setResult(nil)
    }
    
    func reload() {
        
    }
}

#endif
