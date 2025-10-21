//
//  CardFormPaymentMethodTokenizationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation
import SafariServices
import UIKit

// swiftlint:disable:next type_name
final class CardFormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel,
                                                        SearchableItemsPaymentMethodTokenizationViewModelProtocol {

    // MARK: - Properties

    private lazy var cardComponentsManager: InternalCardComponentsManager = {
        let manager = InternalCardComponentsManager(
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField,
            billingAddressFieldViews: allVisibleBillingAddressFieldViews,
            paymentMethodType: self.config.type,
            isRequiringCVVInput: isRequiringCVVInput,
            tokenizationService: tokenizationService,
            delegate: self
        )
        return manager
    }()

    // Used for Co-Badged Cards feature
    private lazy var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager? = {
        let manager = try? PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: "PAYMENT_CARD",
                                                                          delegate: self,
                                                                          isUsedInDropIn: true)
        return manager
    }()

    private var rawCardData = PrimerCardData(cardNumber: "",
                                             expiryDate: "",
                                             cvv: "",
                                             cardholderName: "")
    fileprivate var currentlyAvailableCardNetworks: [PrimerCardNetwork]?

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    var userInputCompletion: (() -> Void)?
    // swiftlint:disable:next identifier_name
    private var cardComponentsManagerTokenizationCompletion: ((Result<PrimerPaymentMethodTokenData, Error>) -> Void)?
    private var webViewController: SFSafariViewController?
    private var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private var paymentMethodsRequiringCVVInput: [PrimerPaymentMethodType] = [.paymentCard]
    private var isRequiringCVVInput: Bool {
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type) else { return false }
        return paymentMethodsRequiringCVVInput.contains(paymentMethodType)
    }
    var dataSource = CountryCode.allCases {
        didSet {
            tableView.reloadData()
        }
    }
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

    private var lastRemoteNetworkValues: [CardNetwork]?

    var defaultCardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = defaultCardNetwork ?? .unknown
        }
    }

    var alternativelySelectedCardNetwork: CardNetwork? {
        didSet {
            if let alternativelySelectedCardNetwork {
                cvvField.cardNetwork = alternativelySelectedCardNetwork
            }
        }
    }

    var isShowingBillingAddressFieldsRequired: Bool {
        guard let billingAddressModule = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
                .filter({ $0.type == "BILLING_ADDRESS" })
                .first else { return false }
        let options = (billingAddressModule.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions)
        return options?.postalCode == true
    }

    internal lazy var countrySelectorViewController: CountrySelectorViewController = {
        CountrySelectorViewController(viewModel: self)
    }()

    // MARK: - Card number field

    lazy var cardNumberField: PrimerCardNumberFieldView = {
        PrimerCardNumberField.cardNumberFieldViewWithDelegate(self)
    }()

    private lazy var cardNumberContainerView: PrimerCustomFieldView = {
        let containerView = PrimerCardNumberField.cardNumberContainerViewWithFieldView(cardNumberField)
        containerView.onCardNetworkSelected = { [weak self] cardNetwork in
            guard let self = self else { return }
            self.alternativelySelectedCardNetwork = cardNetwork.network
            self.rawCardData.cardNetwork = cardNetwork.network
            self.rawDataManager?.rawData = self.rawCardData
            self.cardComponentsManager.selectedCardNetwork = cardNetwork.network

            configureAmountLabels(cardNetwork: cardNetwork.network)

            // Select payment method based on the detected card network
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            Task {
                try? await clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: cardNetwork.network.rawValue)
            }

        }
        return containerView
    }()

    // MARK: - Cardholder name field

    lazy var cardholderNameField: PrimerCardholderNameFieldView? = {
        if !PrimerCardholderNameField.isCardholderNameFieldEnabled { return nil }
        return PrimerCardholderNameField.cardholderNameFieldViewWithDelegate(self)
    }()

    private lazy var cardholderNameContainerView: PrimerCustomFieldView? = {
        if !PrimerCardholderNameField.isCardholderNameFieldEnabled { return nil }
        return PrimerCardholderNameField.cardholderNameContainerViewFieldView(cardholderNameField)
    }()

    // MARK: - Expiry date field

    lazy var expiryDateField: PrimerExpiryDateFieldView = {
        return PrimerEpiryDateField.expiryDateFieldViewWithDelegate(self)
    }()

    private lazy var expiryDateContainerView: PrimerCustomFieldView = {
        return PrimerEpiryDateField.expiryDateContainerViewWithFieldView(expiryDateField)
    }()

    // MARK: - CVV field

    lazy var cvvField: PrimerCVVFieldView = {
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

    lazy var firstNameFieldView: PrimerFirstNameFieldView = {
        PrimerFirstNameField.firstNameFieldViewWithDelegate(self)
    }()

    private lazy var firstNameContainerView: PrimerCustomFieldView = {
        PrimerFirstNameField.firstNameFieldContainerViewFieldView(firstNameFieldView)
    }()

    private var firstNameField: BillingAddressField {
        (firstNameFieldView, firstNameContainerView, billingAddressCheckoutModuleOptions?.firstName == false)
    }

    // MARK: Last name

    lazy var lastNameFieldView: PrimerLastNameFieldView = {
        PrimerLastNameField.lastNameFieldViewWithDelegate(self)
    }()

    private lazy var lastNameContainerView: PrimerCustomFieldView = {
        PrimerLastNameField.lastNameFieldContainerViewFieldView(lastNameFieldView)
    }()

    private var lastNameField: BillingAddressField {
        (lastNameFieldView, lastNameContainerView, billingAddressCheckoutModuleOptions?.lastName == false)
    }

    // MARK: Address Line 1

    lazy var addressLine1FieldView: PrimerAddressLine1FieldView = {
        PrimerAddressLine1Field.addressLine1FieldViewWithDelegate(self)
    }()

    private lazy var addressLine1ContainerView: PrimerCustomFieldView = {
        PrimerAddressLine1Field.addressLine1ContainerViewFieldView(addressLine1FieldView)
    }()

    private var addressLine1Field: BillingAddressField {
        (addressLine1FieldView, addressLine1ContainerView, billingAddressCheckoutModuleOptions?.addressLine1 == false)
    }

    // MARK: Address Line 2

    lazy var addressLine2FieldView: PrimerAddressLine2FieldView = {
        PrimerAddressLine2Field.addressLine2FieldViewWithDelegate(self)
    }()

    private lazy var addressLine2ContainerView: PrimerCustomFieldView = {
        PrimerAddressLine2Field.addressLine2ContainerViewFieldView(addressLine2FieldView)
    }()

    private var addressLine2Field: BillingAddressField {
        (addressLine2FieldView, addressLine2ContainerView, billingAddressCheckoutModuleOptions?.addressLine2 == false)
    }

    // MARK: Postal code

    lazy var postalCodeFieldView: PrimerPostalCodeFieldView = {
        PrimerPostalCodeField.postalCodeViewWithDelegate(self)
    }()

    private lazy var postalCodeContainerView: PrimerCustomFieldView = {
        PrimerPostalCodeField.postalCodeContainerViewFieldView(postalCodeFieldView)
    }()

    private var postalCodeField: BillingAddressField {
        (postalCodeFieldView, postalCodeContainerView, billingAddressCheckoutModuleOptions?.postalCode == false)
    }

    // MARK: City

    lazy var cityFieldView: PrimerCityFieldView = {
        PrimerCityField.cityFieldViewWithDelegate(self)
    }()

    private lazy var cityContainerView: PrimerCustomFieldView = {
        PrimerCityField.cityFieldContainerViewFieldView(cityFieldView)
    }()

    private var cityField: BillingAddressField {
        (cityFieldView, cityContainerView, billingAddressCheckoutModuleOptions?.city == false)
    }

    // MARK: State

    lazy var stateFieldView: PrimerStateFieldView = {
        PrimerStateField.stateFieldViewWithDelegate(self)
    }()

    private lazy var stateContainerView: PrimerCustomFieldView = {
        PrimerStateField.stateFieldContainerViewFieldView(stateFieldView)
    }()

    private var stateField: BillingAddressField {
        (stateFieldView, stateContainerView, billingAddressCheckoutModuleOptions?.state == false)
    }

    // MARK: Country

    lazy var countryFieldView: PrimerCountryFieldView = {
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

    // swiftlint:disable:next identifier_name
    internal var allVisibleBillingAddressFieldContainerViews: [[PrimerCustomFieldView]] {
        let allVisibleBillingAddressFields = billingAddressFields.map { $0.filter { $0.isFieldHidden == false } }
        return allVisibleBillingAddressFields.map { $0.map { $0.containerFieldView } }
    }

    internal var formView: PrimerFormView {
        var formViews: [[UIView?]] = [
            [cardNumberContainerView],
            [expiryDateContainerView],
            [cardholderNameContainerView]
        ]
        if isRequiringCVVInput {
            formViews[1].append(cvvContainerView)
        }
        formViews.append(contentsOf: allVisibleBillingAddressFieldContainerViews)
        return PrimerFormView(frame: .zero, formViews: formViews)
    }

    override func start() {
        let surchargeAmount = alternativelySelectedCardNetwork?.surcharge ?? defaultCardNetwork?.surcharge
        let isMerchantAmountNil
            = PrimerAPIConfigurationModule.apiConfiguration?
            .clientSession?
            .order?
            .merchantAmount == nil
        let currencyExists = AppState.current.currency != nil
        let shouldShowSurcharge = surchargeAmount != nil && isMerchantAmountNil && currencyExists

        // If we would *hide* the surcharge label, then “unselect” the method
        if !shouldShowSurcharge {
            unselectPaymentMethodSilently()
        }

        checkoutEventsNotifierModule.didStartTokenization = {
            DispatchQueue.main.async {
                self.uiModule.submitButton?.startAnimating()
                self.uiManager.primerRootViewController?.enableUserInteraction(false)
            }
        }

        checkoutEventsNotifierModule.didFinishTokenization = {
            DispatchQueue.main.async {
                self.uiModule.submitButton?.stopAnimating()
                self.uiManager.primerRootViewController?.enableUserInteraction(true)
            }
        }

        didStartPayment = {
            DispatchQueue.main.async {
                self.uiModule.submitButton?.startAnimating()
                self.uiManager.primerRootViewController?.enableUserInteraction(false)
            }
        }

        didFinishPayment = { _ in
            DispatchQueue.main.async {
                self.uiModule.submitButton?.stopAnimating()
                self.uiManager.primerRootViewController?.enableUserInteraction(true)

                self.willDismissPaymentMethodUI?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissPaymentMethodUI?()
                })
            }
        }

        Task {
            do {
                self.paymentMethodTokenData = try await startTokenizationFlow()
                await processPaymentMethodTokenData()
            } catch {
                await uiManager.primerRootViewController?.enableUserInteraction(true)
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                if let primerErr = error as? PrimerError,
                   case .cancelled = primerErr,
                   PrimerInternal.shared.sdkIntegrationType == .dropIn,
                   self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
                   self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
                   self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                    do {
                        try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        await PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
                    } catch {}
                } else {
                    do {
                        let primerErr = error.asPrimerError
                        try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        await showResultScreenIfNeeded(error: primerErr)
                        let merchantErrorMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
                        await handleFailureFlow(errorMessage: merchantErrorMessage)
                    } catch {
                        self.logger.error(message: "Unselection of payment method failed - this should never happen ...")
                    }
                }
            }
        }
    }

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard decodedJWTToken.pciUrl != nil else {
            throw handled(primerError: .invalidValue(key: "clientToken.pciUrl", value: decodedJWTToken.pciUrl))
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
        Analytics.Service.fire(
            event: Analytics.Event.ui(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type,
                    url: nil
                ),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .cardForm
            )
        )

        try validate()
        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()
        try await dispatchActions()
        return try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        return try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    @MainActor
    override func presentPaymentMethodUserInterface() async throws {
        switch config.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            uiManager.primerRootViewController?.show(
                viewController: PrimerCardFormViewController(viewModel: self)
            )
        case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
            uiManager.primerRootViewController?.show(
                viewController: PrimerCardFormViewController(navigationBarLogo: uiModule.logo, viewModel: self)
            )
        default:
            assertionFailure("Failed to present card form payment method - \(self.config.type) is not a valid payment method type for this payment flow.")
        }
    }

    override func awaitUserInput() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.userInputCompletion = {
                continuation.resume()
            }

            Task {
                await PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.config.type)
            }
        }

        await uiManager.primerRootViewController?.enableUserInteraction(false)
    }

    @MainActor
    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        cardComponentsManager.tokenize()

        return try await withCheckedThrowingContinuation { continuation in
            self.cardComponentsManagerTokenizationCompletion = { result in
                continuation.resume(with: result)
            }
        }
    }

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                   paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
        if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
            return try await handleRedirectionForDecodedClientToken(decodedJWTToken)
        } else if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
            return try await handle3DSAuthenticationForDecodedClientToken(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
        } else if decodedJWTToken.intent == RequiredActionName.processor3DS.rawValue {
            return try await handleProcessor3DSForDecodedClientToken(decodedJWTToken)
        } else {
            throw handled(primerError: .invalidValue(key: "resumeToken"))
        }
    }

    private func handleRedirectionForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
        guard let redirectUrlStr = decodedJWTToken.redirectUrl,
              let redirectUrl = URL(string: redirectUrlStr),
              let statusUrlStr = decodedJWTToken.statusUrl,
              let statusUrl = URL(string: statusUrlStr),
              decodedJWTToken.intent != nil else {
            throw PrimerError.invalidClientToken()
        }

        await uiManager.primerRootViewController?.enableUserInteraction(true)

        try await self.presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
        return try await PollingModule(url: statusUrl).start()
    }

    @MainActor
    private func handle3DSAuthenticationForDecodedClientToken(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        #if DEBUG
        let threeDSService: ThreeDSServiceProtocol =
            PrimerAPIConfiguration.current?.clientSession?.testId != nil ? Mock3DSService() : ThreeDSService()
        #else
        let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
        #endif

        return try await threeDSService.perform3DS(
            paymentMethodTokenData: paymentMethodTokenData,
            sdkDismissed: nil
        )
    }

    private func handleProcessor3DSForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
        guard let redirectUrlStr = decodedJWTToken.redirectUrl,
              let redirectUrl = URL(string: redirectUrlStr),
              let statusUrlStr = decodedJWTToken.statusUrl,
              let statusUrl = URL(string: statusUrlStr),
              decodedJWTToken.intent != nil else {
            throw handled(primerError: .invalidClientToken())
        }

        await self.uiManager.primerRootViewController?.enableUserInteraction(true)
        try await self.presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)

        let pollingModule = PollingModule(url: statusUrl)
        didCancel = {
            pollingModule.cancel(withError: handled(primerError: .cancelled(paymentMethodType: self.config.type)))
        }
        return try await pollingModule.start()
    }

    @MainActor
    func presentWebRedirectViewControllerWithRedirectUrl(_ redirectUrl: URL) async throws {
        let safariViewController = SFSafariViewController(url: redirectUrl)
        safariViewController.delegate = self
        webViewController = safariViewController

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.webViewCompletion = { _, err in
                if let err {
                    continuation.resume(throwing: err)
                }
            }

            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.present(safariViewController, animated: true, completion: {
                    DispatchQueue.main.async {
                        continuation.resume()
                    }
                })
            }
        }
    }

    func configureAmountLabels(cardNetwork: CardNetwork?) {
        if let surcharge = alternativelySelectedCardNetwork?.surcharge ?? cardNetwork?.surcharge,
           PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.merchantAmount == nil,
           let currency = AppState.current.currency {
            configureSurchargeLabel(surchargeAmount: surcharge, currency: currency)
        } else {
            hideSurchargeLabel()
        }

        let amount: Int = AppState.current.amount ?? 0
        configurePayButton(amount: amount)
    }

    func configurePayButton(amount: Int) {
        DispatchQueue.main.async {
            // Only in a checkout intent and when currency is set
            guard PrimerInternal.shared.intent == .checkout,
                  let currency = AppState.current.currency else {
                return
            }

            let title = PrimerSettings.current.uiOptions.cardFormUIOptions?.payButtonAddNewCard == true
                ? Strings.VaultPaymentMethodViewContent.addCard
                : "\(Strings.PaymentButton.pay) \(amount.toCurrencyString(currency: currency))"

            self.uiModule.submitButton?.setTitle(title, for: .normal)
        }
    }

    func configureSurchargeLabel(surchargeAmount: Int, currency: Currency) {
        DispatchQueue.main.async {
            let amount = "+ \(surchargeAmount.toCurrencyString(currency: currency))"
            self.cardNumberContainerView.updateSurcharge(amount: amount)
        }
    }

    func hideSurchargeLabel() {
        DispatchQueue.main.async {
            self.cardNumberContainerView.updateSurcharge(amount: nil)
        }
    }

    override func submitButtonTapped() {
        self.uiModule.submitButton?.startAnimating()
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

        self.userInputCompletion?()
    }

    override func cancel() {
        self.didCancel?()
        self.didCancel = nil
        super.cancel()
    }
}

