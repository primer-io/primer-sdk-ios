//
//  PrimerWebRedirectUIModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

#if canImport(UIKit)

import Foundation
import SafariServices
import UIKit

class PrimerWebRedirectUIModule: PrimerPaymentMethodUIModule {
    
    var redirectUrl: URL!
    private var redirectUrlComponents: URLComponents?
    private var resumeToken: String!
    private var webViewController: SFSafariViewController?
    
    override func presentPaymentUI() -> Promise<Void> {
        self.paymentMethodOrchestrator.eventEmitter.fireWillPresentPaymentMethodUIEvent()
        
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.webViewController = SFSafariViewController(url: self.redirectUrl)
                self.webViewController?.delegate = self
                                
                self.redirectUrlComponents = URLComponents(string: self.redirectUrl.absoluteString)
                self.redirectUrlComponents?.query = nil
                
                PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: { [weak self] in
                    self?.paymentMethodOrchestrator.eventEmitter.fireDidPresentPaymentMethodUIEvent()
                    seal.fulfill()
                })
            }
        }
    }
    
    override func dismissPaymentUI() -> Promise<Void> {
        self.paymentMethodOrchestrator.eventEmitter.fireWillDismissPaymentMethodUIEvent()
        
        return Promise { seal in
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
            self.webViewController?.dismiss(animated: true, completion: { [weak self] in
                self?.paymentMethodOrchestrator.eventEmitter.fireWillPresentPaymentMethodUIEvent()
                seal.fulfill()
            })
        }
    }
}

extension PrimerWebRedirectUIModule: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if UIApplication.shared.applicationState != .active { return }
//        self.cancel()
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {

    }
    
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        if var safariRedirectComponents = URLComponents(string: URL.absoluteString) {
            safariRedirectComponents.query = nil
        }
        
        if URL.absoluteString.hasSuffix("primer.io/static/loading.html") || URL.absoluteString.hasSuffix("primer.io/static/loading-spinner.html") {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
            self.webViewController?.dismiss(animated: true)
        }
    }
}

#endif
