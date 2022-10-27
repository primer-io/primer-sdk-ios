//
//  PayPalTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import AuthenticationServices
import Foundation
import SafariServices
import UIKit

class PayPalTokenizationModule: TokenizationModule {
    
    private var orderId: String?
    private var session: Any!
    private var payPalInstrument: PayPalPaymentInstrument!
    private var confirmBillingAgreementResponse: Response.Body.PayPal.ConfirmBillingAgreement?
    
    override func validate() -> Promise<Void> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard decodedJWTToken.pciUrl != nil else {
                let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedJWTToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard self.paymentMethodConfiguration.id != nil else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: self.paymentMethodConfiguration.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard decodedJWTToken.coreUrl != nil else {
                let err = PrimerError.invalidValue(key: "decodedClientToken.coreUrl", value: decodedJWTToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            seal.fulfill()
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
                place: .paymentMethodPopup))
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
                return self.firePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodConfiguration.type))
            }
            .then { () -> Promise<Void> in
                return self.checkoutEventsNotifier.fireWillPresentPaymentMethodUI()
            }
            .then { () -> Promise<Void> in
                self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.checkoutEventsNotifier.fireDidPresentPaymentMethodUI()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
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
        let requestBody = Request.Body.Tokenization(paymentInstrument: self.payPalInstrument)
        let tokenizationService: TokenizationServiceProtocol = TokenizationService()
        return tokenizationService.tokenize(requestBody: requestBody)
    }
    
    // MARK: - PAYPAL SPECIFIC FUNCTIONALITY
    
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.fetchOAuthURL()
            }
            .then { url -> Promise<URL> in
//                self.willPresentExternalView?()
                return self.createOAuthSession(url)
            }
            .done { url  in
//                self.didPresentExternalView?()
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func fetchOAuthURL() -> Promise<URL> {
        return Promise { seal in
            let paypalService: PayPalServiceProtocol = PayPalService()
            
            switch PrimerInternal.shared.intent {
            case .checkout:
                paypalService.startOrderSession { result in
                    switch result {
                    case .success(let res):
                        guard let url = URL(string: res.approvalUrl) else {
                            let err = PrimerError.invalidValue(key: "res.approvalUrl", value: res.approvalUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        self.orderId = res.orderId
                        seal.fulfill(url)
                        
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
                
            case .vault:
                paypalService.startBillingAgreementSession { result in
                    switch result {
                    case .success(let urlStr):
                        guard let url = URL(string: urlStr) else {
                            let err = PrimerError.invalidValue(key: "billingAgreement.response.url", value: urlStr, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        seal.fulfill(url)
                        
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            case .none:
                assert(true, "Intent should already be set")
            }
        }
    }
    
    private func createOAuthSession(_ url: URL) -> Promise<URL> {
        return Promise { seal in
            guard var urlScheme = PrimerSettings.current.paymentMethodOptions.urlScheme else {
                let err = PrimerError.invalidValue(key: "settings.paymentMethodOptions.urlScheme", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if urlScheme.contains("://")  {
                urlScheme = urlScheme.components(separatedBy: "://").first!
            }
            
            if #available(iOS 13, *) {
                let webAuthSession = ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: urlScheme,
                    completionHandler: { [weak self] (url, error) in
                        if let error = error {
                            seal.reject(error)
                            
                        } else if let url = url {
                            seal.fulfill(url)
                        }

                        (self?.session as? ASWebAuthenticationSession)?.cancel()
                    }
                )
                session = webAuthSession
                
                webAuthSession.presentationContextProvider = self
                webAuthSession.start()
                
            } else if #available(iOS 11, *) {
                session = SFAuthenticationSession(
                    url: url,
                    callbackURLScheme: urlScheme,
                    completionHandler: { (url, err) in
                        if let err = err {
                            seal.reject(err)
                            
                        } else if let url = url {
                            seal.fulfill(url)
                        }
                    }
                )

                (self.session as? SFAuthenticationSession)?.start()
            }
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.createPaypalPaymentInstrument()
            }
            .done { instrument in
                self.payPalInstrument = instrument
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func createPaypalPaymentInstrument() -> Promise<PayPalPaymentInstrument> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                firstly {
                    self.generateBillingAgreementConfirmation()
                }
                .done { billingAgreement in
                    let paymentInstrument = PayPalPaymentInstrument(
                        paypalOrderId: nil,
                        paypalBillingAgreementId: billingAgreement.billingAgreementId,
                        shippingAddress: billingAgreement.shippingAddress,
                        externalPayerInfo: billingAgreement.externalPayerInfo)

                    seal.fulfill(paymentInstrument)
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                guard let orderId = orderId else {
                    let err = PrimerError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                firstly {
                    self.fetchPayPalExternalPayerInfo(orderId: orderId)
                }
                .then { res -> Promise<PayPalPaymentInstrument> in
                    return self.generatePaypalPaymentInstrument(externalPayerInfo: res.externalPayerInfo)
                }
                .done { response in
                    self.generatePaypalPaymentInstrument(externalPayerInfo: response.externalPayerInfo) { result in
                        switch result {
                        case .success(let paymentInstrument):
                            seal.fulfill(paymentInstrument)
                        case .failure(let err):
                            seal.reject(err)
                        }
                    }
                }
                .catch { err in
                    seal.reject(err)
                }
            }
            
        }
    }
    
    private func generatePaypalPaymentInstrument(externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?) -> Promise<PayPalPaymentInstrument> {
        return Promise { seal in
            self.generatePaypalPaymentInstrument(externalPayerInfo: externalPayerInfo) { result in
                switch result {
                case .success(let paymentInstrument):
                    seal.fulfill(paymentInstrument)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generatePaypalPaymentInstrument(externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?, completion: @escaping (Result<PayPalPaymentInstrument, Error>) -> Void) {
        switch PrimerInternal.shared.intent {
        case .checkout:
            guard let orderId = orderId else {
                let err = PrimerError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            guard let externalPayerInfo = externalPayerInfo else {
                let err = PrimerError.invalidValue(key: "externalPayerInfo", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            let paymentInstrument = PayPalPaymentInstrument(
                paypalOrderId: orderId,
                paypalBillingAgreementId: nil,
                shippingAddress: nil,
                externalPayerInfo: externalPayerInfo)
            
            completion(.success(paymentInstrument))
            
        case .vault:
            guard let confirmedBillingAgreement = self.confirmBillingAgreementResponse else {
                let err = PrimerError.invalidValue(key: "confirmedBillingAgreement", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            let paymentInstrument = PayPalPaymentInstrument(
                paypalOrderId: nil,
                paypalBillingAgreementId: confirmedBillingAgreement.billingAgreementId,
                shippingAddress: confirmedBillingAgreement.shippingAddress,
                externalPayerInfo: confirmedBillingAgreement.externalPayerInfo)
            
            completion(.success(paymentInstrument))
            
        case .none:
            precondition(false, "Intent should have been set.")
        }
    }
    
    private func generateBillingAgreementConfirmation() -> Promise<Response.Body.PayPal.ConfirmBillingAgreement> {
        return Promise { seal in
            let paypalService: PayPalServiceProtocol = PayPalService()
            paypalService.confirmBillingAgreement({ result in
                switch result {
                case .failure(let err):
                    let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(containerErr)
                    
                case .success(let res):
                    self.confirmBillingAgreementResponse = res
                    seal.fulfill(res)
                }
            })
        }
    }
    
    private func fetchPayPalExternalPayerInfo(orderId: String) -> Promise<Response.Body.PayPal.PayerInfo> {
        return Promise { seal in
            let paypalService: PayPalServiceProtocol = PayPalService()
            paypalService.fetchPayPalExternalPayerInfo(orderId: orderId) { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
}

@available(iOS 11.0, *)
extension PayPalTokenizationModule: ASWebAuthenticationPresentationContextProviding {
    
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
}

#endif
