//
//  PrimerIPay88TokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerIPay88TokenizationModule: PrimerTokenizationModule {
    
    override func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        return Promise { seal in
            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: self.paymentMethodOrchestrator.paymentMethodConfig.id!,
                paymentMethodType: self.paymentMethodOrchestrator.paymentMethodConfig.type,
                sessionInfo: IPay88SessionInfo(
                    refNo: UUID().uuidString,
                    locale: "en-US"))
            seal.fulfill(paymentInstrument)
        }
    }
}

#endif
