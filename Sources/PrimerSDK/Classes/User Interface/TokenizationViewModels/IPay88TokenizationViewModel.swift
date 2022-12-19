//
//  IPay88TokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/12/22.
//

#if canImport(UIKit)

import Foundation
import UIKit

#if canImport(PrimerIPay88SDK)
import PrimerIPay88SDK
#endif

class IPay88TokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self.self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
#if canImport(PrimerIPay88SDK)
    private var backendCallbackUrl: URL!
    private var primerTransactionId: String!
    private var statusUrl: URL!
    private var resumeToken: String!
    private var primerIPay88ViewController: PrimerIPay88ViewController!
    private var primerIPay88Payment: PrimerIPay88Payment!
    private var didComplete: (() -> Void)?
    private var didFail: ((_ err: PrimerError) -> Void)?
#endif
    
    private lazy var iPay88NumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.decimalSeparator = "."
        numberFormatter.groupingSeparator = ","
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        return numberFormatter
    }()
    
    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            let err = PrimerError.invalidClientToken(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        var errors: [PrimerError] = []
        
        // Merchant info
        
        if self.config.id == nil {
            let err = PrimerError.invalidValue(
                key: "configuration.id",
                value: config.id,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (self.config.options as? MerchantOptions)?.merchantId == nil {
            let err = PrimerError.invalidValue(
                key: "configuration.merchantId",
                value: config.id,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        // Amount & currency validation
        
        if AppState.current.amount == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "amount",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if AppState.current.currency != .MYR {
            let err = PrimerError.invalidClientSessionValue(
                name: "currencyCode",
                value: AppState.current.currency?.rawValue,
                allowedValue: "MYR",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        // Order validation
        
        if PrimerAPIConfiguration.current?.clientSession?.order?.id == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "order.id",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if PrimerAPIConfiguration.current?.clientSession?.order?.countryCode != .my {
            let err = PrimerError.invalidClientSessionValue(
                name: "order.countryCode",
                value: nil,
                allowedValue: "MY",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (PrimerAPIConfiguration.current?.clientSession?.order?.lineItems ?? []).count == 0 {
            let err = PrimerError.invalidClientSessionValue(
                name: "order.lineItems",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
            
        } else {
            let productsDescription = PrimerAPIConfiguration.current?.clientSession?.order?.lineItems?.compactMap({ $0.name ?? $0.description }).joined(separator: ", ")
            
            if productsDescription == nil {
                let err = PrimerError.invalidClientSessionValue(
                    name: "order.lineItems.description",
                    value: nil,
                    allowedValue: nil,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                errors.append(err)
            }
        }
        
        // Customer validation
        
        if PrimerAPIConfiguration.current?.clientSession?.customer?.firstName == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.firstName",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if PrimerAPIConfiguration.current?.clientSession?.customer?.lastName == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.lastName",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if PrimerAPIConfiguration.current?.clientSession?.customer?.emailAddress == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.emailAddress",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if PrimerAPIConfiguration.current?.clientSession?.customer?.mobileNumber == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.mobileNumber",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
#if !canImport(PrimerIPay88SDK)
        let err = PrimerError.missingSDK(
            sdkName: "PrimerIPay88SDK",
            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
            diagnosticsId: nil)
        ErrorHandler.handle(error: err)
        errors.append(err)
#endif
        
        if errors.count == 1 {
            throw errors.first!
            
        } else if errors.count > 1 {
            let err = PrimerError.underlyingErrors(
                errors: errors,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .paymentMethodPopup))
        Analytics.Service.record(event: event)
        
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
#if canImport(PrimerIPay88SDK)
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                seal.fulfill()
            }
            .ensure {

            }
            .catch { err in
                seal.reject(err)
            }
            
#else
            let err = PrimerError.missingSDK(
                sdkName: "PrimerIPay88SDK",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
#endif
        }
    }
    
    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
#if canImport(PrimerIPay88SDK)
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)
            
            firstly {
                self.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
            
#else
            let err = PrimerError.missingSDK(
                sdkName: "PrimerIPay88SDK",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
#endif
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
#if canImport(PrimerIPay88SDK)
            seal.fulfill()
            
#else
            let err = PrimerError.missingSDK(
                sdkName: "PrimerIPay88SDK",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
#endif
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
#if canImport(PrimerIPay88SDK)
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let sessionInfo = IPay88SessionInfo(refNo: UUID().uuidString, locale: "en-US")
            
            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: configId,
                paymentMethodType: config.type,
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
            
#else
            let err = PrimerError.missingSDK(
                sdkName: "PrimerIPay88SDK",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
#endif
        }
    }
    
    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
#if canImport(PrimerIPay88SDK)
            if decodedJWTToken.intent == "IPAY88_CARD_REDIRECTION" {
                guard let backendCallbackUrlStr = decodedJWTToken.backendCallbackUrl?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPasswordAllowed)?.replacingOccurrences(of: "=", with: "%3D"),
                      let backendCallbackUrl = URL(string: backendCallbackUrlStr),
                      let statusUrlStr = decodedJWTToken.statusUrl,
                      let statusUrl = URL(string: statusUrlStr),
                      let primerTransactionId = decodedJWTToken.primerTransactionId
                else {
                    let err = PrimerError.invalidClientToken(
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                DispatchQueue.main.async {
                    PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                }
                
                self.backendCallbackUrl = backendCallbackUrl
                self.primerTransactionId = primerTransactionId
                self.statusUrl = statusUrl
                
                self.primerIPay88Payment = self.createPrimerIPay88Payment()
                
                firstly {
                    self.presentPaymentMethodUserInterface()
                }
                .then { () -> Promise<Void> in
                    return self.awaitUserInput()
                }
                .done {
                    seal.fulfill(self.resumeToken)
                }
                .catch { err in
                    seal.reject(err)
                }
                
            } else {
                seal.fulfill(nil)
            }
            
#else
            let err = PrimerError.missingSDK(
                sdkName: "PrimerIPay88SDK",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
#endif
        }
    }
    
#if canImport(PrimerIPay88SDK)
    private func createPrimerIPay88Payment() -> PrimerIPay88Payment {
        let amountStr = self.iPay88NumberFormatter.string(from: NSNumber(value: Double(AppState.current.amount!)/100))
        
        return PrimerIPay88Payment(
            amount: amountStr!,
            currency: "MYR",
            paymentId: "2", // 2: iPay88 Card Payment
            merchantKey: self.config.id!,
            merchantCode: (self.config.options as! MerchantOptions).merchantId,
            refNo: self.primerTransactionId,
            prodDesc: PrimerAPIConfiguration.current!.clientSession!.order!.lineItems!.compactMap({ $0.description }).joined(separator: ", "),
            userName: "\(PrimerAPIConfiguration.current!.clientSession!.customer!.firstName!) \(PrimerAPIConfiguration.current!.clientSession!.customer!.lastName!)",
            userEmail: PrimerAPIConfiguration.current!.clientSession!.customer!.emailAddress!,
            userContact: PrimerAPIConfiguration.current!.clientSession!.customer!.mobileNumber!,
            country: "MY",
            backendPostURL: self.backendCallbackUrl!.absoluteString,
            remark: nil,
            lang: "UTF-8")
    }

    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.primerIPay88ViewController = PrimerIPay88ViewController(delegate: self, payment: self.primerIPay88Payment!)

                if #available(iOS 13.0, *) {
                    self.primerIPay88ViewController.isModalInPresentation = true
                    self.primerIPay88ViewController.modalPresentationStyle = .fullScreen
                }

                self.willPresentPaymentMethodUI?()
                PrimerUIManager.primerRootViewController?.present(self.primerIPay88ViewController, animated: true, completion: {
                    DispatchQueue.main.async {
                        PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod?(for: self.config.type)
                        self.didPresentPaymentMethodUI?()
                        seal.fulfill()
                    }
                })
                
                self.didComplete = { [unowned self] in
                    DispatchQueue.main.async { [unowned self] in
                        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                        self.primerIPay88ViewController?.dismiss(animated: true, completion: {
                            
                        })
                    }
                }
            }
        }
    }
    
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            let pollingModule = PollingModule(url: self.statusUrl)
            self.didCancel = {
                let err = PrimerError.cancelled(
                    paymentMethodType: self.config.type,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                pollingModule.cancel(withError: err)
            }
            
            self.didFail = { err in
                pollingModule.fail(withError: err)
            }
            
            firstly {
                pollingModule.start()
            }
            .done { resumeToken in
                self.resumeToken = resumeToken
                seal.fulfill()
            }
            .ensure {
                DispatchQueue.main.async { [unowned self] in
                    self.primerIPay88ViewController?.dismiss(animated: true, completion: {
                        
                    })
                }
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func nullifyCallbacks() {
        self.didCancel = nil
        self.didComplete = nil
        self.didFail = nil
    }
#endif
}

#if canImport(PrimerIPay88SDK)
extension IPay88TokenizationViewModel: PrimerIPay88ViewControllerDelegate {
    
    func primerIPay88ViewDidLoad() {
        
    }
    
    func primerIPay88PaymentSessionCompleted(payment: PrimerIPay88SDK.PrimerIPay88Payment?, error: PrimerIPay88SDK.PrimerIPay88Error?) {
        if let payment {
            self.primerIPay88Payment = payment
        }
        
        if let error {
            switch error {
            case .iPay88Error(let description, _):
                let err = PrimerError.paymentFailed(
                    description: "iPay88 payment (transId: \(self.primerIPay88Payment.transId ?? "nil"), refNo: \(self.primerIPay88Payment.refNo ) failed with error '\(description)'",
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                self.didFail?(err)
                self.nullifyCallbacks()
            }
            
        } else {
            self.didComplete?()
            self.nullifyCallbacks()
        }
    }
    
    func primerIPay88PaymentCancelled(payment: PrimerIPay88SDK.PrimerIPay88Payment?, error: PrimerIPay88SDK.PrimerIPay88Error?) {
        self.didCancel?()
        self.nullifyCallbacks()
    }
}
#endif

#endif

