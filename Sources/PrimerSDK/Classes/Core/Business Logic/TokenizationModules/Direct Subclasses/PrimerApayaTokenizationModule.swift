//
//  PrimerApayaTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerApayaTokenizationModule: PrimerTokenizationModule {
    
    override func performTokenizationStep() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            let paymentInstrument = ApayaPaymentInstrument(
                mx: "",
                mnc: "",
                mcc: "",
                hashedIdentifier: "",
                productId: "",
                currencyCode: "")
            
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            
            let tokenizationService = TokenizationService()
            
            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethodTokenData in
                self.paymentMethodTokenData = paymentMethodTokenData
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
}

#endif
