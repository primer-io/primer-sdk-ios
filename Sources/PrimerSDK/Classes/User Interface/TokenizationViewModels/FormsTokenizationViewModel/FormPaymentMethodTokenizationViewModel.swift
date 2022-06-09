//
//  FormPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

#if canImport(UIKit)

import Foundation
import UIKit

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

class FormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var flow: PaymentFlow
    var inputs: [Input] = []
    private var cardComponentsManager: CardComponentsManager!
    var onConfigurationFetched: (() -> Void)?
    
    // FIXME: Is this the fix for the button's indicator?
    private var isTokenizing = false
    
    private lazy var _title: String = { return "Form" }()
    override var title: String  {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonTitle: String? = {
        switch config.type {
        case .paymentCard:
            return (Primer.shared.flow?.internalSessionFlow.vaulted == true)
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
        case .adyenBlik:
            return UIImage(named: "blik-logo-white", in: Bundle.primerResources, compatibleWith: nil)
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
        case .adyenBlik:
            return .black
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
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTintColor: UIColor? {
        get { return _buttonTintColor }
        set { _buttonTintColor = newValue }
    }
        
    var isShowingBillingAddressFieldsRequired: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let billingAddressModuleOptions = state.primerConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first?.options as? PrimerConfiguration.CheckoutModule.PostalCodeOptions
        return billingAddressModuleOptions != nil
    }

    var inputTextFieldsStackViews: [UIStackView] {
        var stackViews: [UIStackView] = []
        for input in self.inputs {
            let verticalStackView = UIStackView()
            verticalStackView.spacing = 2
            verticalStackView.axis = .vertical
            verticalStackView.alignment = .fill
            verticalStackView.distribution = .fill

            let inputTextFieldView = PrimerGenericFieldView()
            inputTextFieldView.delegate = self
            inputTextFieldView.translatesAutoresizingMaskIntoConstraints = false
            inputTextFieldView.heightAnchor.constraint(equalToConstant: 35).isActive = true
            inputTextFieldView.textField.keyboardType = input.keyboardType ?? .default
            inputTextFieldView.allowedCharacterSet = input.allowedCharacterSet
            inputTextFieldView.maxCharactersAllowed = input.maxCharactersAllowed
            inputTextFieldView.isValid = input.isValid
            inputTextFieldView.shouldMaskText = false
            input.primerTextFieldView = inputTextFieldView
            
            let inputContainerView = PrimerCustomFieldView()
            inputContainerView.fieldView = inputTextFieldView
            inputContainerView.placeholderText = input.topPlaceholder
            inputContainerView.setup()
            inputContainerView.tintColor = .systemBlue
            verticalStackView.addArrangedSubview(inputContainerView)
            
            if let descriptor = input.descriptor {
                let lbl = UILabel()
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.translatesAutoresizingMaskIntoConstraints = false
                lbl.text = descriptor
                verticalStackView.addArrangedSubview(lbl)
            }
            stackViews.append(verticalStackView)
        }
        
        return stackViews
    }
    
    lazy var submitButton: PrimerButton = {
        let btn = PrimerButton()
        btn.isEnabled = false
        btn.clipsToBounds = true
        btn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        btn.layer.cornerRadius = 4
        btn.backgroundColor = btn.isEnabled ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        
        switch config.type {
        case .paymentCard:
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
            btn.setTitle(buttonTitle, for: .normal)
            
        default:
            btn.setTitle("Confirm", for: .normal)
        }
        
        return btn
    }()

    var cardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = cardNetwork ?? .unknown
        }
    }
    
    var onClientSessionActionCompletion: ((Error?) -> Void)?
    var onResumeHandlerCompletion: ((URL?, Error?) -> Void)?
    var onResumeTokenCompletion: ((Error?) -> Void)?
    private var isCanceled: Bool = false
    
    // MARK: - Card number field
    
    internal lazy var cardNumberField: PrimerCardNumberFieldView = {
        PrimerCardNumberField.cardNumberFieldViewWithDelegate(self)
    }()
    
    private lazy var cardNumberContainerView: PrimerCustomFieldView = {
        PrimerCardNumberField.cardNumberContainerViewWithFieldView(cardNumberField)
    }()

    // MARK: - Cardholder name field

    private lazy var cardholderNameField: PrimerCardholderNameFieldView? = {
        if !PrimerCardholderNameField.isCardholderNameFieldEnabled { return nil }
        return PrimerCardholderNameField.cardholderNameFieldViewWithDelegate(self)
    }()
    
    private lazy var cardholderNameContainerView: PrimerCustomFieldView? = {
        if !PrimerCardholderNameField.isCardholderNameFieldEnabled { return nil }
        return PrimerCardholderNameField.cardholderNameContainerViewFieldView(cardholderNameField)
    }()
        
    // MARK: - Expiry date field
    
    private lazy var expiryDateField: PrimerExpiryDateFieldView = {
        return PrimerEpiryDateField.expiryDateFieldViewWithDelegate(self)
    }()
    
    private lazy var expiryDateContainerView: PrimerCustomFieldView = {
        return PrimerEpiryDateField.expiryDateContainerViewWithFieldView(expiryDateField)
    }()

    // MARK: - CVV field
    
    private lazy var cvvField: PrimerCVVFieldView = {
        PrimerCVVField.cvvFieldViewWithDelegate(self)
    }()
        
    private lazy var cvvContainerView: PrimerCustomFieldView = {
        PrimerCVVField.cvvContainerViewFieldView(cvvField)
    }()
    
    // MARK: - Billing address
        
    // MARK: First name
    
    private lazy var firstNameFieldView: PrimerFirstNameFieldView = {
        PrimerFirstNameField.firstNameFieldViewWithDelegate(self)
    }()
        
    private lazy var firstNameContainerView: PrimerCustomFieldView = {
        PrimerFirstNameField.firstNameFieldContainerViewFieldView(firstNameFieldView)
    }()
    
    private var firstNameField: BillingAddressField {
        (firstNameFieldView, firstNameContainerView, billingAddressCheckoutModuleOptions?.firstName == false)
    }
    
    // MARK: Last name
    
    private lazy var lastNameFieldView: PrimerLastNameFieldView = {
        PrimerLastNameField.lastNameFieldViewWithDelegate(self)
    }()
            
    private lazy var lastNameContainerView: PrimerCustomFieldView = {
        PrimerLastNameField.lastNameFieldContainerViewFieldView(lastNameFieldView)
    }()
    
    private var lastNameField: BillingAddressField {
        (lastNameFieldView, lastNameContainerView, billingAddressCheckoutModuleOptions?.lastName == false)
    }
    
    // MARK: Address Line 1

    private lazy var addressLine1FieldView: PrimerAddressLine1FieldView = {
        PrimerAddressLine1Field.addressLine1FieldViewWithDelegate(self)
    }()
            
    private lazy var addressLine1ContainerView: PrimerCustomFieldView = {
        PrimerAddressLine1Field.addressLine1ContainerViewFieldView(addressLine1FieldView)
    }()
    
    private var addressLine1Field: BillingAddressField {
        (addressLine1FieldView, addressLine1ContainerView, billingAddressCheckoutModuleOptions?.addressLine1 == false)
    }

    // MARK: Address Line 2

    private lazy var addressLine2FieldView: PrimerAddressLine2FieldView = {
        PrimerAddressLine2Field.addressLine2FieldViewWithDelegate(self)
    }()
            
    private lazy var addressLine2ContainerView: PrimerCustomFieldView = {
        PrimerAddressLine2Field.addressLine2ContainerViewFieldView(addressLine2FieldView)
    }()
    
    private var addressLine2Field: BillingAddressField {
        (addressLine2FieldView, addressLine2ContainerView, billingAddressCheckoutModuleOptions?.addressLine2 == false)
    }
    
    // MARK: City

    private lazy var cityFieldView: PrimerCityFieldView = {
        PrimerCityField.cityFieldViewWithDelegate(self)
    }()
            
    private lazy var cityContainerView: PrimerCustomFieldView = {
        PrimerCityField.cityFieldContainerViewFieldView(cityFieldView)
    }()
    
    private var cityField: BillingAddressField {
        (cityFieldView, cityContainerView, billingAddressCheckoutModuleOptions?.city == false)
    }
    
    // MARK: State

    private lazy var stateFieldView: PrimerStateFieldView = {
        PrimerStateField.stateFieldViewWithDelegate(self)
    }()
            
    private lazy var stateContainerView: PrimerCustomFieldView = {
        PrimerStateField.stateFieldContainerViewFieldView(stateFieldView)
    }()
    
    private var stateField: BillingAddressField {
        (stateFieldView, stateContainerView, billingAddressCheckoutModuleOptions?.state == false)
    }

    // MARK: Postal code
    
    private lazy var postalCodeFieldView: PrimerPostalCodeFieldView = {
        PrimerPostalCodeField.postalCodeViewWithDelegate(self)
    }()
        
    private lazy var postalCodeContainerView: PrimerCustomFieldView = {
        PrimerPostalCodeField.postalCodeContainerViewFieldView(postalCodeFieldView)
    }()
    
    private var postalCodeField: BillingAddressField {
        (postalCodeFieldView, postalCodeContainerView, billingAddressCheckoutModuleOptions?.postalCode == false)
    }
    
    // MARK: All billing address fields
    
    internal var billingAddressCheckoutModuleOptions: PrimerConfiguration.CheckoutModule.PostalCodeOptions? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.primerConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first?.options as? PrimerConfiguration.CheckoutModule.PostalCodeOptions
    }
    
    internal var billingAddressFields: [[BillingAddressField]] {
        guard isShowingBillingAddressFieldsRequired else { return [] }
        return [
            [firstNameField, lastNameField],
            [addressLine1Field],
            [addressLine2Field],
            [postalCodeField, cityField],
            [stateField],
        ]
    }
    
    internal var formView: PrimerFormView {
        let allVisibleBillingAddressFields = billingAddressFields.map { $0.filter { $0.isFieldHidden == false } }
        let allVisibleBillingAddressFieldContainerViews = allVisibleBillingAddressFields.map { $0.map { $0.containerFieldView } }
        var formViews: [[UIView?]] = [
            [cardNumberContainerView],
            [expiryDateContainerView, cvvContainerView],
            [cardholderNameContainerView],
            [postalCodeContainerView],
        ]
        formViews.append(contentsOf: allVisibleBillingAddressFieldContainerViews)
        return PrimerFormView(frame: .zero, formViews: formViews)
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    required init(config: PaymentMethodConfig) {
        self.flow = .checkout
        if let flow = Primer.shared.flow, flow.internalSessionFlow.vaulted {
            self.flow = .vault
        }
        super.init(config: config)
        
        switch config.type {
        case .adyenBlik:
            let input1 = Input()
            input1.name = "OTP"
            input1.topPlaceholder = NSLocalizedString(
                "input_hint_form_blik_otp",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "6 digit code",
                comment: "6 digit code - Text field top placeholder")
            input1.textFieldPlaceholder = NSLocalizedString(
                "payment_method_blik_loading_placeholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Enter your one time password",
                comment: "Enter your one time password - Text field placeholder")
            input1.keyboardType = .numberPad
            input1.descriptor = NSLocalizedString(
                "input_description_otp",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Get the code from your banking app.",
                comment: "Get the code from your banking app - Blik descriptor")
            input1.allowedCharacterSet = CharacterSet(charactersIn: "0123456789")
            input1.maxCharactersAllowed = 6
            input1.isValid = { text in
                return text.isNumeric && text.count >= 6
            }
            inputs.append(input1)
            
        default:
            break
        }
    }
    
    func cancel() {
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        self.onClientSessionActionCompletion = nil
        self.onResumeHandlerCompletion = nil
        self.onResumeTokenCompletion = nil
        
        let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        ErrorHandler.handle(error: err)
        self.completion?(nil, err)
        self.completion = nil
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
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
        
        if PrimerDelegateProxy.isClientSessionActionsImplemented {
            let params: [String: Any] = ["paymentMethodType": config.type.rawValue]
            ClientSession.Action.selectPaymentMethod(resumeHandler: self, withParameters: params)
        } else {
            continueTokenizationFlow()
        }
    }
    
    private func continueTokenizationFlow() {
        self.onClientSessionActionCompletion = nil

        do {
            try self.validate()
        } catch {
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        DispatchQueue.main.async {
            switch self.config.type {
            case .adyenBlik:
                let pcfvc = PrimerInputViewController(navigationBarLogo: UIImage(named: "blik-logo-black", in: Bundle.primerResources, compatibleWith: nil), formPaymentMethodTokenizationViewModel: self)
                Primer.shared.primerRootVC?.show(viewController: pcfvc)
                
            default:
                break
            }
        }
    }
    
    fileprivate func enableConfirmButton(_ flag: Bool) {
        submitButton.isEnabled = flag
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        submitButton.backgroundColor = flag ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
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

        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false
        
        switch config.type {
        case .adyenBlik:
            self.submitButton.startAnimating()
            
            firstly {
                return self.tokenize()
            }.then { paymentMethodToken -> Promise<URL> in
                self.paymentMethod = paymentMethodToken
                return self.fetchPollingUrl(for: paymentMethodToken)
            }.then { pollingUrl -> Promise<String> in
                self.onResumeHandlerCompletion = nil
                
                DispatchQueue.main.async {
                    Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
                }
                
                return self.startPolling(on: pollingUrl)
            }.then { resumeToken -> Promise<Void> in
                return self.passResumeToken(resumeToken)
            }
            .done {
                self.completion?(self.paymentMethod, nil)
                self.completion = nil
            }
            .ensure {
                Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
                self.onClientSessionActionCompletion = nil
                self.onResumeHandlerCompletion = nil
                self.onResumeTokenCompletion = nil
            }
            .catch { err in
                self.handleFailedTokenizationFlow(error: err)
                self.submitButton.stopAnimating()
                self.completion?(nil, err)
                self.completion = nil
            }
        default:
            isTokenizing = true
            submitButton.startAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false
            
            if PrimerDelegateProxy.isClientSessionActionsImplemented {
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
        
                onClientSessionActionCompletion = { err in
                    if let err = err {
                        DispatchQueue.main.async {
                            self.submitButton.stopAnimating()
                            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
                            PrimerDelegateProxy.onResumeError(err)
                        }
                        self.handle(error: err)
                    } else {
                        self.cardComponentsManager.tokenize()
                    }
                    self.onClientSessionActionCompletion = nil
                }
                
                var actions = [ClientSession.Action(type: "SELECT_PAYMENT_METHOD", params: params)]
                
                if (isShowingBillingAddressFieldsRequired) {
                    let updatedBillingAddress = ClientSession.Address(firstName: firstNameFieldView.firstName,
                                                                      lastName: lastNameFieldView.lastName,
                                                                      addressLine1: addressLine1FieldView.addressLine1,
                                                                      addressLine2: addressLine2FieldView.addressLine2,
                                                                      city: cityFieldView.city,
                                                                      postalCode: postalCodeFieldView.postalCode,
                                                                      state: stateFieldView.state,
                                                                      countryCode: nil)
                    
                    if let updatedBillingAddressDictionary = try? updatedBillingAddress.asDictionary() {
                        
                        let billingAddressAction = ClientSession.Action(
                            type: "SET_BILLING_ADDRESS",
                            params: updatedBillingAddressDictionary
                        )
                        actions.append(billingAddressAction)
                    }
                }
                
                ClientSession.Action.dispatchMultiple(resumeHandler: self, actions: actions)
            
            } else {
                cardComponentsManager.tokenize()
            }
        }
    }

    private func tokenize() -> Promise<PaymentMethodToken> {
        switch config.type {
        case .adyenBlik:
            return Promise { seal in
                guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                    let err = PrimerError.invalidClientToken(userInfo: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let configId = config.id else {
                    let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let blikCode = inputs.first?.text else {
                    let err = PrimerError.invalidValue(key: "blikCode", value: nil, userInfo: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                let tokenizationRequest = BlikPaymentMethodTokenizationRequest(
                    paymentInstrument: BlikPaymentMethodOptions(
                        paymentMethodType: config.type,
                        paymentMethodConfigId: configId,
                        sessionInfo: BlikPaymentMethodOptions.SessionInfo(
                            blikCode: blikCode,
                            locale: settings.localeData.localeCode ?? "en-UK")))

                let apiClient = PrimerAPIClient()
                apiClient.tokenizePaymentMethod(clientToken: decodedClientToken, paymentMethodTokenizationRequest: tokenizationRequest) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        seal.fulfill(paymentMethodToken)
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
    
        default:
            fatalError("Payment method card should never end here.")
        }
    }

    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
        self.paymentMethod = paymentMethodToken
        
        DispatchQueue.main.async {
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethodToken, resumeHandler: self)
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethodToken, { err in
                self.cardComponentsManager.setIsLoading(false)
                
                if let err = err {
                    self.handleFailedTokenizationFlow(error: err)
                } else {
                    self.handleSuccessfulTokenizationFlow()
                }
            })
        }
    }

    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, tokenizationFailedWith errors: [Error]) {
        submitButton.stopAnimating()
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        
        DispatchQueue.main.async {
            let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.checkoutFailed(with: err)
            self.handleFailedTokenizationFlow(error: err)
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

    private func fetchPollingUrl(for paymentMethodToken: PaymentMethodToken) -> Promise<URL> {
        return Promise { seal in
            self.onResumeHandlerCompletion = { (pollingUrl, err) in
                if let err = err {
                    seal.reject(err)
                } else if let pollingUrl = pollingUrl {
                    seal.fulfill(pollingUrl)
                }
                self.onResumeHandlerCompletion = nil
                self.onResumeTokenCompletion = nil
            }
            
            self.onResumeTokenCompletion = { err in
                if let err = err {
                    seal.reject(err)
                } else {
                    let err = PrimerError.invalidValue(key: "Polling URL", value: nil, userInfo: nil)
                    seal.reject(err)
                }
                
                self.onResumeHandlerCompletion = nil
                self.onResumeTokenCompletion = nil
            }
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: self)
        }
    }

    private func startPolling(on url: URL) -> Promise<String> {
        return Promise { seal in
            self.startPolling(on: url) { (id, err) in
                if let err = err {
                    seal.reject(err)
                } else if let id = id {
                    seal.fulfill(id)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
        }
    }
    
    private func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: ClientTokenService.decodedClientToken, url: url.absoluteString) { result in
            if self.completion == nil {
                let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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
                    let err = PrimerError.generic(message: "Should never end up here", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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
    
    private func passResumeToken(_ resumeToken: String) -> Promise<Void> {
        return Promise { seal in
            self.onResumeTokenCompletion = { err in
                if let err = err {
                    seal.reject(err)
                } else {
                    seal.fulfill()
                }
            }
            
            DispatchQueue.main.async {
                Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
            }
        }
    }

    fileprivate func enableSubmitButtonIfNeeded() {
        var validations = [
            cardNumberField.isTextValid,
            expiryDateField.isTextValid,
            cvvField.isTextValid
        ]

        if isShowingBillingAddressFieldsRequired { validations.append(postalCodeFieldView.isTextValid) }
        if let cardholderNameField = cardholderNameField, PrimerCardholderNameField.isCardholderNameFieldEnabled { validations.append(cardholderNameField.isTextValid) }

        if validations.allSatisfy({ $0 == true }) {
            submitButton.isEnabled = true
            submitButton.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            submitButton.isEnabled = false
            submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }
}

extension FormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {

    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        let isTextsValid = inputs.compactMap({ $0.primerTextFieldView?.isTextValid })
        
        if isTextsValid.contains(false) {
            enableConfirmButton(false)
        } else {
            enableConfirmButton(true)
        }
    }
    
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        return true
    }
    
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        return true
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {
        
    }
    
    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {

    }
    
}

extension FormPaymentMethodTokenizationViewModel {
    
    private func handle(_ clientToken: String) {
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if state.clientToken != clientToken {
            
            ClientTokenService.storeClientToken(clientToken) { error in
                DispatchQueue.main.async {

                    guard error == nil else {
                        ErrorHandler.handle(error: error!)
                        PrimerDelegateProxy.onResumeError(error!)
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

        switch config.type {
        case .adyenBlik:
            if decodedClientToken.intent?.contains("_REDIRECTION") == true,
                let statusUrlStr = decodedClientToken.statusUrl,
                let statusUrl = URL(string: statusUrlStr) {
                self.onResumeHandlerCompletion?(statusUrl, nil)
            } else if decodedClientToken.intent == RequiredActionName.checkout.rawValue {
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                
                firstly {
                    configService.fetchConfig()
                }
                .done {
                    self.continueTokenizationFlow()
                }
                .catch { err in
                    DispatchQueue.main.async {
                        Primer.shared.delegate?.onResumeError?(err)
                    }
                    self.handle(error: err)
                }
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                
                handle(error: err)
                DispatchQueue.main.async {
                    PrimerDelegateProxy.onResumeError(err)
                }
            }
        default:
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                #if canImport(Primer3DS)
                guard let paymentMethod = paymentMethod else {
                    DispatchQueue.main.async {
                        let err = ParserError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: containerErr)
                        PrimerDelegateProxy.onResumeError(containerErr)
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
                                        PrimerDelegateProxy.onResumeError(err)
                                        self.handle(error: err)
                                    }
                                    return
                                }
                            
                            PrimerDelegateProxy.onResumeSuccess(resumeToken, resumeHandler: self)
                        }
                        
                    case .failure(let err):
                        log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: containerErr)
                        DispatchQueue.main.async {
                            PrimerDelegateProxy.onResumeError(containerErr)
                        }
                    }
                }
                #else
                let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async {
                    PrimerDelegateProxy.onResumeError(err)
                }
                #endif
                
            } else if decodedClientToken.intent == RequiredActionName.checkout.rawValue {
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                
                firstly {
                    configService.fetchConfig()
                }
                .done {
                    self.continueTokenizationFlow()
                }
                .catch { err in
                    DispatchQueue.main.async {
                        Primer.shared.delegate?.onResumeError?(err)
                    }
                    self.handle(error: err)
                }
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                
                handle(error: err)
                DispatchQueue.main.async {
                    PrimerDelegateProxy.onResumeError(err)
                }
            }
        }
    }
}

extension FormPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        DispatchQueue.main.async {
            if self.onClientSessionActionCompletion != nil {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                self.onClientSessionActionCompletion?(error)
                self.onClientSessionActionCompletion = nil
            }

            switch self.config.type {
            case .adyenBlik:
                if self.onResumeHandlerCompletion != nil {
                    self.onResumeHandlerCompletion?(nil, error)
                    self.onResumeHandlerCompletion = nil
                }
                
                if self.onResumeTokenCompletion != nil {
                    self.onResumeTokenCompletion?(error)
                    self.onResumeTokenCompletion = nil
                }
            default:
                self.handleFailedTokenizationFlow(error: error)
                self.submitButton.stopAnimating()
                Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    override func handle(newClientToken clientToken: String) {
        self.handle(clientToken)
    }
    
    override func handleSuccess() {
        DispatchQueue.main.async {
            self.submitButton.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
            
            if self.onResumeTokenCompletion != nil {
                self.onResumeTokenCompletion?(nil)
                self.onResumeTokenCompletion = nil
            }
        }
    }
}

#endif
