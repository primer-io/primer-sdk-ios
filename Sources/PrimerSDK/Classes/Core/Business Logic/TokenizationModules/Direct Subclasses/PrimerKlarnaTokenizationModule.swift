//
//  PrimerKlarnaTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerKlarnaTokenizationModule: PrimerTokenizationModule {
    
    private var klarnaPaymentResponse: Response.Body.Klarna.CustomerToken!
    
    override func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        return Promise { seal in
            guard let klarnaCustomerToken = self.klarnaPaymentResponse?.customerTokenId else {
                let err = PrimerError.invalidValue(key: "tokenization.klarnaCustomerToken", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let sessionData = self.klarnaPaymentResponse?.sessionData else {
                let err = PrimerError.invalidValue(key: "tokenization.sessionData", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let paymentInstrument = KlarnaCustomerTokenPaymentInstrument(
                klarnaCustomerToken: klarnaCustomerToken,
                sessionData: sessionData)
            
            seal.fulfill(paymentInstrument)
        }
    }
}

#endif
