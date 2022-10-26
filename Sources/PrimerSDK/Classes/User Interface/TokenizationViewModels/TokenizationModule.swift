//
//  TokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

protocol TokenizationModuleProtocol: NSObjectProtocol {
    
    var paymentMethodModule: PaymentMethodModuleProtocol! { get }
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    
    init(paymentMethodModule: PaymentMethodModuleProtocol)
    func startFlow() -> Promise<PrimerPaymentMethodTokenData>
    func validate() -> Promise<Void>
    func performPreTokenizationSteps() -> Promise<Void>
    func performTokenizationStep() -> Promise<Void>
    func tokenize() -> Promise<PrimerPaymentMethodTokenData>
    func performPostTokenizationSteps() -> Promise<Void>
    func submitTokenizationData()
    func cancel()
}

class TokenizationModule: NSObject, TokenizationModuleProtocol {

    weak var paymentMethodModule: PaymentMethodModuleProtocol!
    internal var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    
    required init(paymentMethodModule: PaymentMethodModuleProtocol) {
        self.paymentMethodModule = paymentMethodModule
        super.init()
    }
    
    func startFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                self.performPreTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                return self.performTokenizationStep()
            }
            .then { () -> Promise<Void> in
                return self.performPostTokenizationSteps()
            }
            .done {
                /// We can safely unwrap the **paymentMethodTokenData** since it has been
                /// checked on **performPostTokenizationSteps()**
                seal.fulfill(self.paymentMethodTokenData!)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func validate() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    func performPreTokenizationSteps() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    func performTokenizationStep() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        fatalError("\(#function) must be overriden")
    }
    
    func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            guard let paymentMethodTokenData = self.paymentMethodTokenData else {
                let err = PrimerError.invalidValue(key: "paymentMethodTokenData", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            seal.fulfill()
        }
    }
    
    func submitTokenizationData() {
        // Only applies on PMs that need a submit buton
        fatalError("\(#function) must be overriden")
    }
    
    func cancel() {
        
    }
    
    func firePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                seal.fulfill()
            } else {
                let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
                
                PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                    switch paymentCreationDecision.type {
                    case .abort(let errorMessage):
                        let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        seal.reject(error)
                    case .continue:
                        seal.fulfill()
                    }
                })
            }
        }
    }
}



#endif
