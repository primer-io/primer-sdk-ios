//
//  VaultedPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/5/22.
//

#if canImport(UIKit)

import Foundation

class CheckoutWithVaultedPaymentMethodViewModel {
    
    var config: PrimerPaymentMethod
    var selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData
    var singleUsePaymentMethodTokenData: PrimerPaymentMethodTokenData?
    var paymentCheckoutData: PrimerCheckoutData?
    var successMessage: String?
    
    var resumePaymentId: String?
    
    // Events
    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: ((Error?) -> Void)?
    var didStartPayment: (() -> Void)?
    var didFinishPayment: ((Error?) -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    
    init(configuration: PrimerPaymentMethod, selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData) {
        self.config = configuration
        self.selectedPaymentMethodTokenData = selectedPaymentMethodTokenData
    }
    
    func start() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.startTokenizationFlow()
            }
            .then { paymentMethodTokenData -> Promise<PrimerCheckoutData?> in
                self.singleUsePaymentMethodTokenData = paymentMethodTokenData
                return self.startPaymentFlow(with: paymentMethodTokenData)
            }
            .done { checkoutData in
                if let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }
                
                self.handleSuccessfulFlow()
                seal.fulfill()
            }
            .catch { err in
                self.didFinishPayment?(err)
                
                var primerErr: PrimerError!
                if let error = err as? PrimerError {
                    primerErr = error
                } else {
                    primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: nil)
                }
                
                firstly {
                    PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                    seal.fulfill()
                }
                .catch { _ in }
            }
        }
    }
    
    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                self.dispatchActions(config: self.config, selectedPaymentMethod: self.selectedPaymentMethodTokenData)
            }
            .then { () -> Promise<Void> in
                self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<PaymentMethodToken> in
                self.exchangePaymentMethodToken(self.selectedPaymentMethodTokenData)
            }
            .done { singleUsePaymentMethodTokenData in
                seal.fulfill(singleUsePaymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func dispatchActions(config: PrimerPaymentMethod, selectedPaymentMethod: PaymentMethodToken) -> Promise<Void> {
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
                clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: network)
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
    internal func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if Primer.shared.intent == .vault {
                seal.fulfill()
            } else {
                let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
                
                PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                    switch paymentCreationDecision.type {
                    case .abort(let errorMessage):
                        let error = PrimerError.generic(message: errorMessage ?? "", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        seal.reject(error)
                    case .continue:
                        seal.fulfill()
                    }
                })
            }
        }
    }
    
    private func exchangePaymentMethodToken(_ paymentMethodToken: PaymentMethodToken) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
            client.exchangePaymentMethodToken(clientToken: decodedClientToken, paymentMethodId: paymentMethodToken.id!) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let singleUsePaymentMethod):
                        seal.fulfill(singleUsePaymentMethod)
                    case .failure(let error):
                        seal.reject(error)
                    }
                }
            }
        }
    }
    
    func startPaymentFlow(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            guard let tokenizationViewModel = PrimerAPIConfiguration.paymentMethodConfigs?.filter({ $0.type == config.type }).first?.tokenizationViewModel else {
                return
            }
            
            let paymentModule: PaymentModuleProtocol = PaymentModule(paymentMethodTokenizationViewModel: tokenizationViewModel)
            
            firstly {
                paymentModule.pay(with: paymentMethodTokenData)
            }
            .done { checkoutData in
                seal.fulfill(checkoutData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func handleSuccessfulFlow() {
        Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .success)
    }
    
    func handleFailureFlow(errorMessage: String?) {
        Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: errorMessage)
    }
}

#endif
