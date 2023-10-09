//
//  NolPayTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Boris on 28.8.23..
//
#if canImport(UIKit)

import Foundation

class NolPayTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    var mobileCountryCode: String!
    var mobileNumber: String!
    var nolPayCardNumber: String!
    var completion: (() -> Void)?
    
    override func validate() throws {
        
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let sessionInfo = NolPaySessionInfo(platform: "IOS", 
                                                mobileCountryCode: mobileCountryCode,
                                                mobileNumber: mobileNumber,
                                                nolPayCardNumber: nolPayCardNumber,
                                                phoneVendor: "Apple",
                                                phoneModel: UIDevice.modelIdentifier ?? "iPhone")
                
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
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    override func awaitUserInput() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        fatalError("\(#function) must be overriden")
        // kad ovo dekotiram dobijam transaction number
    }
    
    override func submitButtonTapped() {
        fatalError("\(#function) must be overriden")
    }
}
#endif