extension CardFormPaymentMethodTokenizationViewModel {

    private func dispatchActions() async throws {
        var network = self.alternativelySelectedCardNetwork?.rawValue.uppercased() ?? self.defaultCardNetwork?.rawValue.uppercased()
        if network == nil || network == "UNKNOWN" {
            network = "OTHER"
        }

        let params: [String: Any] = [
            "paymentMethodType": config.type,
            "binData": ["network": network]
        ]
        var actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]

        if isShowingBillingAddressFieldsRequired {
            let updatedBillingAddress = await MainActor.run {
                ClientSession.Address(firstName: firstNameFieldView.firstName,
                                      lastName: lastNameFieldView.lastName,
                                      addressLine1: addressLine1FieldView.addressLine1,
                                      addressLine2: addressLine2FieldView.addressLine2,
                                      city: cityFieldView.city,
                                      postalCode: postalCodeFieldView.postalCode,
                                      state: stateFieldView.state,
                                      countryCode: countryFieldView.countryCode)
            }
            if let billingAddress = try? updatedBillingAddress.asDictionary() {
                let billingAddressAction: ClientSession.Action = .setBillingAddressActionWithParameters(billingAddress)
                actions.append(billingAddressAction)
            }
        }

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.dispatch(actions: actions)
    }

    private func unselectPaymentMethodSilently() {
        Task {
            try? await ClientSessionActionsModule().unselectPaymentMethodIfNeeded()
        }
    }
}

