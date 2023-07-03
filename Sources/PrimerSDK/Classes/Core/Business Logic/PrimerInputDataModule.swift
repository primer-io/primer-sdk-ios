//
//  PrimerDataInputModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/23.
//

#if canImport(UIKit)

import Foundation

class PrimerInputDataModule {
    
    private let paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
    }
    
    func awaitUserInput() -> Promise<PrimerInputDataProtocol> {
        fatalError("Needs to be overriden")
    }
}

#endif
