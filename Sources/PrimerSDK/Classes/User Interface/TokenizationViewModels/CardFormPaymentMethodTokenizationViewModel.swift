//
//  CardFormPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

#if canImport(UIKit)

import Foundation
import SafariServices
import UIKit

class CardFormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var cardComponentsManager: CardComponentsManager!
    var onConfigurationFetched: (() -> Void)?
    
    // This is used just in case we get a client session action response
    // while we've already started the payment. In this case we don't
    // want to update the button's UI.
    private var isTokenizing = false
    private var userInputCompletion: (() -> Void)?
    private var cardComponentsManagerTokenizationCompletion: ((PrimerPaymentMethodTokenData?, Error?) -> Void)?
    private var webViewController: SFSafariViewController?
    private var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    private var isCardholderNameFieldEnabled: Bool {
        if (AppState.current.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions)?.cardHolderName == false {
            return false
        } else {
            return true
        }
    }
    
    lazy var cardNumberField: PrimerCardNumberFieldView = {
        let cardNumberField = PrimerCardNumberFieldView()
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = theme.input.text.color
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = self
        return cardNumberField
    }()
    
    var requirePostalCode: Bool {
        guard let billingAddressModule = AppState.current.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first else { return false }
        return (billingAddressModule.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions)?.postalCode ?? false
    }
    
    lazy var expiryDateField: PrimerExpiryDateFieldView = {
        let expiryDateField = PrimerExpiryDateFieldView()
        expiryDateField.placeholder = "02/22"
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.textColor = theme.input.text.color
        expiryDateField.delegate = self
        return expiryDateField
    }()
    
    lazy var cvvField: PrimerCVVFieldView = {
        let cvvField = PrimerCVVFieldView()
        cvvField.placeholder = "123"
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.textColor = theme.input.text.color
        cvvField.delegate = self
        return cvvField
    }()
    
    lazy var cardholderNameField: PrimerCardholderNameFieldView? = {
        if !isCardholderNameFieldEnabled { return nil }
        let cardholderNameField = PrimerCardholderNameFieldView()
        cardholderNameField.placeholder = NSLocalizedString("primer-form-text-field-placeholder-cardholder",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "e.g. John Doe",
                                                            comment: "e.g. John Doe - Form Text Field Placeholder (Cardholder name)")
        cardholderNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardholderNameField.textColor = theme.input.text.color
        cardholderNameField.delegate = self
        return cardholderNameField
    }()
    
    private var localSamplePostalCode: String {
        let countryCode = AppState.current.apiConfiguration?.clientSession?.order?.countryCode
        return PostalCode.sample(for: countryCode)
    }
    
    lazy var postalCodeField: PrimerPostalCodeFieldView = {
        let postalCodeField = PrimerPostalCodeFieldView()
        postalCodeField.placeholder = localSamplePostalCode
        postalCodeField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        postalCodeField.textColor = theme.input.text.color
        postalCodeField.delegate = self
        return postalCodeField
    }()
    
    internal lazy var cardNumberContainerView: PrimerCustomFieldView = {
        let cardNumberContainerView = PrimerCustomFieldView()
        cardNumberContainerView.fieldView = cardNumberField
        cardNumberContainerView.placeholderText = NSLocalizedString("primer-form-text-field-title-card-number",
                                                                    tableName: nil,
                                                                    bundle: Bundle.primerResources,
                                                                    value: "Card number",
                                                                    comment: "Card number - Form Text Field Title (Card number)")
        cardNumberContainerView.setup()
        cardNumberContainerView.tintColor = theme.input.border.color(for: .selected)
        return cardNumberContainerView
    }()
    
    internal lazy var expiryDateContainerView: PrimerCustomFieldView = {
        let expiryDateContainerView = PrimerCustomFieldView()
        expiryDateContainerView.fieldView = expiryDateField
        expiryDateContainerView.placeholderText = NSLocalizedString("primer-form-text-field-title-expiry-date",
                                                                    tableName: nil,
                                                                    bundle: Bundle.primerResources,
                                                                    value: "Expiry date",
                                                                    comment: "Expiry date - Form Text Field Title (Expiry date)")
        expiryDateContainerView.setup()
        expiryDateContainerView.tintColor = theme.input.border.color(for: .selected)
        return expiryDateContainerView
    }()
    
    internal lazy var cvvContainerView: PrimerCustomFieldView = {
        let cvvContainerView = PrimerCustomFieldView()
        cvvContainerView.fieldView = cvvField
        cvvContainerView.placeholderText = NSLocalizedString("primer-card-form-cvv",
                                                             tableName: nil,
                                                             bundle: Bundle.primerResources,
                                                             value: "CVV",
                                                             comment: "CVV - Card Form (CVV text field placeholder text)")
        cvvContainerView.setup()
        cvvContainerView.tintColor = theme.input.border.color(for: .selected)
        return cvvContainerView
    }()
    
    internal lazy var cardholderNameContainerView: PrimerCustomFieldView? = {
        if !isCardholderNameFieldEnabled { return nil }
        let cardholderNameContainerView = PrimerCustomFieldView()
        cardholderNameContainerView.fieldView = cardholderNameField
        cardholderNameContainerView.placeholderText = NSLocalizedString("primer-card-form-name",
                                                                        tableName: nil,
                                                                        bundle: Bundle.primerResources,
                                                                        value: "Name",
                                                                        comment: "Cardholder name")
        cardholderNameContainerView.setup()
        cardholderNameContainerView.tintColor = theme.input.border.color(for: .selected)
        return cardholderNameContainerView
    }()
    
    private var localPostalCodeTitle: String {
        let countryCode = AppState.current.apiConfiguration?.clientSession?.order?.countryCode
        return PostalCode.name(for: countryCode)
    }
    
    internal lazy var postalCodeContainerView: PrimerCustomFieldView = {
        let postalCodeContainerView = PrimerCustomFieldView()
        postalCodeContainerView.fieldView = postalCodeField
        postalCodeContainerView.placeholderText = localPostalCodeTitle
        postalCodeContainerView.setup()
        postalCodeContainerView.tintColor = theme.input.border.color(for: .selected)
        return postalCodeContainerView
    }()
    
    var cardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = cardNetwork ?? .unknown
        }
    }
    
    required init(config: PaymentMethodConfig) {
        super.init(config: config)
        
        self.cardComponentsManager = CardComponentsManager(
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField,
            postalCodeField: requirePostalCode ? postalCodeField : nil
        )
        cardComponentsManager.delegate = self
    }
    
    override func start() {
        self.didStartTokenization = {
            self.isTokenizing = true
            self.uiModule.submitButton?.startAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false
        }
        
        self.didFinishTokenization = { err in
            self.uiModule.submitButton?.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        
        self.didStartPayment = {
            self.uiModule.submitButton?.startAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false
        }
        
        self.didFinishPayment = { err in
            self.uiModule.submitButton?.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
            
            self.willDismissPaymentMethodUI?()
            self.webViewController?.dismiss(animated: true, completion: {
                self.didDismissPaymentMethodUI?()
            })
        }
        
        super.start()
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "clientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if Primer.shared.intent == .checkout {
            if AppState.current.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if AppState.current.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
        }
    }
    
    override func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type.rawValue,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: event)
        
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                return self.presentCardFormViewController()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                self.didStartTokenization?()
                return self.dispatchActions()
            }
            .then { () -> Promise<Void> in
                self.updateButtonUI()
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutTokenizationDidStart(for: self.config.type.rawValue)
                return self.tokenize()
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func presentCardFormViewController() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                switch self.config.type {
                case .paymentCard:
                    let pcfvc = PrimerCardFormViewController(viewModel: self)
                    Primer.shared.primerRootVC?.show(viewController: pcfvc)
                    seal.fulfill()
                default:
                    fatalError()
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
    
    private func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
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
    
    override func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?> {
        return Promise { seal in
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
    #if canImport(Primer3DS)
                guard let paymentMethodTokenData = paymentMethodTokenData else {
                    let err = InternalError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                    return
                }
                
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodToken: paymentMethodTokenData, protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        DispatchQueue.main.async {
                            guard let threeDSPostAuthResponse = paymentMethodToken.1,
                                  let resumeToken = threeDSPostAuthResponse.resumeToken else {
                                let decoderError = InternalError.failedToDecode(message: "Failed to decode the threeDSPostAuthResponse", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                let err = PrimerError.failedToPerform3DS(error: decoderError, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                ErrorHandler.handle(error: err)
                                seal.reject(err)
                                return
                            }
                            
                            seal.fulfill(resumeToken)
                        }
                        
                    case .failure(let err):
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(containerErr)
                    }
                }
    #else
                let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
    #endif
                
            } else if decodedClientToken.intent == RequiredActionName.processor3DS.rawValue {
                if let redirectUrlStr = decodedClientToken.redirectUrl,
                   let redirectUrl = URL(string: redirectUrlStr),
                   let statusUrlStr = decodedClientToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedClientToken.intent != nil {
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.endIgnoringInteractionEvents()
                    }
                    
                    firstly {
                        self.presentWeb3DS(with: redirectUrl)
                    }
                    .then { () -> Promise<String> in
                        return self.startPolling(on: statusUrl)
                    }
                    .done { resumeToken in
                        seal.fulfill(resumeToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
    
    private func presentWeb3DS(with redirectUrl: URL) -> Promise<Void> {
        return Promise { seal in
            self.webViewController = SFSafariViewController(url: redirectUrl)
            self.webViewController!.delegate = self
            
            self.webViewCompletion = { (id, err) in
                if let err = err {
                    seal.reject(err)
                }
            }
            
            DispatchQueue.main.async {
                Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                    DispatchQueue.main.async {
                        seal.fulfill()
                    }
                })
            }
        }
    }
    
    private func startPolling(on url: URL) -> Promise<String> {
        return Promise { seal in
            self.startPolling(on: url) { resumeToken, err in
                if let err = err {
                    seal.reject(err)
                } else if let resumeToken = resumeToken {
                    seal.fulfill(resumeToken)
                } else {
                    assert(true, "Completion handler should always return a value or an error")
                }
            }
        }
    }
    
    private func startPolling(on url: URL, completion: @escaping (String?, Error?) -> Void) {
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: ClientTokenService.decodedClientToken, url: url.absoluteString) { result in
            if self.webViewCompletion == nil {
                let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(nil, err)
                return
            }
            
            switch result {
            case .success(let res):
                if res.status == .pending {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        self.startPolling(on: url, completion: completion)
                    }
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    let err = PrimerError.generic(message: "Should never end up here", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                }
            case .failure(let err):
                ErrorHandler.handle(error: err)
                // Retry
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                    self.startPolling(on: url, completion: completion)
                }
            }
        }
    }
    
    func configurePayButton(cardNetwork: CardNetwork?) {
        var amount: Int = AppState.current.amount ?? 0
        
        if let surcharge = cardNetwork?.surcharge {
            amount += surcharge
        }
        
        configurePayButton(amount: amount)
    }
    
    func configurePayButton(amount: Int) {
        DispatchQueue.main.async {
            guard Primer.shared.intent == .checkout,
                  let currency = AppState.current.currency else {
                return
            }
            
            var title = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                          tableName: nil,
                                          bundle: Bundle.primerResources,
                                          value: "Pay",
                                          comment: "Pay - Card Form View (Sumbit button text)")
            
            title += " \(amount.toCurrencyString(currency: currency))"
            self.uiModule.submitButton?.setTitle(title, for: .normal)
        }
    }
    
    override func submitButtonTapped() {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type.rawValue,
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

extension CardFormPaymentMethodTokenizationViewModel {
    
    private func dispatchActions() -> Promise<Void> {
        return Promise { seal in
            var network = self.cardNetwork?.rawValue.uppercased()
            if network == nil || network == "UNKNOWN" {
                network = "OTHER"
            }
            
            let params: [String: Any] = [
                "paymentMethodType": "PAYMENT_CARD",
                "binData": [
                    "network": network,
                ]
            ]
            
            var actions = [ClientSessionAPIResponse.Action.selectPaymentMethodActionWithParameters(params)]
            
            if (requirePostalCode) {
                let currentBillingAddress = AppState.current.apiConfiguration?.clientSession?.customer?.billingAddress
                
                let billingAddressWithUpdatedPostalCode = ClientSessionAPIResponse.Address(firstName: currentBillingAddress?.firstName,
                                                                                lastName: currentBillingAddress?.lastName,
                                                                                addressLine1: currentBillingAddress?.addressLine1,
                                                                                addressLine2: currentBillingAddress?.addressLine2,
                                                                                city: currentBillingAddress?.city,
                                                                                postalCode: postalCodeField.postalCode,
                                                                                state: currentBillingAddress?.state,
                                                                                countryCode: currentBillingAddress?.countryCode)
                
                if let billingAddressWithUpdatedPostalCode = try? billingAddressWithUpdatedPostalCode.asDictionary() {
                    let billingAddressAction = ClientSessionAPIResponse.Action.setBillingAddressActionWithParameters(billingAddressWithUpdatedPostalCode)
                    actions.append(billingAddressAction)
                }
            }
            
            firstly {
                ClientSessionAPIResponse.Action.dispatchMultipleActions(actions)
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
}

extension CardFormPaymentMethodTokenizationViewModel: CardComponentsManagerDelegate {
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
        self.cardComponentsManagerTokenizationCompletion?(paymentMethodToken, nil)
        self.cardComponentsManagerTokenizationCompletion = nil
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void) {
        if let clientToken = AppState.current.clientToken {
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
        isLoading ? self.uiModule.submitButton?.startAnimating() : self.uiModule.submitButton?.stopAnimating()
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = !isLoading
    }
    
    fileprivate func autofocusToNextFieldIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if isValid == true {
            if primerTextFieldView is PrimerCardNumberFieldView {
                _ = expiryDateField.becomeFirstResponder()
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                _ = cvvField.becomeFirstResponder()
            } else if primerTextFieldView is PrimerCVVFieldView {
                _ = cardholderNameField?.becomeFirstResponder()
            }
        }
    }
    
    fileprivate func showTexfieldViewErrorIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if isValid == false, !primerTextFieldView.isEmpty {
            // We know for sure that the text is not valid, even if the user hasn't finished typing.
            if primerTextFieldView is PrimerCardNumberFieldView {
                cardNumberContainerView.errorText = "Invalid card number"
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                expiryDateContainerView.errorText = "Invalid date"
            } else if primerTextFieldView is PrimerCVVFieldView {
                cvvContainerView.errorText = "Invalid CVV"
            } else if primerTextFieldView is PrimerCardholderNameFieldView {
                cardholderNameContainerView?.errorText = "Invalid name"
            } else if primerTextFieldView is PrimerPostalCodeFieldView {
                postalCodeContainerView.errorText = "\(localPostalCodeTitle) is required" // todo: localise if UK, etc.
            }
        } else {
            // We don't know for sure if the text is valid
            if primerTextFieldView is PrimerCardNumberFieldView {
                cardNumberContainerView.errorText = nil
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                expiryDateContainerView.errorText = nil
            } else if primerTextFieldView is PrimerCVVFieldView {
                cvvContainerView.errorText = nil
            } else if primerTextFieldView is PrimerCardholderNameFieldView {
                cardholderNameContainerView?.errorText = nil
            } else if primerTextFieldView is PrimerPostalCodeFieldView {
                postalCodeContainerView.errorText = nil
            }
        }
    }
    
    fileprivate func enableSubmitButtonIfNeeded() {
        var validations = [
            cardNumberField.isTextValid,
            expiryDateField.isTextValid,
            cvvField.isTextValid,
        ]
        
        if requirePostalCode { validations.append(postalCodeField.isTextValid) }
        if cardholderNameField != nil { validations.append(cardholderNameField!.isTextValid) }
        
        if validations.allSatisfy({ $0 == true }) {
            self.uiModule.submitButton?.isEnabled = true
            self.uiModule.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            self.uiModule.submitButton?.isEnabled = false
            self.uiModule.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }
    
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    private func updateBillingAddressWithParameters(_ parameters: [String: Any]) {
        
        firstly {
            ClientSessionAPIResponse.Action.setPostalCodeWithParameters(parameters)
        }
        .done{}
        .catch { error in
            // FIXME:
//            self.handle(error: error)
        }
    }
}

extension CardFormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: true)
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        // Dispatch postal code action if valid postal code.
        if let fieldView = (primerTextFieldView as? PrimerPostalCodeFieldView), isValid  == true {
            let currentBillingAddress = AppState.current.apiConfiguration?.clientSession?.customer?.billingAddress
            let billingAddressWithUpdatedPostalCode = ClientSessionAPIResponse.Address(firstName: currentBillingAddress?.firstName,
                                                                            lastName: currentBillingAddress?.lastName,
                                                                            addressLine1: currentBillingAddress?.addressLine1,
                                                                            addressLine2: currentBillingAddress?.addressLine2,
                                                                            city: currentBillingAddress?.city,
                                                                            postalCode: fieldView.postalCode,
                                                                            state: currentBillingAddress?.state,
                                                                            countryCode: currentBillingAddress?.countryCode)
            
            if let billingAddressWithUpdatedPostalCode = try? billingAddressWithUpdatedPostalCode.asDictionary() {
                self.updateBillingAddressWithParameters(ClientSessionAPIResponse.Action.makeBillingAddressDictionaryRequestFromParameters(billingAddressWithUpdatedPostalCode))
            }
        }
        
        autofocusToNextFieldIfNeeded(for: primerTextFieldView, isValid: isValid)
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: isValid)
        enableSubmitButtonIfNeeded()
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork?) {
        self.cardNetwork = cardNetwork
        
        if let cardNetwork = cardNetwork, cardNetwork != .unknown, cardNumberContainerView.rightImage2 == nil && cardNetwork.icon != nil {
            var network = self.cardNetwork?.rawValue.uppercased()
            if network == nil || network == "UNKNOWN" {
                network = "OTHER"
            }
            
            let params: [String: Any] = [
                "paymentMethodType": "PAYMENT_CARD",
                "binData": [
                    "network": network,
                ]
            ]
            
            cardNumberContainerView.rightImage2 = cardNetwork.icon
            
            firstly {
                ClientSessionAPIResponse.Action.selectPaymentMethodWithParametersIfNeeded(params)
            }
            .done {
                self.updateButtonUI()
            }
            .catch { _ in }
        } else if cardNumberContainerView.rightImage2 != nil && cardNetwork?.icon == nil {
            cardNumberContainerView.rightImage2 = nil
            
            firstly {
                ClientSessionAPIResponse.Action.unselectPaymentMethodIfNeeded()
            }
            .done {
                self.updateButtonUI()
            }
            .catch { _ in }
        }
    }
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    private func updateButtonUI() {
        if let amount = AppState.current.amount, !self.isTokenizing {
            self.configurePayButton(amount: amount)
        }
    }
    
    private func raiseOnConfigurationFetchedCallback() {
        self.onConfigurationFetched?()
    }
}

extension CardFormPaymentMethodTokenizationViewModel: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(paymentMethodType: config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            webViewCompletion(nil, err)
        }
        
        webViewCompletion = nil
    }
}

#endif
