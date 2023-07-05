//
//  PrimerTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/23.
//

#if canImport(UIKit)

import Foundation

internal class PrimerTokenizationModule {
    
    internal let paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator
    internal var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
    }
    
    final internal func start() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            self.paymentMethodOrchestrator.eventEmitter.fireWillStartTokenizationEvent()
            
            firstly {
                self.selectPaymentMethodForClientSessionActionsIfNeeded()
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodOrchestrator.paymentMethodConfig.type))
            }
            .then { () -> Promise<Void> in
                return self.performPreTokenizationSteps()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.performTokenizationStep()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodOrchestrator.eventEmitter.fireDidFinishTokenizationEvent()
                return self.performPostTokenizationSteps()
            }
            .done {
                seal.fulfill(self.paymentMethodTokenData!)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    internal func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            self.paymentMethodOrchestrator.eventEmitter.fireWillStartTokenizationEvent()
            seal.fulfill()
        }
    }
    
    final private func performTokenizationStep() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                self.generatePaymentInstrument()
            }
            .then { paymentInstrument -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize(paymentInstrument: paymentInstrument)
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
    
    internal func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        fatalError("\(#function) must be overriden")
    }
    
    final private func tokenize(paymentInstrument: TokenizationRequestBodyPaymentInstrument) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            
            let tokenizationService = TokenizationService()
            
            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    internal func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            self.paymentMethodOrchestrator.eventEmitter.fireDidFinishTokenizationEvent()
            seal.fulfill()
        }
    }
    
    final private func selectPaymentMethodForClientSessionActionsIfNeeded() -> Promise<Void> {
        return Promise { seal in
            // FIXME: Make a check if there's a client session action in the client session
            
            let clientSessionActionsModule = ClientSessionActionsModule()
            
            firstly {
                clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodOrchestrator.paymentMethodConfig.type, cardNetwork: nil)
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    final private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                seal.fulfill()
            } else {
                let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
                
                var decisionHandlerHasBeenCalled = false
                
                PrimerDelegateProxy.primerWillCreatePaymentWithData(
                    checkoutPaymentMethodData,
                    decisionHandler: { paymentCreationDecision in
                        decisionHandlerHasBeenCalled = true
                        switch paymentCreationDecision.type {
                        case .abort(let errorMessage):
                            let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                            seal.reject(error)
                        case .continue:
                            seal.fulfill()
                        }
                    })
                
                Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                    if !decisionHandlerHasBeenCalled {
                        print("PRIMER SDK\nWARNING!\nThe 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. Make sure you call the decision handler otherwise the SDK will hang.")
                    }
                }
            }
        }
    }
}

#endif
