//
//  ApayaLoadWebViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/08/2021.
//

#if canImport(UIKit)

import UIKit

internal class ApayaLoadWebViewController: PrimerLoadWebViewController {
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        presentLoader()
        generateUrl()
    }
    //
    internal func generateUrl() {
        let viewModel: ApayaLoadWebViewModelProtocol = DependencyContainer.resolve()
        viewModel.generateWebViewUrl { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self?.presentError(error)
                case .success(let urlString):
                    let webViewController = ApayaWebViewController()
                    self?.presentWebview(urlString, webViewController: webViewController)
                }
            }
        }
    }
    //
    override func reload() {
        super.reload()
        let viewModel: ApayaLoadWebViewModelProtocol = DependencyContainer.resolve()
        viewModel.tokenize()
    }
}

#endif
