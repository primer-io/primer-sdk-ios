//
//  PaymentMethodTokenizationViewModel+Logic.swift
//  PrimerSDK
//
//  Created by Evangelos on 6/5/22.
//

#if canImport(UIKit)

import Foundation
import UIKit

extension PaymentMethodTokenizationViewModel {
        
    @objc
    func start() {
        firstly {
            self.startTokenizationFlow()
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData
            self.didFinishTokenization?(nil)
            self.didFinishTokenization = nil

            if Primer.shared.intent == .vault {
                self.handleSuccessfulFlow()
            } else {
                self.didStartPayment?()
                self.didStartPayment = nil
                
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)
                
                let paymentModule: PaymentModuleProtocol = PaymentModule(paymentMethodTokenizationViewModel: self)
                
                firstly {
                    paymentModule.pay(with: paymentMethodTokenData)
                }
                .done { checkoutData in
                    self.didFinishPayment?(nil)
                    self.nullifyEventCallbacks()
                    
                    if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                        PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                    }
                    
                    self.handleSuccessfulFlow()
                }
                .ensure {
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
                .catch { err in
                    self.didFinishPayment?(err)
                    self.nullifyEventCallbacks()
                    
                    let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                    
                    firstly {
                        clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                    }
                    .then { () -> Promise<String?> in
                        var primerErr: PrimerError!
                        if let error = err as? PrimerError {
                            primerErr = error
                        } else {
                            primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: nil)
                        }
                        
                        return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                    }
                    .done { merchantErrorMessage in
                        self.handleFailureFlow(errorMessage: merchantErrorMessage)
                    }
                    // The above promises will never end up on error.
                    .catch { _ in }
                }
            }
        }
        .ensure {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
        .catch { err in
            self.didFinishTokenization?(err)
            self.didStartTokenization = nil
            self.didFinishTokenization = nil
            
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            
            if let primerErr = err as? PrimerError,
               case .cancelled = primerErr,
               self.config.type == PrimerPaymentMethodType.applePay.rawValue,
               PrimerHeadlessUniversalCheckout.current.delegate == nil
            {
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .done { merchantErrorMessage in
                    Primer.shared.primerRootVC?.popToMainScreen(completion: nil)
                }
                // The above promises will never end up on error.
                .catch { _ in }
                
            } else {
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .then { () -> Promise<String?> in
                    var primerErr: PrimerError!
                    if let error = err as? PrimerError {
                        primerErr = error
                    } else {
                        primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: nil)
                    }
                    
                    return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                }
                // The above promises will never end up on error.
                .catch { _ in }
            }
        }
    }
    
    func handleSuccessfulFlow() {
        Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .success, withMessage: self.successMessage)
    }
    
    func handleFailureFlow(errorMessage: String?) {
        Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: errorMessage)
    }
        
    internal func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if Primer.shared.intent == .vault {
                seal.fulfill()
            } else {
                let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
                
                PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                    switch paymentCreationDecision.type {
                    case .abort(let errorMessage):
                        let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        seal.reject(error)
                    case .continue:
                        seal.fulfill()
                    }
                })
            }
        }
    }

    func validateReturningPromise() -> Promise<Void> {
        return Promise { seal in
            do {
                try self.validate()
                seal.fulfill()
            } catch {
                seal.reject(error)
            }
        }
    }
    
    func nullifyEventCallbacks() {
        self.didStartTokenization = nil
        self.didFinishTokenization = nil
        self.didStartPayment = nil
        self.didFinishPayment = nil
    }
}

#endif
