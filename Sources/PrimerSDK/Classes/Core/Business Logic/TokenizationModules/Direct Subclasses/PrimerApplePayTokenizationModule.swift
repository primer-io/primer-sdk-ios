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
