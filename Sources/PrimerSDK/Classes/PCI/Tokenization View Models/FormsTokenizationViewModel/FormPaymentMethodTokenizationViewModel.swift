//
//  PrimerAccountInfoPaymentViewController.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

// swiftlint:disable identifier_name
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

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

class FormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel, SearchableItemsPaymentMethodTokenizationViewModelProtocol {

    // MARK: - Properties

    var inputs: [Input] = []
    private var didCancelPolling: (() -> Void)?

    private var cardComponentsManager: InternalCardComponentsManager!
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    private static let countryCodeFlag = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode?.flag ?? ""
    private static let countryDialCode = CountryCode.phoneNumberCountryCodes.first(where: {
        $0.code == PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode?.rawValue
    })?.dialCode ?? ""

    var inputTextFieldsStackViews: [UIStackView] {
        var stackViews: [UIStackView] = []

        for input in self.inputs {

            let stackView = UIStackView()
            stackView.spacing = 2
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fillProportionally

            let inputStackView = UIStackView()
            inputStackView.spacing = 2
            inputStackView.axis = .vertical
            inputStackView.alignment = .fill
            inputStackView.distribution = .fill

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
            inputStackView.addArrangedSubview(inputContainerView)

            if let descriptor = input.descriptor {
                let lbl = UILabel()
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.translatesAutoresizingMaskIntoConstraints = false
                lbl.text = descriptor
                inputStackView.addArrangedSubview(lbl)
            }

            if self.config.type == PrimerPaymentMethodType.adyenMBWay.rawValue {
                let phoneNumberLabelStackView = UIStackView()
                phoneNumberLabelStackView.spacing = 2
                phoneNumberLabelStackView.axis = .vertical
                phoneNumberLabelStackView.alignment = .fill
                phoneNumberLabelStackView.distribution = .fill
                phoneNumberLabelStackView.addArrangedSubview(mbwayTopLabelView)
                inputTextFieldView.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
                stackViews.insert(phoneNumberLabelStackView, at: 0)
                stackView.addArrangedSubview(prefixSelectorButton)
            }

            stackView.addArrangedSubview(inputStackView)
            stackViews.append(stackView)
        }

        return stackViews
    }

    // MARK: Adyen MBWay PhoneNumber prefix view

    var prefixSelectorButton: PrimerButton = {
        let prefixSelectorButton = PrimerButton()
        prefixSelectorButton.isAccessibilityElement = true
        prefixSelectorButton.accessibilityIdentifier = "prefix_selector_btn"
        prefixSelectorButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        prefixSelectorButton.setTitle("\(FormPaymentMethodTokenizationViewModel.countryCodeFlag) \(FormPaymentMethodTokenizationViewModel.countryDialCode)", for: .normal)
        prefixSelectorButton.setTitleColor(.black, for: .normal)
        prefixSelectorButton.clipsToBounds = true
        prefixSelectorButton.isUserInteractionEnabled = false
        prefixSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        prefixSelectorButton.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
        prefixSelectorButton.contentVerticalAlignment = .top
        return prefixSelectorButton
    }()

    // MARK: Adyen MBWay Input View

    var mbwayTopLabelView: UILabel = {
        let label = UILabel()
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        label.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        label.text = Strings.MBWay.inputTopPlaceholder
        label.textColor = theme.text.system.color
        return label
    }()

    var mbwayInputView: Input = {
        let input1 = Input()
        input1.keyboardType = .numberPad
        input1.allowedCharacterSet = CharacterSet(charactersIn: "0123456789")
        input1.isValid = { text in
            return text.isNumeric && text.count >= 8
        }
        return input1
    }()

    // MARK: Adyen Blik Input View

    var adyenBlikInputView: Input = {
        let input1 = Input()
        input1.name = "OTP"
        input1.topPlaceholder = Strings.Blik.inputTopPlaceholder
        input1.textFieldPlaceholder = Strings.Blik.inputTextFieldPlaceholder
        input1.keyboardType = .numberPad
        input1.descriptor = Strings.Blik.inputDescriptor
        input1.allowedCharacterSet = CharacterSet.decimalDigits
        input1.maxCharactersAllowed = 6
        input1.isValid = { text in
            return text.isNumeric && text.count >= 6
        }
        return input1
    }()

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

