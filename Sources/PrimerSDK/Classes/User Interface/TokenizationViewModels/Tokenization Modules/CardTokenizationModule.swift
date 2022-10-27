//
//  CardTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 18/10/22.
//

#if canImport(UIKit)

import Foundation

class CardTokenizationModule: TokenizationModule {

    private var cardComponentsManager: CardComponentsManager!
    private var userInputCompletion: (() -> Void)?
    private var cardComponentsManagerTokenizationCompletion: ((PrimerPaymentMethodTokenData?, Error?) -> Void)?
    
    required init(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: UserInterfaceModule,
        checkoutEventsNotifier: CheckoutEventsNotifierModule)
    {
        super.init(
            paymentMethodConfiguration: paymentMethodConfiguration,
            userInterfaceModule: userInterfaceModule,
            checkoutEventsNotifier: checkoutEventsNotifier)
        
        self.cardComponentsManager = CardComponentsManager(
            cardnumberField: self.userInterfaceModule.cardNumberField,
            expiryDateField: self.userInterfaceModule.expiryDateField,
            cvvField: self.userInterfaceModule.cvvField,
            cardholderNameField: self.userInterfaceModule.cardholderNameField,
            billingAddressFieldViews: self.userInterfaceModule.allVisibleBillingAddressFieldViews,
            paymentMethodType: self.paymentMethodConfiguration.type,
            isRequiringCVVInput: self.userInterfaceModule.isRequiringCVVInput
        )
        
        cardComponentsManager.delegate = self
    }
    
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
        
        return Promise { seal in
            firstly {
                self.validate()
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
                return self.awaitUserInput()
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
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            self.cardComponentsManagerTokenizationCompletion = { (paymentMethodTokenData, err) in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethodTokenData = paymentMethodTokenData {
                    seal.fulfill(paymentMethodTokenData)
                }
            }
            
            self.cardComponentsManager.tokenize()
        }
    }
    
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                switch self.paymentMethodConfiguration.type {
                case PrimerPaymentMethodType.paymentCard.rawValue:
                    let pcfvc = PrimerCardFormViewController(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule)
                    PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                    seal.fulfill()
                    
                case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
                    let pcfvc = PrimerCardFormViewController(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule)
                    PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                    seal.fulfill()
                    
                default:
                    precondition(false, "Should never end up here")
                }
            }
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.userInputCompletion = {
                seal.fulfill()
            }
        }
    }
    
    private func dispatchActions() -> Promise<Void> {
        return Promise { seal in
            var network = self.userInterfaceModule.cardNetwork?.rawValue.uppercased()
            if network == nil || network == "UNKNOWN" {
                network = "OTHER"
            }
            
            let params: [String: Any] = [
                "paymentMethodType": self.paymentMethodConfiguration.type,
                "binData": [
                    "network": network,
                ]
            ]
            
            var actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
            
            if (self.userInterfaceModule.isShowingBillingAddressFieldsRequired) {
                let updatedBillingAddress = ClientSession.Address(
                    firstName: self.userInterfaceModule.firstNameFieldView.firstName,
                    lastName: self.userInterfaceModule.lastNameFieldView.lastName,
                    addressLine1: self.userInterfaceModule.addressLine1FieldView.addressLine1,
                    addressLine2: self.userInterfaceModule.addressLine2FieldView.addressLine2,
                    city: self.userInterfaceModule.cityFieldView.city,
                    postalCode: self.userInterfaceModule.postalCodeFieldView.postalCode,
                    state: self.userInterfaceModule.stateFieldView.state,
                    countryCode: self.userInterfaceModule.countryFieldView.countryCode)
                
                if let billingAddress = try? updatedBillingAddress.asDictionary() {
                    let billingAddressAction: ClientSession.Action = .setBillingAddressActionWithParameters(billingAddress)
                    actions.append(billingAddressAction)
                }
            }

            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            
            firstly {
                clientSessionActionsModule.dispatch(actions: actions)
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
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
                    paymentMethodType: self.paymentMethodConfiguration.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .submit,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
        
        self.userInputCompletion?()
    }
}

extension CardTokenizationModule: CardComponentsManagerDelegate {
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PrimerPaymentMethodTokenData) {
        self.cardComponentsManagerTokenizationCompletion?(paymentMethodToken, nil)
        self.cardComponentsManagerTokenizationCompletion = nil
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void) {
        if let clientToken = PrimerAPIConfigurationModule.clientToken {
            completion(clientToken, nil)
        } else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, tokenizationFailedWith errors: [Error]) {
        let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
        ErrorHandler.handle(error: err)
        self.cardComponentsManagerTokenizationCompletion?(nil, err)
        self.cardComponentsManagerTokenizationCompletion = nil
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, isLoading: Bool) {
        isLoading ? self.userInterfaceModule.submitButton?.startAnimating() : self.userInterfaceModule.submitButton?.stopAnimating()
        PrimerUIManager.primerRootViewController?.view.isUserInteractionEnabled = !isLoading
    }
}

#endif
