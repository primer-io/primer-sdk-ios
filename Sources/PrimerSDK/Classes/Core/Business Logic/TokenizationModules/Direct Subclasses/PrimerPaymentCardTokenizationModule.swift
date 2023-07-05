//
//  PrimerPaymentCardTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

import Foundation

class PrimerPaymentCardTokenizationModule: PrimerTokenizationModule {
    
    private var isRequiringCVVInput: Bool = false
    private var cardNumber: String?
    private var expiryMonth: String?
    private var expiryYear: String?
    private var cvv: String?
    private var cardholderName: String?
    
    override func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        return Promise { seal in
            guard let cardNumber = self.cardNumber else {
                let err = PrimerError.invalidValue(
                    key: "cardNumber",
                    value: nil,
                    userInfo: nil,
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let expiryMonth = self.expiryMonth,
                  let expiryYear = self.expiryYear else {
                let err = PrimerError.invalidValue(
                    key: "Expiry date",
                    value: nil,
                    userInfo: nil,
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if self.isRequiringCVVInput {
                guard let cvv = self.cvv else {
                    let err = PrimerError.invalidValue(
                        key: "cvv",
                        value: nil,
                        userInfo: nil,
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                let paymentInstrument = CardPaymentInstrument(number: cardNumber,
                                                              cvv: cvv,
                                                              expirationMonth: expiryMonth,
                                                              expirationYear: expiryYear,
                                                              cardholderName: self.cardholderName)
                seal.fulfill(paymentInstrument)
                
            } else if let configId = AppState.current.apiConfiguration?.getConfigId(for: self.paymentMethodOrchestrator.paymentMethodConfig.type) {
                guard let cardholderName = self.cardholderName else {
                    let err = PrimerError.invalidValue(
                        key: "cardholderName",
                        value: nil,
                        userInfo: nil,
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                let paymentInstrument = CardOffSessionPaymentInstrument(paymentMethodConfigId: configId,
                                                                        paymentMethodType: self.paymentMethodOrchestrator.paymentMethodConfig.type,
                                                                        number: cardNumber,
                                                                        expirationMonth: expiryMonth,
                                                                        expirationYear: expiryYear,
                                                                        cardholderName: cardholderName)
                seal.fulfill(paymentInstrument)
            }
        }
    }
}
