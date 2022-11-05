//
//  PrimerTestPaymentMethodTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

class PrimerTestPaymentMethodTokenizationModule: TokenizationModule {
    
    private var selectedDecision: PrimerTestPaymentMethodSessionInfo.FlowDecision!
    private var userInputCompletion: (() -> Void)?
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    override func validate() -> Promise<Void> {
        return Promise { seal in
            if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            } else {
                seal.fulfill()
            }
        }
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.paymentMethodConfiguration.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .bankSelectionList))
        Analytics.Service.record(event: event)
        
        return Promise { seal in
            firstly {
                self.validate()
            }
            .then { () -> Promise<Void> in
                return self.checkoutEventsNotifier.fireWillPresentPaymentMethodUI()
            }
            .then { () -> Promise<Void> in
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.checkoutEventsNotifier.fireDidPresentPaymentMethodUI()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                return self.firePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodConfiguration.type))
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let sessionInfo = PrimerTestPaymentMethodSessionInfo(flowDecision: selectedDecision)
            
            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: self.paymentMethodConfiguration.id!,
                paymentMethodType: self.paymentMethodConfiguration.type,
                sessionInfo: sessionInfo)
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            
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
    
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                
                (self.userInterfaceModule as? InputAndResultUserInterfaceModule)?.decisionSelectionCompletion = { decision in
                    self.selectedDecision = decision
                }
                
                let testPaymentMethodsVC = PrimerTestPaymentMethodViewController(
                    paymentMethodConfiguration: self.paymentMethodConfiguration,
                    userInterfaceModule: self.userInterfaceModule)
                
                PrimerUIManager.primerRootViewController?.show(viewController: testPaymentMethodsVC)
                seal.fulfill()
            }
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.userInputCompletion = {
                seal.fulfill()
            }
        }
    }
    
    @objc
    override func submitTokenizationData() {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.paymentMethodConfiguration.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .submit,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
        
        switch self.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.primerTestKlarna.rawValue,
            PrimerPaymentMethodType.primerTestPayPal.rawValue,
            PrimerPaymentMethodType.primerTestSofort.rawValue:
            if self.selectedDecision != nil {
                self.userInterfaceModule.submitButton?.startAnimating()
                self.userInputCompletion?()
                self.userInputCompletion = nil
            }
            
        default:
            fatalError("Must be overridden")
        }
    }
}

#endif
