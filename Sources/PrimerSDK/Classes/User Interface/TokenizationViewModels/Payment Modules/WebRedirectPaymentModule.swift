//
//  WebRedirectPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation
import SafariServices
import UIKit

class WebRedirectPaymentModule: PaymentModule {
    
    private var redirectUrl: URL!
    private var statusUrl: URL!
    private var webViewController: SFSafariViewController!
    private var resumeToken: String?
    
    override func handleDecodedJWTTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                if let redirectUrlStr = decodedJWTToken.redirectUrl,
                   let redirectUrl = URL(string: redirectUrlStr),
                   let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {
                    
                    DispatchQueue.main.async {
                        PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                    }
                    
                    self.redirectUrl = redirectUrl
                    self.statusUrl = statusUrl
                    
                    firstly {
                        self.paymentMethodModule.checkouEventsNotifierModule.fireWillPresentPaymentMethodUI()
                    }
                    .then { () -> Promise<Void> in
                        return self.presentPaymentMethodUserInterface()
                    }
                    .then { () -> Promise<Void> in
                        return self.paymentMethodModule.checkouEventsNotifierModule.fireDidPresentPaymentMethodUI()
                    }
                    .then { () -> Promise<Void> in
                        return self.awaitUserInput()
                    }
                    .done {
                        seal.fulfill(self.resumeToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            } else {
                seal.fulfill(nil)
            }
        }
    }
    
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.webViewController = SFSafariViewController(url: self.redirectUrl)
                self.webViewController.delegate = self
                
                PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                    DispatchQueue.main.async {
                        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPaymentMethodDidShow?(for: self.paymentMethodModule.paymentMethodConfiguration.type)
                        seal.fulfill(())
                    }
                })
            }
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            firstly { () -> Promise<String> in
                let pollingModule = PollingModule(url: self.statusUrl)
                
                self.didCancel = {
                    let err = PrimerError.cancelled(
                        paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    pollingModule.cancel(withError: err)
                }
                
                return pollingModule.start()
            }
            .done { resumeToken in
                self.resumeToken = resumeToken
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
}

extension WebRedirectPaymentModule: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.didCancel?()
        self.didCancel = nil
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
//        if didLoadSuccessfully {
//            self.didPresentPaymentMethodUI?()
//        }
    }
    
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        if URL.absoluteString.hasSuffix("primer.io/static/loading.html") || URL.absoluteString.hasSuffix("primer.io/static/loading-spinner.html") {
            self.webViewController?.dismiss(animated: true)
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        }
    }
}

enum PollingStatus: String, Codable {
    case pending = "PENDING"
    case complete = "COMPLETE"
}

struct PollingResponse: Decodable {
    let status: PollingStatus
    let id: String
    let source: String
    let urls: PollingURLs
}

struct PollingURLs: Decodable {
    let status: String
    lazy var statusUrl: URL? = {
        return URL(string: status)
    }()
    let redirect: String
    lazy var redirectUrl: URL? = {
        return URL(string: redirect)
    }()
    let complete: String?
}

struct QRCodePollingURLs: Decodable {
    let status: String
    lazy var statusUrl: URL? = {
        return URL(string: status)
    }()
    let complete: String?
}

#endif
