//
//  FormPaymentMethodTokenizationViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable identifier_name
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation
import UIKit
import PrimerFoundation

class Input {
    var name: String?
    var topPlaceholder: String?
    var textFieldPlaceholder: String?
    var keyboardType: UIKeyboardType?
    var allowedCharacterSet: CharacterSet?
    var maxCharactersAllowed: UInt?
    var isValid: ((_ text: String) -> Bool?)?
    var descriptor: String?
    var text: String? {
        primerTextFieldView?.text
    }
    var primerTextFieldView: PrimerTextFieldView?
}

final class FormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel, SearchableItemsPaymentMethodTokenizationViewModelProtocol {

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
            text.isNumeric && text.count >= 8
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
            text.isNumeric && text.count >= 6
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

    lazy var tableView: UITableView = {
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

    lazy var searchableTextField: PrimerSearchTextField = {
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

    var isShowingBillingAddressFieldsRequired: Bool {
        let billingAddressModuleOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
            .first { $0.type == "BILLING_ADDRESS" }?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
        return billingAddressModuleOptions != nil
    }

    lazy var countrySelectorViewController: CountrySelectorViewController = {
        CountrySelectorViewController(viewModel: self)
    }()

    // MARK: - Card number field

    lazy var cardNumberField: PrimerCardNumberFieldView = {
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
        PrimerEpiryDateField.expiryDateFieldViewWithDelegate(self)
    }()

    private lazy var expiryDateContainerView: PrimerCustomFieldView = {
        PrimerEpiryDateField.expiryDateContainerViewWithFieldView(expiryDateField)
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

    var billingAddressCheckoutModuleOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? {
        PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
            .filter({ $0.type == "BILLING_ADDRESS" })
            .first?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
    }

    var billingAddressFields: [[BillingAddressField]] {
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

    var allVisibleBillingAddressFieldViews: [PrimerTextFieldView] {
        billingAddressFields.flatMap { $0.filter { $0.isFieldHidden == false } }.map(\.fieldView)
    }

    var allVisibleBillingAddressFieldContainerViews: [[PrimerCustomFieldView]] {
        let allVisibleBillingAddressFields = billingAddressFields.map { $0.filter { $0.isFieldHidden == false } }
        return allVisibleBillingAddressFields.map { $0.map(\.containerFieldView) }
    }

    var formView: PrimerFormView {
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

    override func start() {

        checkoutEventsNotifierModule.didStartTokenization = {
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(false)
            }
        }

        checkoutEventsNotifierModule.didFinishTokenization = {
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(true)
            }
        }

        didStartPayment = {
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(false)
            }
        }

        didFinishPayment = { _ in
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(true)
            }
        }

        super.start()
    }

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard decodedJWTToken.pciUrl != nil else {
            throw handled(primerError: .invalidValue(key: "clientToken.pciUrl"))
        }

        if PrimerInternal.shared.intent == .checkout {
            if AppState.current.amount == nil {
                throw handled(primerError: .invalidValue(key: "amount"))
            }

            if AppState.current.currency == nil {
                throw handled(primerError: .invalidValue(key: "currency"))
            }
        }
    }

