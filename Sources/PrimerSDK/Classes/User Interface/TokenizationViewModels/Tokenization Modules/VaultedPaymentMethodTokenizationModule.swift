//
//  VaultedPaymentMethodTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 18/10/22.
//

#if canImport(UIKit)

import Foundation

class VaultedPaymentMethodTokenizationModule: TokenizationModule {
    
    var selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData
    
    init(paymentMethodModule: PaymentMethodModuleProtocol, selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData) {
        self.selectedPaymentMethodTokenData = selectedPaymentMethodTokenData
        super.init(paymentMethodModule: paymentMethodModule)
    }
    
    required init(paymentMethodModule: PaymentMethodModuleProtocol) {
        fatalError("init(paymentMethodModule:) has not been implemented")
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
    
    override func start() -> Promise<PrimerPaymentMethodTokenData> {
//        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedNotification(_:)), name: Notification.Name.urlSchemeRedirect, object: nil)
        
        return super.start()
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.dispatchActions(config: self.paymentMethodModule.paymentMethodConfiguration, selectedPaymentMethod: self.selectedPaymentMethodTokenData)
            }
            .then { () -> Promise<Void> in
                self.firePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodModule.paymentMethodConfiguration.type))
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.paymentMethodModule.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.paymentMethodModule.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
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
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    private func dispatchActions(config: PrimerPaymentMethod, selectedPaymentMethod: PrimerPaymentMethodTokenData) -> Promise<Void> {
        return Promise { seal in
            var network: String?
            if config.type == PrimerPaymentMethodType.paymentCard.rawValue {
                network = selectedPaymentMethod.paymentInstrumentData?.network?.uppercased()
                if network == nil || network == "UNKNOWN" {
                    network = "OTHER"
                }
            }
            
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            
            firstly {
                clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodModule.paymentMethodConfiguration.type, cardNetwork: network)
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
