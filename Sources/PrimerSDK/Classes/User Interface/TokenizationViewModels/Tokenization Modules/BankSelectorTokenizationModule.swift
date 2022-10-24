//
//  BankSelectorTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

class BankSelectorTokenizationModule: TokenizationModule {
    
    private var banks: [AdyenBank] = []
    private var bankSelectionCompletion: ((AdyenBank) -> Void)?
    private var selectedBank: AdyenBank?
    
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
    
    override func startFlow() -> Promise<PrimerPaymentMethodTokenData> {
//        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedNotification(_:)), name: Notification.Name.urlSchemeRedirect, object: nil)
        
        return super.startFlow()
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
        }
        
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
                place: .bankSelectionList))
        Analytics.Service.record(event: event)
        
        return Promise { seal in
            firstly {
                self.validate()
            }
            .then { () -> Promise<Void> in
                return self.paymentMethodModule.checkouEventsNotifierModule.fireWillPresentPaymentMethodUI()
            }
            .then { () -> Promise<[AdyenBank]> in
                self.fetchBanks()
            }
            .then { banks -> Promise<Void> in
                self.banks = banks
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.paymentMethodModule.checkouEventsNotifierModule.fireDidPresentPaymentMethodUI()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                DispatchQueue.main.async {
                    PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
                        imageView: self.paymentMethodModule.userInterfaceModule.makeIconImageView(withDimension: 24.0),
                        message: nil)
                }
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
        return Promise { seal in
            guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            let requestBody = Request.Body.Tokenization(
                paymentInstrument: OffSessionPaymentInstrument(
                    paymentMethodConfigId: self.paymentMethodModule.paymentMethodConfiguration.id!,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
                    sessionInfo: BankSelectorSessionInfo(issuer: self.selectedBank!.id)))
            
            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethodTokenData in
                self.paymentMethodTokenData = paymentMethodTokenData
                seal.fulfill(paymentMethodTokenData)
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
    
    // MARK: - BANK SELECTOR SPECIFIC FUNCTIONALITY
    
    private func fetchBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            var paymentMethodRequestValue: String = ""
            switch self.paymentMethodModule.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.adyenDotPay.rawValue:
                paymentMethodRequestValue = "dotpay"
            case PrimerPaymentMethodType.adyenIDeal.rawValue:
                paymentMethodRequestValue = "ideal"
            default:
                break
            }
                    
            let request = Request.Body.Adyen.BanksList(
                paymentMethodConfigId: self.paymentMethodModule.paymentMethodConfiguration.id!,
                parameters: BankTokenizationSessionRequestParameters(paymentMethod: paymentMethodRequestValue))
            
            let apiClient: PrimerAPIClientProtocol = PaymentMethodModule.apiClient ?? PrimerAPIClient()
            
            apiClient.listAdyenBanks(clientToken: decodedJWTToken, request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let banks):
                    seal.fulfill(banks)
                }
            }
        }
    }
    
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                let bsvc = self.paymentMethodModule.userInterfaceModule.createBanksSelectorViewController(with: self.banks)
                
                bsvc.didSelectBank = { [weak self] bank in
                    self?.selectedBank = bank
                    self?.bankSelectionCompletion?(bank)
                }
                
                PrimerUIManager.primerRootViewController?.show(viewController: bsvc)
                seal.fulfill()
            }
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.bankSelectionCompletion = { bank in
                seal.fulfill()
            }
        }
    }
}

#endif