extension CardFormPaymentMethodTokenizationViewModel: InternalCardComponentsManagerDelegate {

    func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager, onTokenizeSuccess paymentMethodToken: PrimerPaymentMethodTokenData) {
        self.cardComponentsManagerTokenizationCompletion?(.success(paymentMethodToken))
        self.cardComponentsManagerTokenizationCompletion = nil
    }

    func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void) {
        if let clientToken = PrimerAPIConfigurationModule.clientToken {
            completion(clientToken, nil)
        } else {
            completion(nil, handled(primerError: .invalidClientToken()))
        }
    }

    func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager, tokenizationFailedWith errors: [Error]) {
        self.cardComponentsManagerTokenizationCompletion?(.failure(handled(primerError: .underlyingErrors(errors: errors))))
        self.cardComponentsManagerTokenizationCompletion = nil
    }

    func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager, isLoading: Bool) {
        if isLoading {
            self.uiModule.submitButton?.startAnimating()
        } else {
            self.uiModule.submitButton?.stopAnimating()
        }
        self.uiManager.primerRootViewController?.enableUserInteraction(!isLoading)
    }

    // swiftlint:disable cyclomatic_complexity
    fileprivate func showTexfieldViewErrorIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {

        if isValid == false {
            // We know for sure that the text is not valid, even if the user hasn't finished typing.
            if primerTextFieldView is PrimerCardNumberFieldView, !primerTextFieldView.isEmpty {
                cardNumberContainerView.errorText = Strings.CardFormView.CardNumber.invalidErrorMessage
            } else if primerTextFieldView is PrimerExpiryDateFieldView, !primerTextFieldView.isEmpty {
                expiryDateContainerView.errorText = Strings.CardFormView.ExpiryDate.invalidErrorMessage
            } else if primerTextFieldView is PrimerCVVFieldView, !primerTextFieldView.isEmpty {
                cvvContainerView.errorText = Strings.CardFormView.CVV.invalidErrorMessage
            } else if primerTextFieldView is PrimerCardholderNameFieldView {
                // Check if the cardholder name field is empty or has an invalid length.
                if primerTextFieldView.isEmpty {
                    // If the text field is empty, assign the default invalid error message.
                    cardholderNameContainerView?.errorText = Strings.CardFormView.Cardholder.invalidErrorMessage
                } else if let count = primerTextFieldView.textField.text?.count, count >= 2 && count < 45 {
                    // If the count of characters is between 2 (inclusive) and 45 (exclusive),
                    // assign the error message specific to cardholder length.
                    cardholderNameContainerView?.errorText = Strings.CardFormView.Cardholder.invalidCardholderLengthErrorMessage
                } else {
                    // For all other cases, assign the general invalid error message.
                    cardholderNameContainerView?.errorText = Strings.CardFormView.Cardholder.invalidErrorMessage
                }
            } else if primerTextFieldView is PrimerPostalCodeFieldView {
                postalCodeContainerView.errorText = primerTextFieldView.isEmpty ?
                    Strings.CardFormView.PostalCode.isRequiredErrorMessage : Strings.CardFormView.PostalCode.invalidErrorMessage
            } else if primerTextFieldView is PrimerCountryFieldView {
                countryFieldContainerView.errorText = primerTextFieldView.isEmpty ?
                    Strings.CardFormView.CountryCode.isRequiredErrorMessage : Strings.CardFormView.CountryCode.invalidErrorMessage
            } else if primerTextFieldView is PrimerFirstNameFieldView {
                firstNameContainerView.errorText = primerTextFieldView.isEmpty ?
                    Strings.CardFormView.FirstName.isRequiredErrorMessage : Strings.CardFormView.FirstName.invalidErrorMessage
            } else if primerTextFieldView is PrimerLastNameFieldView {
                lastNameContainerView.errorText = primerTextFieldView.isEmpty ?
                    Strings.CardFormView.LastName.isRequiredErrorMessage : Strings.CardFormView.LastName.invalidErrorMessage
            } else if primerTextFieldView is PrimerCityFieldView {
                cityContainerView.errorText = primerTextFieldView.isEmpty ?
                    Strings.CardFormView.City.isRequiredErrorMessage : Strings.CardFormView.City.invalidErrorMessage
            } else if primerTextFieldView is PrimerStateFieldView {
                stateContainerView.errorText = primerTextFieldView.isEmpty ?
                    Strings.CardFormView.State.isRequiredErrorMessage : Strings.CardFormView.State.invalidErrorMessage
            } else if primerTextFieldView is PrimerAddressLine1FieldView {
                addressLine1ContainerView.errorText = primerTextFieldView.isEmpty ?
                    Strings.CardFormView.AddressLine1.isRequiredErrorMessage : Strings.CardFormView.AddressLine1.invalidErrorMessage
            } else if primerTextFieldView is PrimerAddressLine2FieldView {
                addressLine2ContainerView.errorText = primerTextFieldView.isEmpty ?
                    Strings.CardFormView.AddressLine2.isRequiredErrorMessage : Strings.CardFormView.AddressLine2.invalidErrorMessage
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
            } else if primerTextFieldView is PrimerCountryFieldView {
                countryFieldContainerView.errorText = nil
            } else if primerTextFieldView is PrimerFirstNameFieldView {
                firstNameContainerView.errorText = nil
            } else if primerTextFieldView is PrimerLastNameFieldView {
                lastNameContainerView.errorText = nil
            } else if primerTextFieldView is PrimerCityFieldView {
                cityContainerView.errorText = nil
            } else if primerTextFieldView is PrimerStateFieldView {
                stateContainerView.errorText = nil
            } else if primerTextFieldView is PrimerAddressLine1FieldView {
                addressLine1ContainerView.errorText = nil
            } else if primerTextFieldView is PrimerAddressLine2FieldView {
                addressLine2ContainerView.errorText = nil
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity

    fileprivate func enableSubmitButtonIfNeeded() {
        var validations = [
            cardNumberField.isTextValid,
            expiryDateField.isTextValid
        ]

        if isRequiringCVVInput {
            validations.append(cvvField.isTextValid)
        }

        if isShowingBillingAddressFieldsRequired {
            validations.append(contentsOf: allVisibleBillingAddressFieldViews.map { $0.isTextValid })
        }

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

extension CardFormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {

    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: true)
    }

    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: isValid)
        enableSubmitButtonIfNeeded()
    }

    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView,
                             didDetectCardNetwork cardNetwork: CardNetwork?) {
        if let text = primerTextFieldView.textField.internalText {
            rawCardData.cardNumber = text.replacingOccurrences(of: " ", with: "")
            rawDataManager?.rawData = rawCardData
        }
    }

    private func handleCardNetworkDetection(_ cardNetwork: CardNetwork?) {
        guard alternativelySelectedCardNetwork == nil
        else { return }

        self.rawCardData.cardNetwork = cardNetwork
        self.rawDataManager?.rawData = self.rawCardData

        var network = cardNetwork?.rawValue.uppercased()

        if let cardNetwork = cardNetwork,
           cardNetwork != .unknown {
            // Set the network value to "OTHER" if it's nil or unknown
            if network == nil || network == "UNKNOWN" {
                network = "OTHER"
            }

            // Update the UI with the detected card network icon
            cardNumberContainerView.rightImage = cardNetwork.icon

            // Update labels immediately
            configureAmountLabels(cardNetwork: cardNetwork)
        } else if cardNumberContainerView.rightImage != nil && (cardNetwork?.icon == nil || cardNetwork == .unknown) {
            // Unselect payment method and remove the card network icon if unknown or nil
            cardNumberContainerView.rightImage = nil

            configureAmountLabels(cardNetwork: cardNetwork)
        }
    }
}

