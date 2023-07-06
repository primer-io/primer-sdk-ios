//
//  PrimerApplePayDataInputModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

@available(iOS 11.0, *)
class PrimerApplePayInputDataModule: PrimerInputDataModule {
    
    override func awaitUserInput() -> Promise<PrimerInputDataProtocol> {
        return Promise { seal in
            guard let applePayUIModule = self.paymentMethodOrchestrator.uiModule as? PrimerApplePayUIModule else {
                fatalError()
            }
            
            applePayUIModule.applePayReceiveDataCompletion = { [weak self] result in
                switch result {
                case .success(let applePayPaymentResponse):
                    seal.fulfill(applePayPaymentResponse)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
}

#endif
