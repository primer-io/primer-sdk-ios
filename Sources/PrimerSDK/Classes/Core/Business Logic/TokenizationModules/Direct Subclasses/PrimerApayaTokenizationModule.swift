//
//  PrimerApayaTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerApayaTokenizationModule: PrimerTokenizationModule {
    
    var apayaPaymentResponse: Apaya.WebViewResponse!
    
    override func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        return Promise { seal in
            let paymentInstrument = ApayaPaymentInstrument(
                mx: self.apayaPaymentResponse.mxNumber,
                mnc: self.apayaPaymentResponse.mnc,
                mcc: self.apayaPaymentResponse.mcc,
                hashedIdentifier: self.apayaPaymentResponse.hashedIdentifier,
                productId: self.apayaPaymentResponse.productId,
                currencyCode: AppState.current.currency!.rawValue)
            seal.fulfill(paymentInstrument)
        }
    }
}

#endif