extension CardFormPaymentMethodTokenizationViewModel: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            webViewCompletion(nil, handled(primerError: .cancelled(paymentMethodType: config.type)))
        }

        webViewCompletion = nil
    }
}

extension CardFormPaymentMethodTokenizationViewModel: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let country = dataSource[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CountryTableViewCell.className,
                                                       for: indexPath) as? CountryTableViewCell
        else {
            fatalError("Unexpected cell dequed in PrimerSDK.CardFormPaymentMethodTokenizationViewModel")
        }
        cell.configure(viewModel: country)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = self.dataSource[indexPath.row]
        countryFieldView.textField.text = "\(country.flag) \(country.country)"
        countryFieldView.countryCode = country
        countryFieldView.validation = .valid
        countryFieldView.textFieldDidEndEditing(countryFieldView.textField)
        self.uiManager.primerRootViewController?.popViewController()
    }
}

extension CardFormPaymentMethodTokenizationViewModel: UITextFieldDelegate {

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
            dataSource = countries
            return true
        }

        var countryResults: [CountryCode] = []

        for country in countries where
            country.country.lowercasedAndFolded().contains(query.lowercasedAndFolded()) == true {
            countryResults.append(country)
        }

        dataSource = countryResults

        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        dataSource = countries
        return true
    }
}

