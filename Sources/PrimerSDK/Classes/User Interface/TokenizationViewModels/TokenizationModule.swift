//
//  TokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

protocol TokenizationModuleProtocol: NSObjectProtocol {
        
    init(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: NewUserInterfaceModule,
        checkoutEventsNotifier: CheckoutEventsNotifierModule)
    
    func startFlow() -> Promise<PrimerPaymentMethodTokenData>
    func validate() -> Promise<Void>
    func performPreTokenizationSteps() -> Promise<Void>
    func performTokenizationStep() -> Promise<PrimerPaymentMethodTokenData>
    func tokenize() -> Promise<PrimerPaymentMethodTokenData>
    func performPostTokenizationSteps() -> Promise<Void>
    func submitTokenizationData()
    func cancel()
}

class TokenizationModule: NSObject, TokenizationModuleProtocol {
    
    weak var paymentMethodConfiguration: PrimerPaymentMethod!
    weak var userInterfaceModule: NewUserInterfaceModule!
    weak var checkoutEventsNotifier: CheckoutEventsNotifierModule!
    
    required init(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: NewUserInterfaceModule,
        checkoutEventsNotifier: CheckoutEventsNotifierModule
    ) {
        self.paymentMethodConfiguration = paymentMethodConfiguration
        self.userInterfaceModule = userInterfaceModule
        self.checkoutEventsNotifier = checkoutEventsNotifier
        super.init()
    }
    
    func startFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            var tmpPaymentMethodTokenData: PrimerPaymentMethodTokenData!
            
            firstly {
                self.performPreTokenizationSteps()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.performTokenizationStep()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                tmpPaymentMethodTokenData = paymentMethodTokenData
                return self.performPostTokenizationSteps()
            }
            .done {
                seal.fulfill(tmpPaymentMethodTokenData)
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
    
    func performTokenizationStep() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            var tmpPaymentMethodTokenData: PrimerPaymentMethodTokenData!
            
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutTokenizationDidStart(for: self.paymentMethodConfiguration.type)
            
            firstly {
                self.checkoutEventsNotifier.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                tmpPaymentMethodTokenData = paymentMethodTokenData
                return self.checkoutEventsNotifier.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill(tmpPaymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        fatalError("\(#function) must be overriden")
    }
    
    func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
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
