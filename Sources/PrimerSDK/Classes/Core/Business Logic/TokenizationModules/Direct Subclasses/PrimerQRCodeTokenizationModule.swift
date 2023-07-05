//
//  PrimerQRCodeTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerQRCodeTokenizationModule: PrimerTokenizationModule {
    
    override func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        return Promise { seal in
            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: self.paymentMethodOrchestrator.paymentMethodConfig.id!,
                paymentMethodType: self.paymentMethodOrchestrator.paymentMethodConfig.type,
                sessionInfo: WebRedirectSessionInfo(
                    locale: PrimerSettings.current.localeData.localeCode))
            seal.fulfill(paymentInstrument)
        }
    }
}

#endif
