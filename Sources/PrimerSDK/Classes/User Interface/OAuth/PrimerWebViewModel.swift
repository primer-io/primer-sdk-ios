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
    func onDismiss(error: Error?)
}

internal class ApayaWebViewModel: PrimerWebViewModelProtocol {

    var result: Result<Apaya.WebViewResult, Error>?

    private func setResult(_ value: Result<Apaya.WebViewResult, Error>?) {
        result = value
    }

    func onRedirect(with url: URL) {
        setResult(Apaya.WebViewResult.create(from: url))
    }

    func onDismiss(error: Error? = nil) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if let err = error {
            let result: Result<Apaya.WebViewResult, Error> = .failure(err)
            state.setApayaResult(result)
        } else {
            let result = self.result ?? .failure(ApayaException.webViewFlowCancelled)
            state.setApayaResult(result)
        }
        
        setResult(nil)
    }
}

#endif