// MARK: - PrimerHeadlessUniversalCheckoutRawDataManagerDelegate
extension CardFormPaymentMethodTokenizationViewModel: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Swift.Error]?) {
        let errorsDescription = errors?.map { $0.localizedDescription }.joined(separator: ", ")
        logger.debug(message: "dataIsValid: \(isValid), errors: \(errorsDescription ?? "none")")
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              metadataDidChange metadata: [String: Any]?) {
        logger.debug(message: "metadataDidChange: \(metadata ?? [:])")
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willFetchMetadataForState cardState: PrimerValidationState) {
        guard let state = cardState as? PrimerCardNumberEntryState else {
            logger.error(message: "Received non-card metadata. Ignoring ...")
            return
        }
        logger.debug(message: "willFetchCardMetadataForState: \(state.cardNumber)")
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState cardState: PrimerValidationState) {
        guard let metadataModel = metadata as? PrimerCardNumberEntryMetadata,
              let stateModel = cardState as? PrimerCardNumberEntryState else {
            logger.error(message: "Received non-card metadata. Ignoring ...")
            return
        }

        let metadataDescription = metadataModel.selectableCardNetworks?.items
            .map { $0.displayName }
            .joined(separator: ", ") ?? "n/a"
        logger.debug(message: "didReceiveCardMetadata: (selectable ->) \(metadataDescription), cardState: \(stateModel.cardNumber)")

        var primerNetworks: [PrimerCardNetwork]
        if metadataModel.source == .remote,
           let selectable = metadataModel.selectableCardNetworks?.items,
           !selectable.isEmpty {
            primerNetworks = selectable
        } else if let preferred = metadataModel.detectedCardNetworks.preferred {
            primerNetworks = [preferred]
        } else if let first = metadataModel.detectedCardNetworks.items.first {
            primerNetworks = [first]
        } else {
            primerNetworks = []
        }

        let filteredNetworks = primerNetworks.filter { $0.displayName != "Unknown" }
        let newNetworks = filteredNetworks.map { $0.network }
        guard newNetworks != lastRemoteNetworkValues else { return }
        lastRemoteNetworkValues = newNetworks

        currentlyAvailableCardNetworks = filteredNetworks
        cardNumberContainerView.cardNetworks = filteredNetworks

        // 1) Set default on first non-empty detection
        if defaultCardNetwork == nil, let first = newNetworks.first {
            defaultCardNetwork = first
        }

        DispatchQueue.main.async {
            // 2) Exactly one network: reset any manual selection and apply it
            if newNetworks.count == 1 {
                self.cardNumberContainerView.resetCardNetworkSelection()
                self.alternativelySelectedCardNetwork = nil
                self.handleCardNetworkDetection(newNetworks[0])

                // 3) Multiple possible networks: show generic/“unknown” icon
            } else if newNetworks.count > 1 {
                self.cardNumberContainerView.resetCardNetworkSelection()
                self.cardNumberContainerView.rightImage = CardNetwork.unknown.icon

                // 4) No networks (user cleared the field): wipe everything
            } else {
                // Remember if we had any selection
                let hadSelection = (self.alternativelySelectedCardNetwork != nil)
                    || (self.defaultCardNetwork != nil)

                // Clear all state & UI
                self.alternativelySelectedCardNetwork = nil
                self.defaultCardNetwork = nil
                self.cardNumberContainerView.rightImage = nil
                self.configureAmountLabels(cardNetwork: nil)

                // Only unselect if there was something to unselect
                if hadSelection {
                    self.unselectPaymentMethodSilently()
                }
            }
        }
    }

    private func image(from model: PrimerCardNetwork) -> UIImage? {
        let asset = PrimerHeadlessUniversalCheckout.AssetsManager.getCardNetworkAsset(for: model.network)
        return asset?.cardImage
    }
}

private extension String {
    func lowercasedAndFolded() -> String {
        self
            .lowercased()
            .folding(
                options: .diacriticInsensitive,
                locale: nil)
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
