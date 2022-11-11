//
//  CustomTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/11/22.
//

#if canImport(UIKit)

import Foundation

class CustomTokenizationModule: TokenizationModule {
    
    var userInputCompletion: (() -> Void)?
    
    override func validate() -> Promise<Void> {
        return Promise()
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
                place: .cardForm))
        Analytics.Service.record(event: event)
        
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.userInterfaceModule.makeIconImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
            firstly {
                self.validate()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodConfiguration.type, cardNetwork: nil)
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
                guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else {
                    return Promise()
                }
                
                switch paymentMethodType {
                case .adyenBlik,
                        .adyenMBWay,
                        .adyenMultibanco:
                    return self.awaitUserInput()
                default:
                    return Promise()
                }
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
    
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            guard let startScreen = self.paymentMethodConfiguration.implementation?.screens.first(where: { $0.id == "start_screen" }) else {
                return
            }
            
            let vc = PMF.ViewController(screen: startScreen, params: nil)
            PrimerUIManager.primerRootViewController?.show(viewController: vc)
            seal.fulfill()
            
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else {
                return
            }
            
            switch paymentMethodType {
            case .adyenBlik,
                    .adyenMBWay,
                    .adyenMultibanco:
                let payButton = startScreen.components.compactMap { pmfComponent in
                    switch pmfComponent {
                    case .button(let buttonComponent):
                        if buttonComponent.clickAction.type == .startPaymentFlow {
                            return buttonComponent
                        }

                    default:
                        break
                    }
                    
                    return nil
                    
                }.first
                
                payButton?.onStartFlow = {
                    self.userInputCompletion?()
                }
                
            default:
                break
            }
        }
    }
    
    func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.userInputCompletion = {
                seal.fulfill()
            }
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else {
                return
            }
            
            switch paymentMethodType {
            case .adyenMultibanco:
//                guard let configId = self.paymentMethodConfiguration.id else {
//                    let err = PrimerError.invalidValue(key: "configuration.id", value: self.paymentMethodConfiguration.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
//                    ErrorHandler.handle(error: err)
//                    seal.reject(err)
//                    return
//                }
                
                let sessionInfo = WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
                
                let paymentInstrument = OffSessionPaymentInstrument(
                    paymentMethodConfigId: "a15284a6-bbf2-47aa-add8-03b314441baf",
                    paymentMethodType: self.paymentMethodConfiguration.type,
                    sessionInfo: sessionInfo)
                
                let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
                let tokenizationService: TokenizationServiceProtocol = TokenizationService()
                
                firstly {
                    tokenizationService.tokenize(requestBody: requestBody)
                }
                .done{ paymentMethod in
                    seal.fulfill(paymentMethod)
                }
                .catch { err in
                    seal.reject(err)
                }
                
            default:
                fatalError()
            }
        }
    }
}
    
#endif
