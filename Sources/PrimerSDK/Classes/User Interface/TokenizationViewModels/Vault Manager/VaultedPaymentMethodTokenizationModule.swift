//
//  VaultedPaymentMethodTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 18/10/22.
//

#if canImport(UIKit)

import Foundation

class VaultedPaymentMethodTokenizationModule: TokenizationModule {
    
    private(set) var selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData
    
    init(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: NewUserInterfaceModule,
        checkoutEventsNotifier: CheckoutEventsNotifierModule,
        selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData
    ) {
        self.selectedPaymentMethodTokenData = selectedPaymentMethodTokenData
        super.init(
            paymentMethodConfiguration: paymentMethodConfiguration,
            userInterfaceModule: userInterfaceModule,
            checkoutEventsNotifier: checkoutEventsNotifier)
    }
    
    required init(paymentMethodConfiguration: PrimerPaymentMethod, userInterfaceModule: NewUserInterfaceModule, checkoutEventsNotifier: CheckoutEventsNotifierModule) {
        fatalError("init(paymentMethodConfiguration:userInterfaceModule:checkoutEventsNotifier:) has not been implemented")
    }
    
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
        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(false)
        }

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
                place: .vaultManager))
        Analytics.Service.record(event: event)
        
        return Promise { seal in
            firstly {
                self.validate()
            }
            .then { () -> Promise<Void> in
                return self.dispatchActions()
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
        let tokenizationService = TokenizationService()
        return tokenizationService.exchangePaymentMethodToken(self.selectedPaymentMethodTokenData)
    }
    
    private func dispatchActions() -> Promise<Void> {
        return Promise { seal in
            var network: String?
            if self.paymentMethodConfiguration.type == PrimerPaymentMethodType.paymentCard.rawValue {
                network = self.selectedPaymentMethodTokenData.paymentInstrumentData?.network?.uppercased()
                if network == nil || network == "UNKNOWN" {
                    network = "OTHER"
                }
            }
            
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            
            firstly {
                clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodConfiguration.type, cardNetwork: network)
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
}

#endif
