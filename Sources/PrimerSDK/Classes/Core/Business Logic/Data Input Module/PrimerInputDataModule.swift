//
//  PrimerDataInputModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/23.
//

#if canImport(UIKit)

import Foundation

internal class PrimerInputDataModule {
    
    weak private(set) var paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator!
    internal var onInputDataSet: ((_ inputData: PrimerInputDataProtocol) -> Void)?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
    }
    
    func awaitUserInput() -> Promise<PrimerInputDataProtocol> {
        fatalError("Needs to be overriden")
    }
}

#endif
