//
//  CardTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 18/10/22.
//

#if canImport(UIKit)

import Foundation

class CardTokenizationModule: TokenizationModule, SearchableItemsPaymentMethodTokenizationViewModelProtocol {
        
    
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
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }

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

    private var paymentMethodsRequiringCVVInput: [PrimerPaymentMethodType] = [.paymentCard]
    private var isRequiringCVVInput: Bool {
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodModule.paymentMethodConfiguration.type) else { return false }
        return paymentMethodsRequiringCVVInput.contains(paymentMethodType)
    }
    var cardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = cardNetwork ?? .unknown
        }
    }
            
    var isShowingBillingAddressFieldsRequired: Bool {
        guard let billingAddressModule = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first else { return false }
        return (billingAddressModule.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions)?.postalCode == true
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
            [expiryDateContainerView],
            [cardholderNameContainerView],
        ]
        if isRequiringCVVInput {
            formViews[1].append(cvvContainerView)
        }
        formViews.append(contentsOf: allVisibleBillingAddressFieldContainerViews)
        return PrimerFormView(frame: .zero, formViews: formViews)
    }
    
    private var cardComponentsManager: CardComponentsManager!
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private var userInputCompletion: (() -> Void)?
    private var cardComponentsManagerTokenizationCompletion: ((PrimerPaymentMethodTokenData?, Error?) -> Void)?
    
    required init(paymentMethodModule: PaymentMethodModuleProtocol) {
        super.init(paymentMethodModule: paymentMethodModule)
        
        self.cardComponentsManager = CardComponentsManager(
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField,
            billingAddressFieldViews: allVisibleBillingAddressFieldViews,
            paymentMethodType: paymentMethodModule.paymentMethodConfiguration.type,
            isRequiringCVVInput: isRequiringCVVInput
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
        
        return Promise { seal in
            firstly {
                self.validate()
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
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                return self.dispatchActions()
            }
            .then { () -> Promise<Void> in
                return self.firePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodModule.paymentMethodConfiguration.type))
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
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                switch self.paymentMethodModule.paymentMethodConfiguration.type {
                case PrimerPaymentMethodType.paymentCard.rawValue:
                    let pcfvc = PrimerCardFormViewController(cardTokenizationModule: self)
                    PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                    seal.fulfill()
                    
                case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
                    let pcfvc = PrimerCardFormViewController(
                        navigationBarLogo: self.paymentMethodModule.userInterfaceModule.logo,
                        cardTokenizationModule: self)
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
            var network = self.cardNetwork?.rawValue.uppercased()
            if network == nil || network == "UNKNOWN" {
                network = "OTHER"
            }
            
            let params: [String: Any] = [
                "paymentMethodType": self.paymentMethodModule.paymentMethodConfiguration.type,
                "binData": [
                    "network": network,
                ]
            ]
            
            var actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
            
            if (isShowingBillingAddressFieldsRequired) {
                let updatedBillingAddress = ClientSession.Address(firstName: firstNameFieldView.firstName,
                                                                  lastName: lastNameFieldView.lastName,
                                                                  addressLine1: addressLine1FieldView.addressLine1,
                                                                  addressLine2: addressLine2FieldView.addressLine2,
                                                                  city: cityFieldView.city,
                                                                  postalCode: postalCodeFieldView.postalCode,
                                                                  state: stateFieldView.state,
                                                                  countryCode: countryFieldView.countryCode)
                
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
    
    func enableSubmitButtonIfNeeded() {
        var validations = [
            cardNumberField.isTextValid,
            expiryDateField.isTextValid,
        ]
        
        if isRequiringCVVInput {
            validations.append(cvvField.isTextValid)
        }
        
        if isShowingBillingAddressFieldsRequired {
            validations.append(contentsOf: allVisibleBillingAddressFieldViews.map { $0.isTextValid })
        }
        
        if cardholderNameField != nil { validations.append(cardholderNameField!.isTextValid) }
        
        if validations.allSatisfy({ $0 == true }) {
            self.paymentMethodModule.userInterfaceModule.submitButton?.isEnabled = true
            self.paymentMethodModule.userInterfaceModule.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            self.paymentMethodModule.userInterfaceModule.submitButton?.isEnabled = false
            self.paymentMethodModule.userInterfaceModule.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }
    
    func updateButtonUI() {
        if let amount = AppState.current.amount, self.paymentMethodModule.userInterfaceModule.isSubmitButtonAnimating == false {
            self.configurePayButton(amount: amount)
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
            guard PrimerInternal.shared.intent == .checkout,
                  let currency = AppState.current.currency else {
                return
            }
            
            var title = Strings.PaymentButton.pay
            title += " \(amount.toCurrencyString(currency: currency))"
            self.paymentMethodModule.userInterfaceModule.submitButton?.setTitle(title, for: .normal)
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
        
        self.userInputCompletion?()
    }
}

extension CardTokenizationModule: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let country = dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CountryTableViewCell.className, for: indexPath) as! CountryTableViewCell
        cell.configure(viewModel: country)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = self.dataSource[indexPath.row]
        countryFieldView.textField.text = "\(country.flag) \(country.country)"
        countryFieldView.countryCode = country
        countryFieldView.validation = .valid
        countryFieldView.textFieldDidEndEditing(countryFieldView.textField)
        PrimerUIManager.primerRootViewController?.popViewController()
    }
}

extension CardTokenizationModule: UITextFieldDelegate {
    
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
            dataSource = countries
            return true
        }
        
        var countryResults: [CountryCode] = []
        
        for country in countries {
            if country.country.lowercased().folding(options: .diacriticInsensitive, locale: nil).contains(query.lowercased().folding(options: .diacriticInsensitive, locale: nil)) == true {
                countryResults.append(country)
            }
        }
        
        dataSource = countryResults
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        dataSource = countries
        return true
    }
    
    func showTexfieldViewErrorIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        
        if isValid == false {
            // We know for sure that the text is not valid, even if the user hasn't finished typing.
            if primerTextFieldView is PrimerCardNumberFieldView, !primerTextFieldView.isEmpty {
                cardNumberContainerView.errorText = Strings.CardFormView.CardNumber.invalidErrorMessage
            } else if primerTextFieldView is PrimerExpiryDateFieldView, !primerTextFieldView.isEmpty {
                expiryDateContainerView.errorText = Strings.CardFormView.ExpiryDate.invalidErrorMessage
            } else if primerTextFieldView is PrimerCVVFieldView, !primerTextFieldView.isEmpty {
                cvvContainerView.errorText = Strings.CardFormView.CVV.invalidErrorMessage
            } else if primerTextFieldView is PrimerCardholderNameFieldView, !primerTextFieldView.isEmpty {
                cardholderNameContainerView?.errorText = Strings.CardFormView.Cardholder.invalidErrorMessage
            } else if primerTextFieldView is PrimerPostalCodeFieldView {
                postalCodeContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.PostalCode.isRequiredErrorMessage : Strings.CardFormView.PostalCode.invalidErrorMessage
            } else if primerTextFieldView is PrimerCountryFieldView {
                countryFieldContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.CountryCode.isRequiredErrorMessage : Strings.CardFormView.CountryCode.invalidErrorMessage
            } else if primerTextFieldView is PrimerFirstNameFieldView {
                firstNameContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.FirstName.isRequiredErrorMessage :  Strings.CardFormView.FirstName.invalidErrorMessage
            } else if primerTextFieldView is PrimerLastNameFieldView {
                lastNameContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.LastName.isRequiredErrorMessage :  Strings.CardFormView.LastName.invalidErrorMessage
            } else if primerTextFieldView is PrimerCityFieldView {
                cityContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.City.isRequiredErrorMessage :  Strings.CardFormView.City.invalidErrorMessage
            } else if primerTextFieldView is PrimerStateFieldView {
                stateContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.State.isRequiredErrorMessage :  Strings.CardFormView.State.invalidErrorMessage
            } else if primerTextFieldView is PrimerAddressLine1FieldView {
                addressLine1ContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.AddressLine1.isRequiredErrorMessage :  Strings.CardFormView.AddressLine1.invalidErrorMessage
            } else if primerTextFieldView is PrimerAddressLine2FieldView {
                addressLine2ContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.AddressLine2.isRequiredErrorMessage :  Strings.CardFormView.AddressLine2.invalidErrorMessage
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
    
    func autofocusToNextFieldIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
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
}

extension CardTokenizationModule: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: true)
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        autofocusToNextFieldIfNeeded(for: primerTextFieldView, isValid: isValid)
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: isValid)
        enableSubmitButtonIfNeeded()
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork?) {
        self.cardNetwork = cardNetwork
        
        var network = self.cardNetwork?.rawValue.uppercased()
        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        
        if let cardNetwork = cardNetwork, cardNetwork != .unknown, cardNumberContainerView.rightImage2 == nil && cardNetwork.icon != nil {
            if network == nil || network == "UNKNOWN" {
                network = "OTHER"
            }
            
            cardNumberContainerView.rightImage2 = cardNetwork.icon
            
            firstly {
                clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodModule.paymentMethodConfiguration.type, cardNetwork: network)
            }
            .done {
                self.updateButtonUI()
            }
            .catch { _ in }
        } else if cardNumberContainerView.rightImage2 != nil && cardNetwork?.icon == nil {
            cardNumberContainerView.rightImage2 = nil
                        
            firstly {
                clientSessionActionsModule.unselectPaymentMethodIfNeeded()
            }
            .done {
                self.updateButtonUI()
            }
            .catch { _ in }
        }
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
        isLoading ? self.paymentMethodModule.userInterfaceModule.submitButton?.startAnimating() : self.paymentMethodModule.userInterfaceModule.submitButton?.stopAnimating()
        PrimerUIManager.primerRootViewController?.view.isUserInteractionEnabled = !isLoading
    }
}

#endif
