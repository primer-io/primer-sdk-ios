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

class FormTokenizationModule: TokenizationModule, SearchableItemsPaymentMethodTokenizationViewModelProtocol {
    
    // MARK: - Properties
    
    var inputs: [Input] = []
    
    private var cardComponentsManager: CardComponentsManager!
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    var didCancel: (() -> Void)?
    
    
    var countriesDataSource = CountryCode.allCases {
        didSet {
            tableView.reloadData()
        }
    }
    
    var phoneNumberCountryCodesDataSource = CountryCode.phoneNumberCountryCodes {
        didSet {
            tableView.reloadData()
        }
    }
    
    var phoneNumberCountryCodes = CountryCode.phoneNumberCountryCodes
    var countries = CountryCode.allCases
    
    lazy var inputTextFieldsStackViews: [UIStackView] = {
        return self.paymentMethodModule.userInterfaceModule.createInputTextFieldsStackViews(inputs: inputs, textFieldsDelegate: self)
    }()
    
    internal lazy var tableView: UITableView = {
        return self.paymentMethodModule.userInterfaceModule.createCountriesTableView(dataSource: self, delegate: self)
    }()
    
    internal lazy var searchableTextField: PrimerSearchTextField = {
        return self.paymentMethodModule.userInterfaceModule.createSearchableTextFiel(delegate: self)
    }()
    
