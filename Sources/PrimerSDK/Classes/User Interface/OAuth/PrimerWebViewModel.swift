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
}

internal class ApayaWebViewModel: PrimerWebViewModelProtocol {
    func onRedirect(with url: URL) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let result = Apaya.WebViewResult.create(from: url)
        state.setApayaResult(result)
    }
}

#endif
