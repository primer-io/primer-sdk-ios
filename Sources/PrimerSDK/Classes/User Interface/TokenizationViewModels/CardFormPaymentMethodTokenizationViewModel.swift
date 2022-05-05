//
//  CardFormPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

#if canImport(UIKit)

import Foundation
import UIKit

class CardFormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var flow: PaymentFlow
    private var cardComponentsManager: CardComponentsManager!
    var onConfigurationFetched: (() -> Void)?
    
    // FIXME: Is this the fix for the button's indicator?
    private var isTokenizing = false
    
    private lazy var _title: String = {
        return "Payment Card"
    }()
    
    override var title: String {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonTitle: String? = {
        switch config.type {
        case .paymentCard:
            return Primer.shared.flow.internalSessionFlow.vaulted
            ? NSLocalizedString("payment-method-type-card-vaulted",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: "Add new card",
                                comment: "Add new card - Payment Method Type (Card Vaulted)")
            
            : NSLocalizedString("payment-method-type-card-not-vaulted",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: "Pay with card",
                                comment: "Pay with card - Payment Method Type (Card Not vaulted)")
        case .adyenBlik:
            return nil
            
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override var buttonTitle: String? {
        get { return _buttonTitle }
        set { _buttonTitle = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .paymentCard:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .adyenBlik:
            return UIImage(named: "blik-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override var buttonImage: UIImage? {
        get { return _buttonImage }
        set { _buttonImage = newValue }
    }
    
    private lazy var _buttonColor: UIColor? = {
        switch config.type {
        case .paymentCard,
                .adyenBlik:
            return theme.paymentMethodButton.color(for: .enabled)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override var buttonColor: UIColor? {
        get { return _buttonColor }
        set { _buttonColor = newValue }
    }
    
    private lazy var _buttonTitleColor: UIColor? = {
        switch config.type {
        case .paymentCard:
            return theme.paymentMethodButton.text.color
        case .adyenBlik:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override var buttonTitleColor: UIColor? {
        get { return _buttonTitleColor }
        set { _buttonTitleColor = newValue }
    }
    
    private lazy var _buttonBorderWidth: CGFloat = {
        switch config.type {
        case .paymentCard,
                .adyenBlik:
            return theme.paymentMethodButton.border.width
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override var buttonBorderWidth: CGFloat {
        get { return _buttonBorderWidth }
        set { _buttonBorderWidth = newValue }
    }
    
    private lazy var _buttonBorderColor: UIColor? = {
        switch config.type {
        case .paymentCard,
                .adyenBlik:
            return theme.paymentMethodButton.border.color(for: .enabled)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override var buttonBorderColor: UIColor? {
        get { return _buttonBorderColor }
        set { _buttonBorderColor = newValue }
    }
    
    private lazy var _buttonTintColor: UIColor? = {
        switch config.type {
        case .paymentCard:
            return theme.paymentMethodButton.iconColor
        case .adyenBlik:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override var buttonTintColor: UIColor? {
        get { return _buttonTintColor }
        set { _buttonTintColor = newValue }
    }
    
    private lazy var _buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    override var buttonFont: UIFont? {
        get { return _buttonFont }
        set { _buttonFont = newValue }
    }
    
    private lazy var _buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    override var buttonCornerRadius: CGFloat? {
        get { return _buttonCornerRadius }
        set { _buttonCornerRadius = newValue }
    }
    
    private var isCardholderNameFieldEnabled: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if (state.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions)?.cardHolderName == false {
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let billingAddressModule = state.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first else { return false }
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        let countryCode = state.apiConfiguration?.clientSession?.order?.countryCode
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        let countryCode = state.apiConfiguration?.clientSession?.order?.countryCode
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
    
    lazy var submitButton: PrimerButton = {
        var buttonTitle: String = ""
        if flow == .checkout {
            let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
            buttonTitle = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                            tableName: nil,
                                            bundle: Bundle.primerResources,
                                            value: "Pay",
                                            comment: "Pay - Card Form View (Sumbit button text)") + " " + (viewModel.amountStringed ?? "")
        } else if flow == .vault {
            buttonTitle = NSLocalizedString("primer-card-form-add-card",
                                            tableName: nil,
                                            bundle: Bundle.primerResources,
                                            value: "Add card",
                                            comment: "Add card - Card Form (Vault title text)")
        }
        
        let submitButton = PrimerButton()
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitButton.isAccessibilityElement = true
        submitButton.accessibilityIdentifier = "submit_btn"
        submitButton.isEnabled = false
        submitButton.setTitle(buttonTitle, for: .normal)
        submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
        submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
        submitButton.layer.cornerRadius = 4
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(payButtonTapped(_:)), for: .touchUpInside)
        return submitButton
    }()
    
    var cardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = cardNetwork ?? .unknown
        }
    }
    
    required init(config: PaymentMethodConfig) {
        self.flow = Primer.shared.flow.internalSessionFlow.vaulted ? .vault : .checkout
        super.init(config: config)
        
        self.cardComponentsManager = CardComponentsManager(
            flow: flow,
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField,
            postalCodeField: requirePostalCode ? postalCodeField : nil
        )
        cardComponentsManager.delegate = self
    }
    
    override func validate() throws {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "clientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if !Primer.shared.flow.internalSessionFlow.vaulted {
            if settings.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if settings.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
        }
    }
    
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
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
        
        do {
            try self.validate()
        } catch {
            DispatchQueue.main.async {
                PrimerDelegateProxy.primerDidFailWithError(error, data: nil, decisionHandler: nil)
                self.handleFailureFlow(error: error)
            }
            return
        }
        
        DispatchQueue.main.async {
            switch self.config.type {
            case .paymentCard:
                let pcfvc = PrimerCardFormViewController(viewModel: self)
                Primer.shared.primerRootVC?.show(viewController: pcfvc)
            default:
                break
            }
        }
    }
    
    func configurePayButton(cardNetwork: CardNetwork?) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        var amount: Int = settings.amount ?? 0
        
        if let surcharge = cardNetwork?.surcharge {
            amount += surcharge
        }
        
        configurePayButton(amount: amount)
    }
    
    func configurePayButton(amount: Int) {
        DispatchQueue.main.async {
            if !Primer.shared.flow.internalSessionFlow.vaulted {
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                var title = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                              tableName: nil,
                                              bundle: Bundle.primerResources,
                                              value: "Pay",
                                              comment: "Pay - Card Form View (Sumbit button text)") //+ " " + (amount.toCurrencyString(currency: settings.currency) ?? "")
                
                if let currency = settings.currency {
                    title += " \(amount.toCurrencyString(currency: currency))"
                }
                
                self.submitButton.setTitle(title, for: .normal)
            }
        }
    }
    
    @objc
    func payButtonTapped(_ sender: UIButton) {
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
        
        isTokenizing = true
        submitButton.startAnimating()
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false
        
        firstly {
            self.dispatchActions()
        }
        .then {
            self.handlePrimerWillCreatePaymentEvent(PaymentMethodData(type: self.config.type))
        }
        .done {
            self.cardComponentsManager.tokenize()
        }
        .ensure {
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        .catch { error in
            ErrorHandler.handle(error: error)
            PrimerDelegateProxy.primerDidFailWithError(error, data: nil, decisionHandler: nil)
            self.handleFailureFlow(error: error)
        }
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
            
            var actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
            
            if (requirePostalCode) {
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                let currentBillingAddress = state.apiConfiguration?.clientSession?.customer?.billingAddress
                
                let billingAddressWithUpdatedPostalCode = ClientSession.Address(firstName: currentBillingAddress?.firstName,
                                                                                lastName: currentBillingAddress?.lastName,
                                                                                addressLine1: currentBillingAddress?.addressLine1,
                                                                                addressLine2: currentBillingAddress?.addressLine2,
                                                                                city: currentBillingAddress?.city,
                                                                                postalCode: postalCodeField.postalCode,
                                                                                state: currentBillingAddress?.state,
                                                                                countryCode: currentBillingAddress?.countryCode)
                
                if let billingAddressWithUpdatedPostalCode = try? billingAddressWithUpdatedPostalCode.asDictionary() {
                    let billingAddressAction = ClientSession.Action.setBillingAddressActionWithParameters(billingAddressWithUpdatedPostalCode)
                    actions.append(billingAddressAction)
                }
            }
            
            firstly {
                ClientSession.Action.dispatchMultipleActions(actions)
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
        self.paymentMethodTokenData = paymentMethodToken
        
        DispatchQueue.main.async {            
            self.handleContinuePaymentFlowWithPaymentMethod(paymentMethodToken)
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if let clientToken = state.clientToken {
            completion(clientToken, nil)
        } else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(nil, err)
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, tokenizationFailedWith errors: [Error]) {
        submitButton.startAnimating()
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        
        DispatchQueue.main.async {
            let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.primerDidFailWithError(err, data: nil, decisionHandler: nil)
            self.handleFailureFlow(error: err)
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, isLoading: Bool) {
        isLoading ? submitButton.startAnimating() : submitButton.stopAnimating()
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
            submitButton.isEnabled = true
            submitButton.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            submitButton.isEnabled = false
            submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }
    
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    private func updateBillingAddressWithParameters(_ parameters: [String: Any]) {
        
        firstly {
            ClientSession.Action.setPostalCodeWithParameters(parameters)
        }
        .done{}
        .catch { error in
            self.handle(error: error)
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
            let state: AppStateProtocol = DependencyContainer.resolve()
            let currentBillingAddress = state.apiConfiguration?.clientSession?.customer?.billingAddress
            let billingAddressWithUpdatedPostalCode = ClientSession.Address(firstName: currentBillingAddress?.firstName,
                                                                            lastName: currentBillingAddress?.lastName,
                                                                            addressLine1: currentBillingAddress?.addressLine1,
                                                                            addressLine2: currentBillingAddress?.addressLine2,
                                                                            city: currentBillingAddress?.city,
                                                                            postalCode: fieldView.postalCode,
                                                                            state: currentBillingAddress?.state,
                                                                            countryCode: currentBillingAddress?.countryCode)
            
            if let billingAddressWithUpdatedPostalCode = try? billingAddressWithUpdatedPostalCode.asDictionary() {
                self.updateBillingAddressWithParameters(ClientSession.Action.makeBillingAddressDictionaryRequestFromParameters(billingAddressWithUpdatedPostalCode))
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
            
            self.selectPaymentMethodWithParametersIfNeeded(params)
            cardNumberContainerView.rightImage2 = cardNetwork.icon
        } else if cardNumberContainerView.rightImage2 != nil && cardNetwork?.icon == nil {
            cardNumberContainerView.rightImage2 = nil
            self.unselectPaymentMethodIfNeeded()
        }
    }
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    private func selectPaymentMethodWithParametersIfNeeded(_ parameters: [String: Any]) {
        firstly {
            ClientSession.Action.selectPaymentMethodWithParametersIfNeeded(parameters)
        }
        .ensure {
            self.updateButtonUI()
            self.raiseOnConfigurationFetchedCallback()
        }
        .catch { error in
            self.handle(error: error)
        }
    }
    
    private func unselectPaymentMethodIfNeeded() {
        firstly {
            ClientSession.Action.unselectPaymentMethodIfNeeded()
        }
        .ensure {
            self.updateButtonUI()
            self.raiseOnConfigurationFetchedCallback()
        }
        .catch { _ in }
    }
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    private func handle(_ clientToken: String) {
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if state.clientToken != clientToken {
            
            ClientTokenService.storeClientToken(clientToken) { error in
                DispatchQueue.main.async {
                    
                    guard error == nil else {
                        ErrorHandler.handle(error: error!)
                        self.handleErrorBasedOnSDKSettings(error!, isOnResumeFlow: true)
                        return
                    }
                    
                    self.continueHandleNewClientToken(clientToken)
                }
            }
        } else {
            self.continueHandleNewClientToken(clientToken)
        }
    }
    
    private func continueHandleNewClientToken(_ clientToken: String) {
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            DispatchQueue.main.async {
                let error = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                self.handle(error: error)
            }
            return
        }
        
        if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
#if canImport(Primer3DS)
            guard let paymentMethod = paymentMethod else {
                DispatchQueue.main.async {
                    let err = ParserError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: containerErr)
                    self.handleErrorBasedOnSDKSettings(containerErr, isOnResumeFlow: true)
                }
                return
            }
            
            let threeDSService = ThreeDSService()
            threeDSService.perform3DS(paymentMethodToken: paymentMethod, protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                switch result {
                case .success(let paymentMethodToken):
                    DispatchQueue.main.async {
                        guard let threeDSPostAuthResponse = paymentMethodToken.1,
                              let resumeToken = threeDSPostAuthResponse.resumeToken else {
                            DispatchQueue.main.async {
                                let decoderError = ParserError.failedToDecode(message: "Failed to decode the threeDSPostAuthResponse", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                let err = PrimerError.failedToPerform3DS(error: decoderError, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                ErrorHandler.handle(error: err)
                                self.handleErrorBasedOnSDKSettings(err, isOnResumeFlow: true)
                            }
                            return
                        }
                        
                        self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                    }
                    
                case .failure(let err):
                    log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: containerErr)
                    DispatchQueue.main.async {
                        self.handleErrorBasedOnSDKSettings(containerErr, isOnResumeFlow: true)
                    }
                }
            }
#else
            let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            DispatchQueue.main.async {
                self.handleErrorBasedOnSDKSettings(err, isOnResumeFlow: true)
            }
#endif
            
        } else {
            let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            DispatchQueue.main.async {
                self.handleErrorBasedOnSDKSettings(err, isOnResumeFlow: true)
            }
        }
    }
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    private func updateButtonUI() {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if let amount = settings.amount, !self.isTokenizing {
            self.configurePayButton(amount: amount)
        }
    }
    
    private func raiseOnConfigurationFetchedCallback() {
        self.onConfigurationFetched?()
    }
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        DispatchQueue.main.async {
            self.handleFailureFlow(error: error)
            self.submitButton.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        
        tokenizationCompletion?(nil, error)
    }
    
    override func handle(newClientToken clientToken: String) {
        self.handle(clientToken)
    }
    
    override func handleSuccess() {
        DispatchQueue.main.async {
            self.submitButton.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        tokenizationCompletion?(self.paymentMethodTokenData, nil)
    }
}

#endif
