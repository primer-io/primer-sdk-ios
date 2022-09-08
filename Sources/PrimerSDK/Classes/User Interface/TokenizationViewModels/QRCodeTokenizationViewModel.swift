//
//  QRCodeTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/1/22.
//

#if canImport(UIKit)

import SafariServices
import UIKit

class QRCodeTokenizationViewModel: ExternalPaymentMethodTokenizationViewModel {
    
    private var tokenizationService: TokenizationServiceProtocol?
    private var statusUrl: URL!
    internal var qrCode: String?
    private var resumeToken: String!
    
    deinit {
        tokenizationService = nil
        qrCode = nil
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
                place: .bankSelectionList))
        Analytics.Service.record(event: event)
        
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
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
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutTokenizationDidStart(for: self.config.type)
            
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
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                let qrcvc = QRCodeViewController(viewModel: self)
                self.willPresentPaymentMethodUI?()
                Primer.shared.primerRootVC?.show(viewController: qrcvc)
                self.didPresentPaymentMethodUI?()
                seal.fulfill(())
            }
        }
    }
    
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            let pollingModule = PollingModule(url: statusUrl)
            self.didCancel = {
                pollingModule.cancel()
                return
            }
            
            firstly {
                pollingModule.start()
            }
            .done { resumeToken in
                self.resumeToken = resumeToken
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func cancel() {
        didCancel?()
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let sessionInfo = WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
            
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
        }
    }
    
    override func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?> {
        return Promise { seal in
            if let statusUrlStr = decodedClientToken.statusUrl,
               let statusUrl = URL(string: statusUrlStr),
               decodedClientToken.intent != nil {
                
                self.statusUrl = statusUrl
                self.qrCode = decodedClientToken.qrCode
                
                firstly {
                    self.evaluateFireDidReceiveAdditionalInfoEvent()
                }
                .then { () -> Promise<Void> in
                    self.evaluatePresentUserInterface()
                }
                .then { () -> Promise<Void> in
                    return self.awaitUserInput()
                }
                .done { () in
                    seal.fulfill(self.resumeToken)
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(error)
            }
        }
    }
}

extension QRCodeTokenizationViewModel {
    
    private func evaluatePresentUserInterface() -> Promise<Void> {
        return Promise { seal in
            
            guard PrimerSettings.current.paymentHandling == .auto else {
                seal.fulfill()
                return
            }
            
            _ = self.presentPaymentMethodUserInterface()
            seal.fulfill()
        }
    }
    
    private func evaluateFireDidReceiveAdditionalInfoEvent() -> Promise<Void> {
        return Promise { seal in
            
            let isHeadlessCheckoutDelegateImplemented = PrimerHeadlessUniversalCheckout.current.delegate != nil
            let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
            var additionalInfo: PrimerCheckoutAdditionalInfo?
            
            switch self.config.type {
            case PrimerPaymentMethodType.rapydPromptPay.rawValue,
                PrimerPaymentMethodType.omisePromptPay.rawValue:
                
                guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let expiresAt = decodedClientToken.expiresAt else {
                    let err = PrimerError.invalidValue(key: "decodedClientToken.expiresAt", value: decodedClientToken.expiresAt, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let qrCodeString = decodedClientToken.qrCode,
                      let qrCodeUrl = URL(string: qrCodeString) else {
                    let err = PrimerError.invalidValue(key: "decodedClientToken.qrCode", value: decodedClientToken.qrCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                additionalInfo = PromptPayCheckoutAdditionalInfo(expiresAt: expiresAt,
                                                                 qrCodeUrl: qrCodeUrl)
            default:
                log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD RESULT", message: self.config.type, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)
                break
            }
            
            if isManualPaymentHandling {
                
                if let additionalInfo = additionalInfo {
                    PrimerDelegateProxy.primerDidReceiveAdditionalInfo(additionalInfo)
                    seal.fulfill()
                } else {
                    let err = PrimerError.invalidValue(key: "additionalInfo", value: additionalInfo, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            } else {
                seal.fulfill()
            }
        }
    }
}

#endif