    override func performPreTokenizationSteps() async throws {
        Analytics.Service.fire(event: Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: config.type,
                url: nil
            ),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .cardForm
        ))

        await uiManager.primerRootViewController?.showLoadingScreenIfNeeded(
            imageView: uiModule.makeIconImageView(withDimension: 24.0),
            message: nil
        )

        try validate()

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(config.type, cardNetwork: nil)

        try await presentPaymentMethodUserInterface()
        try await evaluatePaymentMethodNeedingFurtherUserActions()
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    override func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
            return try await handleRedirectionForDecodedClientToken(decodedJWTToken)
        } else if decodedJWTToken.intent == RequiredActionName.paymentMethodVoucher.rawValue {
            return try await handlePaymentMethodVoucherForDecodedClientToken(decodedJWTToken)
        } else {
            throw handled(primerError: .invalidValue(key: "resumeToken"))
        }
    }

    private func handleRedirectionForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
        guard let statusUrlStr = decodedJWTToken.statusUrl,
              let statusUrl = URL(string: statusUrlStr),
              decodedJWTToken.intent != nil else {
            throw PrimerError.invalidClientToken()
        }

        let paymentMethodType = PrimerPaymentMethodType(rawValue: config.type)
        let isPaymentMethodNeedingExternalCompletion = (needingExternalCompletionPaymentMethodDictionary
            .first { $0.key == paymentMethodType } != nil) == true

        defer {
            didCancel = nil
        }

        try await presentPaymentMethodAppropriateViewController(
            shouldCompletePaymentExternally: isPaymentMethodNeedingExternalCompletion
        )

        let pollingModule = PollingModule(url: statusUrl)
        self.didCancel = {
            let err = handled(primerError: .cancelled(paymentMethodType: self.config.type))
            pollingModule.cancel(withError: err)
        }

        return try await pollingModule.start()
    }

    private func handlePaymentMethodVoucherForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
        let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
        var additionalInfo: PrimerCheckoutAdditionalInfo?

        switch config.type {
        case PrimerPaymentMethodType.adyenMultibanco.rawValue:
            let formatter = DateFormatter().withExpirationDisplayDateFormat()

            var expiresAtAdditionalInfo: String?
            if let unwrappedExpiresAt = decodedJWTToken.expiresAt {
                expiresAtAdditionalInfo = formatter.string(from: unwrappedExpiresAt)
            }

            additionalInfo = MultibancoCheckoutAdditionalInfo(
                expiresAt: expiresAtAdditionalInfo,
                entity: decodedJWTToken.entity,
                reference: decodedJWTToken.reference
            )

            if let paymentCheckoutData {
                paymentCheckoutData.additionalInfo = additionalInfo
            } else {
                paymentCheckoutData = PrimerCheckoutData(payment: nil, additionalInfo: additionalInfo)
            }

        default:
            logger.info(message: "UNHANDLED PAYMENT METHOD RESULT")
            logger.info(message: config.type)
        }

        if isManualPaymentHandling {
            await PrimerDelegateProxy.primerDidEnterResumePendingWithPaymentAdditionalInfo(additionalInfo)
        }
        return nil
    }

    private func evaluatePaymentMethodNeedingFurtherUserActions() async throws {
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: config.type),
              inputPaymentMethodTypes.contains(paymentMethodType) ||
              voucherPaymentMethodTypes.contains(paymentMethodType)
        else {
            return
        }

        try await awaitUserInput()
    }

    override func presentPaymentMethodUserInterface() async throws {
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: config.type),
              inputPaymentMethodTypes.contains(paymentMethodType) ||
              voucherPaymentMethodTypes.contains(paymentMethodType)
        else {
            return
        }

        try await presentPaymentMethodAppropriateViewController()
    }

    override func awaitUserInput() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.userInputCompletion = {
                continuation.resume()
            }

            Task {
                await PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: config.type)
            }
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
        Analytics.Service.fire(event: viewEvent)

        switch config.type {
        case PrimerPaymentMethodType.adyenBlik.rawValue,
             PrimerPaymentMethodType.adyenMBWay.rawValue,
             PrimerPaymentMethodType.adyenMultibanco.rawValue:
            self.uiModule.submitButton?.startAnimating()
            self.userInputCompletion?()
            self.userInputCompletion = nil

        default:
            fatalError("Must be overridden")
        }
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let configId = config.id else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        switch config.type {
        case PrimerPaymentMethodType.adyenBlik.rawValue:
            return try await handleAdyenBlikTokenization(configId: configId)
        case PrimerPaymentMethodType.rapydFast.rawValue:
            return try await handleRapydFastTokenization(configId: configId)
        case PrimerPaymentMethodType.adyenMBWay.rawValue:
            return try await handleAdyenMBWayTokenization(configId: configId)
        case PrimerPaymentMethodType.adyenMultibanco.rawValue:
            return try await handleAdyenMultibancoTokenization(configId: configId)
        default:
            fatalError("Unsupported payment method type.")
        }
    }

    private func handleAdyenBlikTokenization(configId: String) async throws -> PrimerPaymentMethodTokenData {
        guard let blikCode = inputs.first?.text else {
            throw handled(primerError: PrimerError.invalidValue(key: "blikCode"))
        }

        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: config.type,
            sessionInfo: BlikSessionInfo(
                blikCode: blikCode,
                locale: PrimerSettings.current.localeData.localeCode
            )
        )
        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)

        return try await tokenizationService.tokenize(requestBody: requestBody)
    }

    private func handleRapydFastTokenization(configId: String) async throws -> PrimerPaymentMethodTokenData {
        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: config.type,
            sessionInfo: WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
        )
        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        let tokenizationService: TokenizationServiceProtocol = TokenizationService()

        return try await tokenizationService.tokenize(requestBody: requestBody)
    }

    private func handleAdyenMBWayTokenization(configId: String) async throws -> PrimerPaymentMethodTokenData {
        guard let phoneNumber = inputs.first?.text else {
            throw handled(primerError: PrimerError.invalidValue(key: "phoneNumber"))
        }

        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: config.type,
            sessionInfo: InputPhonenumberSessionInfo(
                phoneNumber: "\(FormPaymentMethodTokenizationViewModel.countryDialCode)\(phoneNumber)"
            )
        )
        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        let tokenizationService: TokenizationServiceProtocol = TokenizationService()

        return try await tokenizationService.tokenize(requestBody: requestBody)
    }

    private func handleAdyenMultibancoTokenization(configId: String) async throws -> PrimerPaymentMethodTokenData {
        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: config.type,
            sessionInfo: WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
        )
        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        let tokenizationService: TokenizationServiceProtocol = TokenizationService()

        return try await tokenizationService.tokenize(requestBody: requestBody)
    }

    @MainActor
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

        let err = PrimerError.cancelled(paymentMethodType: self.config.type)
        ErrorHandler.handle(error: err)
    }

    // MARK: Private helper methods

    private func enableUserInteraction(_ enable: Bool) {
        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(enable)
        }
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
        countriesDataSource.count
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
