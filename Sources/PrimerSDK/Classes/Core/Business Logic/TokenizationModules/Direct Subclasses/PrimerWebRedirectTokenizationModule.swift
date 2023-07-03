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
    
    override func performTokenizationStep() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            let sessionInfo = WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
            
            // self.paymentMethodOrchestrator.paymentMethodConfig.id has already been
            // validated by the validator so it safe to force unwrap
            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: self.paymentMethodOrchestrator.paymentMethodConfig.id!,
                paymentMethodType: self.paymentMethodOrchestrator.paymentMethodConfig.type,
                sessionInfo: sessionInfo)
                        
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            
            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done{ paymentMethodTokenData in
                self.paymentMethodTokenData = paymentMethodTokenData
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
}
