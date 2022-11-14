//
//  CardPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation
import SafariServices
import UIKit

class CardPaymentModule: PaymentModule {
    
    private var redirectUrl: URL!
    private var statusUrl: URL!
    private var webViewController: SFSafariViewController!
    private var webViewCompletion: ((_ authorizationToken: String?, _ error: PrimerError?) -> Void)?
    private var resumeToken: String?
    
    override func handleDecodedJWTTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("_REDIRECTION") == true ||
                decodedJWTToken.intent == RequiredActionName.processor3DS.rawValue
            {
                if let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {
                    
                    DispatchQueue.main.async {
                        PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                    }
                    
                    firstly {
                        self.presentWebViewController()
                    }
                    .then { () -> Promise<String> in
                        let pollingModule = PollingModule(url: statusUrl)
                        
                        self.didCancel = { [weak self] in
                            guard let strongSelf = self else { return }
                            let err = PrimerError.cancelled(
                                paymentMethodType: strongSelf.paymentMethodConfiguration.type,
                                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            pollingModule.cancel(withError: err)
                            strongSelf.webViewCompletion = nil
                            strongSelf.webViewCompletion = nil
                            strongSelf.didCancel = nil
                        }
                        
                        return pollingModule.start()
                    }
                    .done { resumeToken in
                        seal.fulfill(resumeToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    seal.reject(error)
                }
                
            } else if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
    #if canImport(Primer3DS)
                guard let paymentMethodTokenData = paymentMethodTokenData else {
                    let err = InternalError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                    return
                }
                
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodTokenData: paymentMethodTokenData, protocolVersion: decodedJWTToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let resumeToken):
                        DispatchQueue.main.async {
                            seal.fulfill(resumeToken)
                        }
                        
                    case .failure(let err):
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(containerErr)
                    }
                }
    #else
                let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
    #endif
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }

        }
    }
    
    private func presentWebViewController() -> Promise<Void> {
        return Promise { seal in
            self.webViewController = SFSafariViewController(url: self.redirectUrl)
            self.presentedViewController = self.webViewController
            
            self.webViewController!.delegate = self
            
            self.webViewCompletion = { (id, err) in
                if let err = err {
                    seal.reject(err)
                }
            }
            
            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                    DispatchQueue.main.async {
                        seal.fulfill()
                    }
                })
            }
        }
    }
}

extension CardPaymentModule: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.didCancel?()
    }
}

#endif
