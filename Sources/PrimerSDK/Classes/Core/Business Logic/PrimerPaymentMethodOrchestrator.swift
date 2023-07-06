//
//  PrimerPaymentMethodOrchestrator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/23.
//

import Foundation

protocol PaymentMethodOrchestratorConvertible {
    
    
}

class PrimerPaymentMethodOrchestrator {
    
    weak private(set) var paymentMethodConfig: PrimerPaymentMethod!
    var validator: PrimerValidator!
    var dataInputModule: PrimerInputDataModule!
    var uiModule: PrimerPaymentMethodUIModule!
    var tokenizationModule: PrimerTokenizationModule!
    var paymentModule: PrimerPaymentModule!
    var eventEmitter: PrimerEventEmitter!
    
    var isCancelled: Bool = false
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init?(paymentMethodConfig: PrimerPaymentMethod) {
        self.paymentMethodConfig = paymentMethodConfig
        
        if paymentMethodConfig.implementationType == .webRedirect {
            if PrimerInternal.shared.intent == .vault {
                return nil
            }
            
            self.validator = PrimerWebRedirectValidator(paymentMethodOrchestrator: self)
            self.tokenizationModule = PrimerWebRedirectTokenizationModule(paymentMethodOrchestrator: self)
            self.paymentModule = PrimerWebRedirectPaymentModule(paymentMethodOrchestrator: self)
            self.uiModule = PrimerWebRedirectUIModule(paymentMethodOrchestrator: self)
            self.dataInputModule = PrimerWebRedirectInputDataModule(paymentMethodOrchestrator: self)
            
        } else if paymentMethodConfig.type == "PAYMENT_CARD" {
            self.validator = PrimerPaymentCardValidator(paymentMethodOrchestrator: self)
            self.tokenizationModule = PrimerTokenizationModule(paymentMethodOrchestrator: self)
            self.paymentModule = PrimerPaymentModule(paymentMethodOrchestrator: self)
            self.uiModule = PrimerWebRedirectUIModule(paymentMethodOrchestrator: self)
            self.dataInputModule = PrimerWebRedirectInputDataModule(paymentMethodOrchestrator: self)
            
        } else if paymentMethodConfig.type == "APPLE_PAY" {
            if PrimerInternal.shared.intent == .vault {
                return nil
            }
            
            if #available(iOS 11.0, *) {
                self.validator = PrimerApplePayValidator(paymentMethodOrchestrator: self)
                self.tokenizationModule = PrimerApplePayTokenizationModule(paymentMethodOrchestrator: self)
                self.paymentModule = PrimerApplePayPaymentModule(paymentMethodOrchestrator: self)
                self.uiModule = PrimerApplePayUIModule(paymentMethodOrchestrator: self)
                self.dataInputModule = PrimerApplePayInputDataModule(paymentMethodOrchestrator: self)
            } else {
                return nil
            }
        } else {
            self.validator = PrimerValidator(paymentMethodOrchestrator: self)
            self.tokenizationModule = PrimerTokenizationModule(paymentMethodOrchestrator: self)
            self.paymentModule = PrimerPaymentModule(paymentMethodOrchestrator: self)
            self.uiModule = PrimerPaymentMethodUIModule(paymentMethodOrchestrator: self)
            self.dataInputModule = PrimerInputDataModule(paymentMethodOrchestrator: self)
        }

        self.eventEmitter = PrimerEventEmitter(paymentMethodOrchestrator: self)
    }
    
    func start() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.validator.validate()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenizationModule.start()
            }
            .then { primerPaymentMethodTokenData -> Promise<PrimerCheckoutData?> in
                return self.paymentModule.start()
            }
            .done { checkoutData in
                if let checkoutData = checkoutData {
                    /// We won't have **checkoutData** with the **manual** payment handling
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }
                self.uiModule.presentResultUIIfNeeded(forResult: .success, withMessage: nil)
            }
            .ensure {
                
            }
            .catch { err in
                var primerError: PrimerError
                if let primerErr = err as? PrimerError {
                    primerError = primerErr
                } else {
                    primerError = PrimerError.underlyingErrors(
                        errors: [err],
                        userInfo: nil,
                        diagnosticsId: UUID().uuidString)
                }
                PrimerDelegateProxy.primerDidFailWithError(primerError, data: self.paymentModule.checkoutData) { decisionHandler in
                    switch decisionHandler.type {
                    case .fail(errorMessage: let errorMessage):
                        self.uiModule.presentResultUIIfNeeded(forResult: .failure, withMessage: errorMessage)
                    }
                }
            }
        }
    }
    
    func cancel() {
        self.isCancelled = true
    }
}




