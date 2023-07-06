//
//  PrimerApplePayTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerApplePayTokenizationModule: PrimerTokenizationModule {
    
    private var applePayPaymentResponse: ApplePayPaymentResponse!
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
            
            firstly {
                self.paymentMethodOrchestrator.uiModule.presentPreTokenizationUI()
            }
            .then { () -> Promise<PrimerInputDataProtocol> in
                return self.paymentMethodOrchestrator.dataInputModule.awaitUserInput()
            }
            .done { applePayPaymentResponse in
                guard let applePayPaymentResponse = applePayPaymentResponse as? ApplePayPaymentResponse else {
                    fatalError()
                }
                
                self.applePayPaymentResponse = applePayPaymentResponse
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        return Promise { seal in
            let paymentInstrument = ApplePayPaymentInstrument(
                paymentMethodConfigId: self.paymentMethodOrchestrator.paymentMethodConfig.id!,
                sourceConfig: ApplePayPaymentInstrument.SourceConfig(
                    source: "IN_APP",
                    merchantId: PrimerSettings.current.paymentMethodOptions.applePayOptions!.merchantIdentifier),
                token: self.applePayPaymentResponse.token)
            seal.fulfill(paymentInstrument)
        }
    }
}

#endif
