//
//  PrimerWebRedirectTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/23.
//

import Foundation

class PrimerWebRedirectTokenizationModule: PrimerTokenizationModule {
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            // Bank tokenization is true
            var needsPreTokenizationUIPresentation = false
            
            if needsPreTokenizationUIPresentation {
                
            } else {
                seal.fulfill()
            }
        }
    }
    
    override func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        return Promise { seal in
            // self.paymentMethodOrchestrator.paymentMethodConfig.id has already been
            // validated by the validator so it safe to force unwrap
            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: self.paymentMethodOrchestrator.paymentMethodConfig.id!,
                paymentMethodType: self.paymentMethodOrchestrator.paymentMethodConfig.type,
                sessionInfo: WebRedirectSessionInfo(
                    locale: PrimerSettings.current.localeData.localeCode))
            seal.fulfill(paymentInstrument)
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
}