    internal lazy var tableView: UITableView = {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = theme.view.backgroundColor
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.rowHeight = 41
        tableView.register(CountryTableViewCell.self, forCellReuseIdentifier: CountryTableViewCell.className)

        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    internal lazy var searchableTextField: PrimerSearchTextField = {
        let textField = PrimerSearchTextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textField.delegate = self
        textField.borderStyle = .none
        textField.layer.cornerRadius = 3.0
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.placeholder = Strings.CountrySelector.searchCountryTitle
        textField.rightViewMode = .always
        return textField
    }()

    var cardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = cardNetwork ?? .unknown
        }
    }

    var isShowingBillingAddressFieldsRequired: Bool {
        let billingAddressModuleOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
            .first { $0.type == "BILLING_ADDRESS" }?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
        return billingAddressModuleOptions != nil
    }

    internal lazy var countrySelectorViewController: CountrySelectorViewController = {
        CountrySelectorViewController(viewModel: self)
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
                self.uiManager.primerRootViewController?.show(viewController: self.countrySelectorViewController)
            }
        })
    }()

    // MARK: All billing address fields

    internal var billingAddressCheckoutModuleOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? {
        return PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
            .filter({ $0.type == "BILLING_ADDRESS" })
            .first?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
    }

    internal var billingAddressFields: [[BillingAddressField]] {
        guard isShowingBillingAddressFieldsRequired else { return [] }
        return [
            [countryField],
            [firstNameField, lastNameField],
            [addressLine1Field],
            [addressLine2Field],
            [postalCodeField, cityField],
            [stateField]
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
            [cardholderNameContainerView]
        ]
        formViews.append(contentsOf: allVisibleBillingAddressFieldContainerViews)
        return PrimerFormView(frame: .zero, formViews: formViews)
    }

    // MARK: Input Payment Methods Array

    /// Array containing the payment method types expecting some input step to be performed
    let inputPaymentMethodTypes: [PrimerPaymentMethodType] = [.adyenBlik, .adyenMBWay]

    // MARK: Voucher Info Payment Methods Array

    /// Array containing the payment method types issuing a voucher
    let voucherPaymentMethodTypes: [PrimerPaymentMethodType] = [.adyenMultibanco]

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

    // MARK: - Payment Flow

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "clientToken.pciUrl",
                                               value: decodedJWTToken.pciUrl,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        if PrimerInternal.shared.intent == .checkout {
            if AppState.current.amount == nil {
                let err = PrimerError.invalidValue(key: "amount",
                                                   value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            if AppState.current.currency == nil {
                let err = PrimerError.invalidValue(key: "currency",
                                                   value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: self.config.type,
                url: nil),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .cardForm
        )
        Analytics.Service.record(event: event)

        let imageView = self.uiModule.makeIconImageView(withDimension: 24.0)
        self.uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imageView,
                                                                            message: nil)

        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then {
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then {
                return self.presentPaymentMethodUserInterface()
            }
            .then {
                return self.evaluatePaymentMethodNeedingFurtherUserActions()
            }
            .then {
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
                self.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
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

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                if let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {

                    let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type)
                    let isPaymentMethodNeedingExternalCompletion = (needingExternalCompletionPaymentMethodDictionary
                                                                        .first { $0.key == paymentMethodType } != nil) == true

                    firstly {
                        self.presentPaymentMethodAppropriateViewController(shouldCompletePaymentExternally: isPaymentMethodNeedingExternalCompletion)
                    }
                    .then { () -> Promise<String> in
                        let pollingModule = PollingModule(url: statusUrl)
                        self.didCancel = {
                            let err = PrimerError.cancelled(
                                paymentMethodType: self.config.type,
                                userInfo: .errorUserInfoDictionary(),
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            pollingModule.cancel(withError: err)
                            return
                        }

                        return pollingModule.start()
                    }
                    .done { resumeToken in
                        seal.fulfill(resumeToken)
                    }
                    .ensure {
                        self.didCancel = nil
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    let error = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                    seal.reject(error)
                }
            } else if decodedJWTToken.intent == RequiredActionName.paymentMethodVoucher.rawValue {

                let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
                var additionalInfo: PrimerCheckoutAdditionalInfo?

                switch self.config.type {
                case PrimerPaymentMethodType.adyenMultibanco.rawValue:

                    let formatter = DateFormatter().withExpirationDisplayDateFormat()

                    var expiresAtAdditionalInfo: String?
                    if let unwrappedExpiresAt = decodedJWTToken.expiresAt {
                        expiresAtAdditionalInfo = formatter.string(from: unwrappedExpiresAt)
                    }

                    additionalInfo = MultibancoCheckoutAdditionalInfo(expiresAt: expiresAtAdditionalInfo,
                                                                      entity: decodedJWTToken.entity,
                                                                      reference: decodedJWTToken.reference)

                    if self.paymentCheckoutData == nil {
                        self.paymentCheckoutData = PrimerCheckoutData(payment: nil, additionalInfo: additionalInfo)
                    } else {
                        self.paymentCheckoutData?.additionalInfo = additionalInfo
                    }

                default:
                    self.logger.info(message: "UNHANDLED PAYMENT METHOD RESULT")
                    self.logger.info(message: self.config.type)
                }

                if isManualPaymentHandling {
                    PrimerDelegateProxy.primerDidEnterResumePendingWithPaymentAdditionalInfo(additionalInfo)
                    seal.fulfill(nil)
                } else {
                    seal.fulfill(nil)
                }
            }
        }
    }

    private func evaluatePaymentMethodNeedingFurtherUserActions() -> Promise<Void> {

        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type),
              inputPaymentMethodTypes.contains(paymentMethodType) ||
                voucherPaymentMethodTypes.contains(paymentMethodType)
        else {
            return Promise()
        }

        return self.awaitUserInput()
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {

        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type),
              inputPaymentMethodTypes.contains(paymentMethodType) ||
                voucherPaymentMethodTypes.contains(paymentMethodType)
        else {
            return Promise()
        }

        return self.presentPaymentMethodAppropriateViewController()
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.userInputCompletion = {
                seal.fulfill()
            }
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.config.type)
        }
    }

    fileprivate func enableSubmitButton(_ flag: Bool) {
        self.uiModule.submitButton?.isEnabled = flag
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let colorState: ColorState = flag ? .enabled : .disabled
        self.uiModule.submitButton?.backgroundColor = theme.mainButton.color(for: colorState)
    }

    override func submitButtonTapped() {

        let viewEvent = Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: self.config.type,
                url: nil),
            extra: nil,
            objectType: .button,
            objectId: .submit,
            objectClass: "\(Self.self)",
            place: .cardForm
        )
        Analytics.Service.record(event: viewEvent)

        switch config.type {
        case PrimerPaymentMethodType.adyenBlik.rawValue,
             PrimerPaymentMethodType.adyenMBWay.rawValue,
             PrimerPaymentMethodType.adyenMultibanco.rawValue:
            self.uiModule.submitButton?.startAnimating()
            self.userInputCompletion?()

        default:
            fatalError("Must be overridden")
        }
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        guard let configId = config.id else {
            let err = PrimerError.invalidValue(key: "configuration.id",
                                               value: config.id,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return Promise { $0.reject(err) }
        }

        switch config.type {
        case PrimerPaymentMethodType.adyenBlik.rawValue:
            return Promise { seal in
                guard let blikCode = inputs.first?.text else {
                    let err = PrimerError.invalidValue(key: "blikCode",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let sessionInfo = BlikSessionInfo(
                    blikCode: blikCode,
                    locale: PrimerSettings.current.localeData.localeCode)

                let paymentInstrument = OffSessionPaymentInstrument(
                    paymentMethodConfigId: configId,
                    paymentMethodType: config.type,
                    sessionInfo: sessionInfo)

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
                .done { paymentMethod in
                    seal.fulfill(paymentMethod)
                }
                .catch { err in
                    seal.reject(err)
                }
            }

        case PrimerPaymentMethodType.adyenMBWay.rawValue:
            return Promise { seal in
                guard let phoneNumber = inputs.first?.text else {
                    let err = PrimerError.invalidValue(key: "phoneNumber",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let fullPhoneNumber = "\(FormPaymentMethodTokenizationViewModel.countryDialCode)\(phoneNumber)"
                let sessionInfo = InputPhonenumberSessionInfo(phoneNumber: fullPhoneNumber)

                let paymentInstrument = OffSessionPaymentInstrument(
                    paymentMethodConfigId: configId,
                    paymentMethodType: config.type,
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
                .done { paymentMethod in
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

    override func handleSuccessfulFlow() {

        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type) else {
            return
        }

        if voucherPaymentMethodTypes.contains(paymentMethodType) {

            presentVoucherInfoViewController()

        } else if accountInfoPaymentMethodTypes.contains(paymentMethodType) {

            presentAccountInfoViewController()

        } else {

            super.handleSuccessfulFlow()
        }
    }

    override func cancel() {
        didCancel?()
        inputs = []

        let err = PrimerError.cancelled(paymentMethodType: self.config.type,
                                        userInfo: .errorUserInfoDictionary(),
                                        diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: err)
    }
}

extension FormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {

    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {}

    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        let isTextsValid = inputs.allSatisfy { $0.primerTextFieldView?.isTextValid == true }
        if isTextsValid {
            enableSubmitButton(true)
        } else {
            enableSubmitButton(false)
        }
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

extension FormPaymentMethodTokenizationViewModel: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countriesDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let country = countriesDataSource[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CountryTableViewCell.className, for: indexPath) as? CountryTableViewCell
        else {
            fatalError("Unexpected cell dequed in FormPaymentMethodTokenizationViewModel")
        }
        cell.configure(viewModel: country)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = self.countriesDataSource[indexPath.row]
        countryFieldView.textField.text = "\(country.flag) \(country.country)"
        countryFieldView.countryCode = country
        countryFieldView.validation = .valid
        countryFieldView.textFieldDidEndEditing(countryFieldView.textField)
        self.uiManager.primerRootViewController?.popViewController()
    }
}

extension FormPaymentMethodTokenizationViewModel: UITextFieldDelegate {

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

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

        for country in countries where country.country.lowercased()
            .folding(options: .diacriticInsensitive,
                     locale: nil)
            .contains(query.lowercased()
                        .folding(options: .diacriticInsensitive,
                                 locale: nil)) == true {
            countryResults.append(country)
        }

        countriesDataSource = countryResults

        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        countriesDataSource = countries
        return true
    }
}
// swiftlint:enable identifier_name
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
