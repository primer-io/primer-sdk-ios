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
    
    let paymentMethodConfig: PrimerPaymentMethod
    var validator: PrimerValidator!
    var dataInputModule: PrimerInputDataModule!
    var uiModule: PrimerPaymentMethodUIModule!
    var tokenizationModule: PrimerTokenizationModule!
    var paymentModule: PrimerPaymentModule!
    var eventEmitter: PrimerEventEmitter!
    
    init(paymentMethodConfig: PrimerPaymentMethod) {
        self.paymentMethodConfig = paymentMethodConfig
        
        if paymentMethodConfig.implementationType == .webRedirect {
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
            
        } else {
            self.validator = PrimerValidator(paymentMethodOrchestrator: self)
            self.tokenizationModule = PrimerTokenizationModule(paymentMethodOrchestrator: self)
            self.paymentModule = PrimerPaymentModule(paymentMethodOrchestrator: self)
            self.uiModule = PrimerPaymentMethodUIModule(paymentMethodOrchestrator: self)
            self.dataInputModule = PrimerInputDataModule(paymentMethodOrchestrator: self)
        }

        
        
        self.eventEmitter = PrimerEventEmitter()
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
                
            }
            .ensure {
                
            }
            .catch { err in
                
            }
        }
    }
}




