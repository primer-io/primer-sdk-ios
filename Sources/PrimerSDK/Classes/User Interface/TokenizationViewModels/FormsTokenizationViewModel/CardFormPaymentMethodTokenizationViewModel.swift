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
    
    // MARK: - Properties
    
    private var flow: PaymentFlow
    private var cardComponentsManager: CardComponentsManager!
    var onConfigurationFetched: (() -> Void)?
    
    // FIXME: Is this the fix for the button's indicator?
    private var isTokenizing = false
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    var webViewController: SFSafariViewController?
    var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    var onResumeTokenCompletion: ((_ paymentMethod: PaymentMethodToken?, _ error: Error?) -> Void)?
    var onClientToken: ((_ clientToken: String?, _ err: Error?) -> Void)?
    var onClientSessionActionCompletion: ((Error?) -> Void)?

    var cardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = cardNetwork ?? .unknown
        }
    }
    
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
    
    // MARK: - Overrides
    
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
            return (Primer.shared.flow?.internalSessionFlow.vaulted ?? false)
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
        
    var isShowingBillingAddressFieldsRequired: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let billingAddressModuleOptions = state.primerConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first?.options as? PrimerConfiguration.CheckoutModule.PostalCodeOptions
        return billingAddressModuleOptions != nil
    }
    
    // MARK: - Card number field
    
    lazy var cardNumberField: PrimerCardNumberFieldView = {
        PrimerCardNumberField.cardNumberFieldViewWithDelegate(self)
    }()
    
    internal lazy var cardNumberContainerView: PrimerCustomFieldView = {
        PrimerCardNumberField.cardNumberContainerViewWithFieldView(cardNumberField)
    }()

    // MARK: - Cardholder name field

    internal lazy var cardholderNameField: PrimerCardholderNameFieldView? = {
        if !PrimerCardholderNameField.isCardholderNameFieldEnabled { return nil }
        return PrimerCardholderNameField.cardholderNameFieldViewWithDelegate(self)
    }()
    
    internal lazy var cardholderNameContainerView: PrimerCustomFieldView? = {
        if !PrimerCardholderNameField.isCardholderNameFieldEnabled { return nil }
        return PrimerCardholderNameField.cardholderNameContainerViewFieldView(cardholderNameField)
    }()
        
    // MARK: - Expiry date field
    
    internal lazy var expiryDateField: PrimerExpiryDateFieldView = {
        return PrimerEpiryDateField.expiryDateFieldViewWithDelegate(self)
    }()
    
    internal lazy var expiryDateContainerView: PrimerCustomFieldView = {
        return PrimerEpiryDateField.expiryDateContainerViewWithFieldView(expiryDateField)
    }()

    // MARK: - CVV field
    
    internal lazy var cvvField: PrimerCVVFieldView = {
        PrimerCVVField.cvvFieldViewWithDelegate(self)
    }()
        
    internal lazy var cvvContainerView: PrimerCustomFieldView = {
        PrimerCVVField.cvvContainerViewFieldView(cvvField)
    }()
    
    // MARK: - Billing address
        
    // MARK: First name
    
    internal lazy var firstNameFieldView: PrimerFirstNameFieldView = {
        PrimerFirstNameField.firstNameFieldViewWithDelegate(self)
    }()
        
    internal lazy var firstNameContainerView: PrimerCustomFieldView = {
        PrimerFirstNameField.firstNameFieldContainerViewFieldView(firstNameFieldView)
    }()
    
    internal var firstNameField: BillingAddressField {
        (firstNameFieldView, firstNameContainerView, billingAddressCheckoutModuleOptions?.firstName == false)
    }
    
    // MARK: Last name
    
    internal lazy var lastNameFieldView: PrimerLastNameFieldView = {
        PrimerLastNameField.lastNameFieldViewWithDelegate(self)
    }()
            
    internal lazy var lastNameContainerView: PrimerCustomFieldView = {
        PrimerLastNameField.lastNameFieldContainerViewFieldView(lastNameFieldView)
    }()
    
    internal var lastNameField: BillingAddressField {
        (lastNameFieldView, lastNameContainerView, billingAddressCheckoutModuleOptions?.lastName == false)
    }
    
    // MARK: Address Line 1

    internal lazy var addressLine1FieldView: PrimerAddressLine1FieldView = {
        PrimerAddressLine1Field.addressLine1FieldViewWithDelegate(self)
    }()
            
    internal lazy var addressLine1ContainerView: PrimerCustomFieldView = {
        PrimerAddressLine1Field.addressLine1ContainerViewFieldView(addressLine1FieldView)
    }()
    
    internal var addressLine1Field: BillingAddressField {
        (addressLine1FieldView, addressLine1ContainerView, billingAddressCheckoutModuleOptions?.addressLine1 == false)
    }

    // MARK: Address Line 2

    internal lazy var addressLine2FieldView: PrimerAddressLine2FieldView = {
        PrimerAddressLine2Field.addressLine2FieldViewWithDelegate(self)
    }()
            
    internal lazy var addressLine2ContainerView: PrimerCustomFieldView = {
        PrimerAddressLine2Field.addressLine2ContainerViewFieldView(addressLine2FieldView)
    }()
    
    internal var addressLine2Field: BillingAddressField {
        (addressLine2FieldView, addressLine2ContainerView, billingAddressCheckoutModuleOptions?.addressLine2 == false)
    }
    
    // MARK: City

    internal lazy var cityFieldView: PrimerCityFieldView = {
        PrimerCityField.cityFieldViewWithDelegate(self)
    }()
            
    internal lazy var cityContainerView: PrimerCustomFieldView = {
        PrimerCityField.cityFieldContainerViewFieldView(cityFieldView)
    }()
    
    internal var cityField: BillingAddressField {
        (cityFieldView, cityContainerView, billingAddressCheckoutModuleOptions?.city == false)
    }
    
    // MARK: State

    internal lazy var stateFieldView: PrimerStateFieldView = {
        PrimerStateField.stateFieldViewWithDelegate(self)
    }()
            
    internal lazy var stateContainerView: PrimerCustomFieldView = {
        PrimerStateField.stateFieldContainerViewFieldView(stateFieldView)
    }()
    
    internal var stateField: BillingAddressField {
        (stateFieldView, stateContainerView, billingAddressCheckoutModuleOptions?.state == false)
    }

    // MARK: Postal code
    
    internal lazy var postalCodeFieldView: PrimerPostalCodeFieldView = {
        PrimerPostalCodeField.postalCodeViewWithDelegate(self)
    }()
        
    internal lazy var postalCodeContainerView: PrimerCustomFieldView = {
        PrimerPostalCodeField.postalCodeContainerViewFieldView(postalCodeFieldView)
    }()
    
    internal var postalCodeField: BillingAddressField {
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
    
    // MARK: - Init
    
    required init(config: PaymentMethodConfig) {
        self.flow = (Primer.shared.flow?.internalSessionFlow.vaulted ?? false) ? .vault : .checkout
        super.init(config: config)
        
        let billingAddressFieldViews = billingAddressFields.flatMap { $0 }.map { $0.fieldView }
        
        self.cardComponentsManager = CardComponentsManager(
            flow: flow,
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField,
            billingAddressFieldViews: billingAddressFieldViews
        )
        cardComponentsManager.delegate = self
    }
    
    // MARK: - Functions Overrides
    
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
    override func presentNativeUI() {
        let cfvc = PrimerCardFormViewController(viewModel: self)
        Primer.shared.primerRootVC?.show(viewController: cfvc)
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
                Primer.shared.delegate?.checkoutFailed?(with: error)
                self.handleFailedTokenizationFlow(error: error)
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
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    fileprivate func continueTokenizationFlow() {
        do {
            try self.validate()
        } catch {
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        switch config.type {
        case .adyenBlik:
            DispatchQueue.main.async {
                
            }
        default:
            break
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
                        Primer.shared.delegate?.onResumeError?(err)
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
    
    internal func presentWeb3DS(with pollingUrls: PollingURLs) {
        DispatchQueue.main.async { [unowned self] in
            guard let redirectUrl = URL(string: pollingUrls.redirect) else {
                let err = PrimerError.invalidUrl(url: pollingUrls.redirect, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.onResumeError(err)
                return
            }
            
            guard let statusUrl = URL(string: pollingUrls.status) else {
                let err = PrimerError.invalidUrl(url: pollingUrls.status, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.onResumeError(err)
                return
            }
            
            self.willPresentExternalView?()
            
            self.webViewCompletion = { (id, err) in
                DispatchQueue.main.async {
                    self.willDismissExternalView?()
                    self.webViewController?.dismiss(animated: true, completion: {
                        self.didDismissExternalView?()
                    })
                }
                
                if let err = err {
                    ErrorHandler.handle(error: err)
                    PrimerDelegateProxy.onResumeError(err)
                } else if let id = id {
                    PrimerDelegateProxy.onResumeSuccess(id, resumeHandler: self)
                } else {
                    assert(true, "Should have received an id or an error")
                }
            }
            
            self.webViewController = SFSafariViewController(url: redirectUrl)
            self.webViewController?.delegate = self
            
            self.willPresentExternalView?()
            Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                DispatchQueue.main.async {
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPaymentMethodPresented()
                }
            })
            
            self.startPolling(on: statusUrl) { id, err in
                self.webViewCompletion?(id, err)
            }
        }
    }
    
    fileprivate func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: ClientTokenService.decodedClientToken, url: url.absoluteString) { result in
            if self.webViewCompletion == nil {
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
                    let err = PrimerError.generic(message: "Should never end up here, retry", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                        self.startPolling(on: url, completion: completion)
                    }
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

}

extension CardFormPaymentMethodTokenizationViewModel: CardComponentsManagerDelegate {
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
        self.paymentMethod = paymentMethodToken
        
        DispatchQueue.main.async {
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
            }
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: self)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { err in
                self.cardComponentsManager.setIsLoading(false)
                
                if let err = err {
                    self.handleFailedTokenizationFlow(error: err)
                } else {
                    self.handleSuccessfulTokenizationFlow()
                }
            })
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
            Primer.shared.delegate?.checkoutFailed?(with: err)
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
                postalCodeContainerView.errorText = "\(PrimerPostalCodeField.localPostalCodeTitle) is required" // todo: localise if UK, etc.
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
        
        if isShowingBillingAddressFieldsRequired { validations.append(postalCodeFieldView.isTextValid) }
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

extension CardFormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: true)
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        // Dispatch postal code action if valid postal code.
        if let fieldView = (primerTextFieldView as? PrimerPostalCodeFieldView), isValid  == true {
            let state: AppStateProtocol = DependencyContainer.resolve()
            
            let currentBillingAddress = state.primerConfiguration?.clientSession?.customer?.billingAddress
            
            let params = [
                "firstName": currentBillingAddress?.firstName as Any,
                "lastName": currentBillingAddress?.lastName as Any,
                "addressLine1": currentBillingAddress?.addressLine1 as Any,
                "addressLine2": currentBillingAddress?.addressLine2 as Any,
                "city": currentBillingAddress?.city as Any,
                "postalCode": fieldView.postalCode,
                "state": currentBillingAddress?.state as Any,
                "countryCode": currentBillingAddress?.countryCode as Any
            ] as [String: Any]
            
            ClientSession.Action.setPostalCode(resumeHandler: self, withParameters: params)
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
            
            ClientSession.Action.selectPaymentMethod(resumeHandler: self, withParameters: params)
            cardNumberContainerView.rightImage2 = cardNetwork.icon
        } else if cardNumberContainerView.rightImage2 != nil && cardNetwork?.icon == nil {
            cardNumberContainerView.rightImage2 = nil
            ClientSession.Action.unselectPaymentMethod(resumeHandler: self)
        }
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
                        
                        Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
                    }
                    
                case .failure(let err):
                    log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: containerErr)
                    self.handle(error: err)
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
            
        } else if decodedClientToken.intent == RequiredActionName.processor3DS.rawValue {
            if let redirectUrl = decodedClientToken.redirectUrl,
               let statusUrl = decodedClientToken.statusUrl {
                let pollingUrls = PollingURLs(status: statusUrl, redirect: redirectUrl, complete: nil)
                self.presentWeb3DS(with: pollingUrls)
                
            } else {
                let err = PrimerError.invalidValue(key: "Polling parameters", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.onResumeError(err)
            }

        } else if decodedClientToken.intent == RequiredActionName.checkout.rawValue {
            let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            
            firstly {
                configService.fetchConfig()
            }
            .done {
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                if let amount = settings.amount, !self.isTokenizing {
                    self.configurePayButton(amount: amount)
                }
                
                // determine postal code textfield visibility
                self.onConfigurationFetched?()
                
                self.onClientSessionActionCompletion?(nil)
            }
            .catch { err in
                self.onClientSessionActionCompletion?(err)
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

extension CardFormPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        DispatchQueue.main.async {
            if self.onClientSessionActionCompletion != nil {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                self.onClientSessionActionCompletion?(error)
                self.onClientSessionActionCompletion = nil
            }
            
            self.handleFailedTokenizationFlow(error: error)
            self.submitButton.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        
        completion?(nil, error)
    }
    
    override func handle(newClientToken clientToken: String) {
        self.handle(clientToken)
    }
    
    override func handleSuccess() {
        DispatchQueue.main.async {
            self.submitButton.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        completion?(paymentMethod, nil)
    }
}

extension CardFormPaymentMethodTokenizationViewModel: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(paymentMethodType: config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            webViewCompletion(nil, err)
        }
        
        webViewCompletion = nil
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if didLoadSuccessfully {
            self.didPresentExternalView?()
        }
    }
    
}

#endif
