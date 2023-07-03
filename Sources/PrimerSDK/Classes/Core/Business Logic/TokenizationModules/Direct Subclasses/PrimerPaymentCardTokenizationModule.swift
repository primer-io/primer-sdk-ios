//
//  PrimerPaymentCardTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

import Foundation

class PrimerPaymentCardTokenizationModule: PrimerTokenizationModule {
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            // Await user input
            //
            // Headless:
            //   1. Fulfills when merchant calls **submit()**
            //
            // Drop In:
            //   1. Presents card form
            //   2. Fulfills when submit button gets tapped.
        }
    }
    
    override func performTokenizationStep() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
//            guard let cardExpirationYear = cardExpirationYear,
//                  let expiryMonth = self.expiryDateField.expiryMonth else {
//                return nil
//            }
//
//            if isRequiringCVVInput {
//
//                let cardPaymentInstrument = CardPaymentInstrument(number: self.cardnumberField.cardnumber,
//                                                                  cvv: self.cvvField.cvv,
//                                                                  expirationMonth: expiryMonth,
//                                                                  expirationYear: cardExpirationYear,
//                                                                  cardholderName: self.cardholderField?.cardholderName)
//                return cardPaymentInstrument
//
//            } else if let configId = AppState.current.apiConfiguration?.getConfigId(for: self.primerPaymentMethodType.rawValue),
//                      let cardholderName = self.cardholderField?.cardholderName {
//
//                let cardOffSessionPaymentInstrument = CardOffSessionPaymentInstrument(paymentMethodConfigId: configId,
//                                                                                      paymentMethodType: self.primerPaymentMethodType.rawValue,
//                                                                                      number: self.cardnumberField.cardnumber,
//                                                                                      expirationMonth: expiryMonth,
//                                                                                      expirationYear: cardExpirationYear,
//                                                                                      cardholderName: cardholderName)
//                return cardOffSessionPaymentInstrument
//            }
//
//            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
//            let requestBody = Request.Body.Tokenization(paymentInstrument: tokenizationPaymentInstrument)
//            firstly {
//                return tokenizationService.tokenize(requestBody: requestBody)
//            }
//            .done { paymentMethodTokenData in
//                self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethodTokenData)
//            }
//            .catch { err in
//                let containerErr = PrimerError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
//                ErrorHandler.handle(error: containerErr)
//                self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [err])
//            }
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            
        }
    }
}