    var cardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = cardNetwork ?? .unknown
        }
    }
    
    var isShowingBillingAddressFieldsRequired: Bool {
        let billingAddressModuleOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
        return billingAddressModuleOptions != nil
    }
    
    internal lazy var countrySelectorViewController: CountrySelectorViewController = {
        CountrySelectorViewController(delegate: self, paymentMethod: self.paymentMethodModule.paymentMethodConfiguration)
    }()
    
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
    
    private var countryField: BillingAddressField {
        (countryFieldView, countryFieldContainerView, billingAddressCheckoutModuleOptions?.countryCode == false)
    }
    
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
    
    // MARK: Country
    
    private lazy var countryFieldView: PrimerCountryFieldView = {
        PrimerCountryField.countryFieldViewWithDelegate(self)
    }()
    
    private lazy var countryFieldContainerView: PrimerCustomFieldView = {
        PrimerCountryField.countryContainerViewFieldView(countryFieldView, openCountriesListPressed: {
            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.show(viewController: self.countrySelectorViewController)
            }
        })
    }()
    
    // MARK: All billing address fields
    
    internal var billingAddressCheckoutModuleOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? {
        return PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
    }
    
    internal var billingAddressFields: [[BillingAddressField]] {
        guard isShowingBillingAddressFieldsRequired else { return [] }
        return [
            [countryField],
            [firstNameField, lastNameField],
            [addressLine1Field],
            [addressLine2Field],
            [postalCodeField, cityField],
            [stateField],
        ]
    }
    
    internal var allVisibleBillingAddressFieldViews: [PrimerTextFieldView] {
        billingAddressFields.flatMap { $0.filter { $0.isFieldHidden == false } }.map { $0.fieldView }
    }
    
    internal var allVisibleBillingAddressFieldContainerViews: [[PrimerCustomFieldView]] {
        let allVisibleBillingAddressFields = billingAddressFields.map { $0.filter { $0.isFieldHidden == false } }
        return allVisibleBillingAddressFields.map { $0.map { $0.containerFieldView } }
    }
    
    internal var formView: PrimerFormView {
        var formViews: [[UIView?]] = [
            [cardNumberContainerView],
            [expiryDateContainerView, cvvContainerView],
            [cardholderNameContainerView],
        ]
        formViews.append(contentsOf: allVisibleBillingAddressFieldContainerViews)
        return PrimerFormView(frame: .zero, formViews: formViews)
    }
    
    
    // MARK: Account Info Payment Methods Array
    
    /// Array containing the payment method types expecting some account info
    /// to transfer the founds to
    let accountInfoPaymentMethodTypes: [PrimerPaymentMethodType] = [.rapydFast]
    
    // MARK: Payment Pending Info Array
    
    /// Dictionary containing the payment method types expecting to show a view with the Payment Logo and a message
    /// informing the user to complete the payment outside of the current Application context
    let needingExternalCompletionPaymentMethodDictionary: [PrimerPaymentMethodType: String] = [.adyenMBWay: Strings.MBWay.completeYourPayment,
                                                                                               .adyenBlik: Strings.Blik.completeYourPayment]
    
    // MARK: Account Info Payment
    
    /// Generic info view
    var infoView: PrimerFormView?
    
    // MARK: Input completion block
    
    /// Input completion block callback
    var userInputCompletion: (() -> Void)?
    
    var voucherConfirmationInfoView: PrimerFormView {
        
        // Complete your payment
        
        let confirmationTitleLabel = UILabel()
        confirmationTitleLabel.text = Strings.VoucherInfoConfirmationSteps.confirmationStepTitle
        confirmationTitleLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.title)
        confirmationTitleLabel.textColor = theme.text.title.color
        
        // Confirmation steps
        
        let confirmationStepContainerStackView = PrimerStackView()
        confirmationStepContainerStackView.axis = .vertical
        confirmationStepContainerStackView.spacing = 16.0
        confirmationStepContainerStackView.isLayoutMarginsRelativeArrangement = true
        
        let stepsTexts = [Strings.VoucherInfoConfirmationSteps.confirmationStep1LabelText,
                          Strings.VoucherInfoConfirmationSteps.confirmationStep2LabelText,
                          Strings.VoucherInfoConfirmationSteps.confirmationStep3LabelText]
        
        for stepsText in stepsTexts {
            
            let confirmationStepLabel = UILabel()
            confirmationStepLabel.textColor = .gray600
            confirmationStepLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
            confirmationStepLabel.numberOfLines = 0
            confirmationStepLabel.text = stepsText
            
            confirmationStepContainerStackView.addArrangedSubview(confirmationStepLabel)
        }
        
        let views = [[confirmationTitleLabel],
                     [confirmationStepContainerStackView]]
        
        return PrimerFormView(formViews: views)
    }
    
    // MARK: Voucher Info View
    
    var voucherInfoView: PrimerFormView {
        
        // Complete your payment
        
        let completeYourPaymentLabel = UILabel()
        completeYourPaymentLabel.text = Strings.VoucherInfoPaymentView.completeYourPayment
        completeYourPaymentLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.title)
        completeYourPaymentLabel.textColor = theme.text.title.color
        
        let descriptionLabel = UILabel()
        descriptionLabel.textColor = .gray600
        descriptionLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = Strings.VoucherInfoPaymentView.descriptionLabel
        
        // Expires at
        
        let expiresAtContainerStackView = UIStackView()
        expiresAtContainerStackView.axis = .horizontal
        expiresAtContainerStackView.spacing = 8.0
        
        let calendarImage = UIImage(named: "calendar", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let calendarImageView = UIImageView(image: calendarImage)
        calendarImageView.tintColor = .gray600
        calendarImageView.clipsToBounds = true
        calendarImageView.contentMode = .scaleAspectFit
        expiresAtContainerStackView.addArrangedSubview(calendarImageView)
        
        if let expDate = PrimerAPIConfigurationModule.decodedJWTToken?.expiresAt {
            let expiresAtPrefixLabel = UILabel()
            let expiresAtAttributedString = NSMutableAttributedString()
            let prefix = NSAttributedString(
                string: Strings.VoucherInfoPaymentView.expiresAt,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray600])
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let expiresAtDate = NSAttributedString(
                string: formatter.string(from: expDate),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            expiresAtAttributedString.append(prefix)
            expiresAtAttributedString.append(NSAttributedString(string: " ", attributes: nil))
            expiresAtAttributedString.append(expiresAtDate)
            expiresAtPrefixLabel.attributedText = expiresAtAttributedString
            expiresAtPrefixLabel.numberOfLines = 0
            expiresAtPrefixLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
            expiresAtContainerStackView.addArrangedSubview(expiresAtPrefixLabel)
        }
        
        // Voucher info container Stack View
        
        let voucherInfoContainerStackView = PrimerStackView()
        voucherInfoContainerStackView.axis = .vertical
        voucherInfoContainerStackView.spacing = 12.0
        voucherInfoContainerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        voucherInfoContainerStackView.layer.cornerRadius = PrimerDimensions.cornerRadius / 2
        voucherInfoContainerStackView.layer.borderColor = UIColor.gray200.cgColor
        voucherInfoContainerStackView.layer.borderWidth = 2.0
        voucherInfoContainerStackView.isLayoutMarginsRelativeArrangement = true
        voucherInfoContainerStackView.layer.cornerRadius = 8.0
                        
        for voucherValue in VoucherValue.currentVoucherValues {
            
            if voucherValue.value != nil {
                
                let voucherValueStackView = PrimerStackView()
                voucherValueStackView.axis = .horizontal
                voucherValueStackView.spacing = 12.0
                voucherValueStackView.distribution = .fillProportionally
                
                let voucherValueLabel = UILabel()
                voucherValueLabel.text = voucherValue.description
                voucherValueLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
                voucherValueLabel.textColor = .gray600
                voucherValueStackView.addArrangedSubview(voucherValueLabel)
                
                let voucherValueText = UILabel()
                voucherValueText.text = voucherValue.value
                voucherValueText.font = UIFont.boldSystemFont(ofSize: PrimerDimensions.Font.label)
                voucherValueText.textColor = theme.text.title.color
                voucherValueText.setContentHuggingPriority(.required, for: .horizontal)
                voucherValueText.setContentCompressionResistancePriority(.required, for: .horizontal)
                voucherValueStackView.addArrangedSubview(voucherValueText)
                                
                voucherInfoContainerStackView.addArrangedSubview(voucherValueStackView)
                
                if let lastValue = VoucherValue.currentVoucherValues.last, voucherValue != lastValue  {
                    // Separator view
                    let separatorView = PrimerView()
                    separatorView.backgroundColor = .gray200
                    separatorView.translatesAutoresizingMaskIntoConstraints = false
                    separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
                    voucherInfoContainerStackView.addArrangedSubview(separatorView)
                }
            }
        }
        
        //        let copyToClipboardImage = UIImage(named: "copy-to-clipboard", in: Bundle.primerResources, compatibleWith: nil)
        //        let copiedToClipboardImage = UIImage(named: "check-circle", in: Bundle.primerResources, compatibleWith: nil)
        //        let copyToClipboardButton = UIButton(type: .custom)
        //        copyToClipboardButton.setImage(copyToClipboardImage, for: .normal)
        //        copyToClipboardButton.setImage(copiedToClipboardImage, for: .selected)
        //        copyToClipboardButton.translatesAutoresizingMaskIntoConstraints = false
        //        copyToClipboardButton.addTarget(self, action: #selector(copyToClipboardTapped), for: .touchUpInside)
        //        entityStackView.addArrangedSubview(copyToClipboardButton)
        
//        self.paymentMethodModule.userInterfaceModule.submitButton = nil
        
        let views = [[completeYourPaymentLabel],
                     [expiresAtContainerStackView],
                     [voucherInfoContainerStackView]]
        
        return PrimerFormView(formViews: views)
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
    
    override func start() -> Promise<PrimerPaymentMethodTokenData> {
//        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedNotification(_:)), name: Notification.Name.urlSchemeRedirect, object: nil)
        
        return super.start()
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
                
                guard let blikCode = inputs.first?.text else {
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
                
                guard let phoneNumber = inputs.first?.text else {
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
}

extension FormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {}
    // MARK: - FORM SPECIFIC FUNCTIONALITY
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        let isTextsValid = inputs.allSatisfy { $0.primerTextFieldView?.isTextValid == true }
        isTextsValid ? enableSubmitButton(true) : enableSubmitButton(false)
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
//        [.adyenBlik, .adyenMBWay, .adyenMultibanco]
        
        switch self.paymentMethodModule.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.adyenBlik.rawValue,
            PrimerPaymentMethodType.adyenMBWay.rawValue:
            return presentInputViewController()
            
        case PrimerPaymentMethodType.adyenMultibanco.rawValue:
            return presentVoucherInfoConfirmationStepViewController()
            
        default:
            return Promise()
        }
    }
    
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        true
    func presentInputViewController() -> Promise<Void> {
        return Promise { seal in
            let pcfvc = PrimerInputViewController(
                navigationBarLogo: self.paymentMethodModule.userInterfaceModule.invertedLogo,
                formTokenizationModule: self,
                inputsDistribution: .horizontal)
            inputs.append(contentsOf: makeInputViews())
            PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
            seal.fulfill()
        }
    }
    
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        true
    func presentVoucherInfoConfirmationStepViewController() -> Promise<Void> {
        return Promise { seal in
            let pcfvc = PrimerAccountInfoPaymentViewController(navigationBarLogo: self.paymentMethodModule.userInterfaceModule.invertedLogo, formTokenizationModule: self)
            infoView = voucherConfirmationInfoView
            PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
            seal.fulfill()
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {}
    func makeInputViews() -> [Input] {
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodModule.paymentMethodConfiguration.type) else { return [] }
        
        switch paymentMethodType {
        case .adyenBlik:
            return [self.paymentMethodModule.userInterfaceModule.adyenBlikInputView]
        case .adyenMBWay:
            return [self.paymentMethodModule.userInterfaceModule.mbwayInputView]
        default:
            return []
        }
    }
    
    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {}
    func enableSubmitButton(_ flag: Bool) {
        self.paymentMethodModule.userInterfaceModule.submitButton?.isEnabled = flag
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        self.paymentMethodModule.userInterfaceModule.submitButton?.backgroundColor = flag ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
    }
    
    func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.userInputCompletion = {
                seal.fulfill()
            }
        }
    }
    
    @objc
    override func submitButtonTapped() {
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

extension FormTokenizationModule: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countriesDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let country = countriesDataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CountryTableViewCell.className, for: indexPath) as! CountryTableViewCell
        cell.configure(viewModel: country)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let country = self.countriesDataSource[indexPath.row]
            countryFieldView.textField.text = "\(country.flag) \(country.country)"
            countryFieldView.countryCode = country
            countryFieldView.validation = .valid
            countryFieldView.textFieldDidEndEditing(countryFieldView.textField)
            PrimerUIManager.primerRootViewController?.popViewController()
    }
}

extension FormTokenizationModule: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string == "\n" {
            // Keyboard's return button tapoped
            textField.resignFirstResponder()
            return false
        }
        
        var query: String
        
        if string.isEmpty {
            query = String((textField.text ?? "").dropLast())
        } else {
            query = (textField.text ?? "") + string
        }
        
        if query.isEmpty {
            countriesDataSource = countries
            return true
        }
        
        var countryResults: [CountryCode] = []
        
        for country in countries {
            if country.country.lowercased().folding(options: .diacriticInsensitive, locale: nil).contains(query.lowercased().folding(options: .diacriticInsensitive, locale: nil)) == true {
                countryResults.append(country)
            }
        }
        
        countriesDataSource = countryResults
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        countriesDataSource = countries
        return true
    }
}

extension FormTokenizationModule: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {}
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        let isTextsValid = inputs.allSatisfy { $0.primerTextFieldView?.isTextValid == true }
        isTextsValid ? enableSubmitButton(true) : enableSubmitButton(false)
    }
    
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        true
    }
    
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        true
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {}
    
    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {}
}

#endif

