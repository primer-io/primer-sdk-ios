//
//  PrimerWebViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 05/08/2021.
//

#if canImport(UIKit)

import UIKit

internal protocol PrimerWebViewModelProtocol: AnyObject {
    func onRedirect(with url: URL)
    func onDismiss()
}

internal class ApayaWebViewModel: PrimerWebViewModelProtocol {

    var result: Result<Apaya.WebViewResult, Error>?

    private func setResult(_ value: Result<Apaya.WebViewResult, Error>?) {
        result = value
    }

    func onRedirect(with url: URL) {
        setResult(Apaya.WebViewResult.create(from: url))
    }

    func onDismiss() {
        let result = self.result ?? .failure(ApayaException.webViewFlowCancelled)
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.setApayaResult(result)
        setResult(nil)
    }
}

#endif
