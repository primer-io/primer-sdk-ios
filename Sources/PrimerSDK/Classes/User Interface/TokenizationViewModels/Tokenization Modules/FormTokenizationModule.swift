//
//  FormTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 18/10/22.
//

#if canImport(UIKit)

import Foundation

internal class Input {
    var name: String?
    var topPlaceholder: String?
    var textFieldPlaceholder: String?
    var keyboardType: UIKeyboardType?
    var allowedCharacterSet: CharacterSet?
    var maxCharactersAllowed: UInt?
    var isValid: ((_ text: String) -> Bool?)?
    var descriptor: String?
    var text: String? {
        return primerTextFieldView?.text
    }
    var primerTextFieldView: PrimerTextFieldView?
}

class FormTokenizationModule: TokenizationModule {
    
    // MARK: - Properties
    
    var didCancel: (() -> Void)?
    var userInputCompletion: (() -> Void)?
    
    override func validate() -> Promise<Void> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard decodedJWTToken.pciUrl != nil else {
                let err = PrimerError.invalidValue(key: "clientToken.pciUrl", value: decodedJWTToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if PrimerInternal.shared.intent == .checkout {
                if AppState.current.amount == nil {
                    let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if AppState.current.currency == nil {
                    let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
            }
            
            seal.fulfill()
        }
    }
    
    override func startFlow() -> Promise<PrimerPaymentMethodTokenData> {
        //        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedNotification(_:)), name: Notification.Name.urlSchemeRedirect, object: nil)
        
        return super.startFlow()
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: event)
        
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.paymentMethodModule.userInterfaceModule.makeIconImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
            firstly {
                self.validate()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodModule.paymentMethodConfiguration.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.paymentMethodModule.checkouEventsNotifierModule.fireWillPresentPaymentMethodUI()
            }
            .then { () -> Promise<Void> in
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.paymentMethodModule.checkouEventsNotifierModule.fireDidPresentPaymentMethodUI()
            }
            .then { () -> Promise<Void> in
                guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodModule.paymentMethodConfiguration.type) else {
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
                return self.firePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodModule.paymentMethodConfiguration.type))
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
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutTokenizationDidStart(for: self.paymentMethodModule.paymentMethodConfiguration.type)
            
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
        switch self.paymentMethodModule.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.adyenBlik.rawValue:
            return Promise { seal in
                
                guard let configId = self.paymentMethodModule.paymentMethodConfiguration.id else {
                    let err = PrimerError.invalidValue(key: "configuration.id", value: self.paymentMethodModule.paymentMethodConfiguration.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let blikCode = self.paymentMethodModule.userInterfaceModule.inputs?.first?.text else {
                    let err = PrimerError.invalidValue(key: "blikCode", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                let sessionInfo = BlikSessionInfo(
                    blikCode: blikCode,
                    locale: PrimerSettings.current.localeData.localeCode)
                
                let paymentInstrument = OffSessionPaymentInstrument(
                    paymentMethodConfigId: configId,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
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
            
        case PrimerPaymentMethodType.rapydFast.rawValue:
            return Promise { seal in
                guard let configId = self.paymentMethodModule.paymentMethodConfiguration.id else {
                    let err = PrimerError.invalidValue(key: "configuration.id", value: self.paymentMethodModule.paymentMethodConfiguration.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                let sessionInfo = WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
                
                let paymentInstrument = OffSessionPaymentInstrument(
                    paymentMethodConfigId: configId,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
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
            
            
        case PrimerPaymentMethodType.adyenMBWay.rawValue:
            return Promise { seal in
                
                guard let configId = self.paymentMethodModule.paymentMethodConfiguration.id else {
                    let err = PrimerError.invalidValue(key: "configuration.id", value: self.paymentMethodModule.paymentMethodConfiguration.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let phoneNumber = self.paymentMethodModule.userInterfaceModule.inputs?.first?.text else {
                    let err = PrimerError.invalidValue(key: "phoneNumber", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                let countryDialCode = CountryCode.phoneNumberCountryCodes.first(where: { $0.code == PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode?.rawValue})?.dialCode ?? ""
                let sessionInfo = InputPhonenumberSessionInfo(phoneNumber: "\(countryDialCode)\(phoneNumber)")
                
                let paymentInstrument = OffSessionPaymentInstrument(
                    paymentMethodConfigId: configId,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
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
            
        case PrimerPaymentMethodType.adyenMultibanco.rawValue:
            return Promise { seal in
                guard let configId = self.paymentMethodModule.paymentMethodConfiguration.id else {
                    let err = PrimerError.invalidValue(key: "configuration.id", value: self.paymentMethodModule.paymentMethodConfiguration.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                let sessionInfo = WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
                
                let paymentInstrument = OffSessionPaymentInstrument(
                    paymentMethodConfigId: configId,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
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
            
        default:
            fatalError("Payment method card should never end here.")
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    func presentPaymentMethodUserInterface() -> Promise<Void> {
        //        [.adyenBlik, .adyenMBWay, .adyenMultibanco]
        return Promise { seal in
            DispatchQueue.main.async {
                switch self.paymentMethodModule.paymentMethodConfiguration.type {
                case PrimerPaymentMethodType.adyenBlik.rawValue,
                    PrimerPaymentMethodType.adyenMBWay.rawValue:
                    
                    let pcfvc = PrimerInputViewController(
                        paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
                        userInterfaceModule: self.paymentMethodModule.userInterfaceModule,
                        inputsDistribution: .horizontal)
                    PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                    seal.fulfill()
                    
                    
                case PrimerPaymentMethodType.adyenMultibanco.rawValue:
                    let pcfvc = PrimerAccountInfoPaymentViewController(userInterfaceModule: self.paymentMethodModule.userInterfaceModule)
                    PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                    seal.fulfill()
                    
                default:
                    seal.fulfill()
                }
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
    
    @objc
    override func submitTokenizationData() {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .submit,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
        
        switch self.paymentMethodModule.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.adyenBlik.rawValue,
            PrimerPaymentMethodType.adyenMBWay.rawValue,
            PrimerPaymentMethodType.adyenMultibanco.rawValue:
            self.paymentMethodModule.userInterfaceModule.submitButton?.startAnimating()
            self.userInputCompletion?()
            
        default:
            fatalError("Must be overridden")
        }
    }
}

#endif

