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
    
    // MARK: - Properties
    
    var inputs: [Input] = []
    private var cardComponentsManager: CardComponentsManager!
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    var didCancel: (() -> Void)?
    
    // FIXME: Is this the fix for the button's indicator?
    private var isTokenizing = false
            
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
    
    internal lazy var searchCountryTextField: PrimerSearchTextField = {
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
        let billingAddressModuleOptions = AppState.current.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
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
                Primer.shared.primerRootVC?.show(viewController: self.countrySelectorViewController)
            }
        })
    }()
    
    // MARK: All billing address fields
    
    internal var billingAddressCheckoutModuleOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? {
        return AppState.current.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
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
    
    // MARK: Input Payment Methods Array
    
    /// Array containing the payment method types expecting some input step to be performed
    let inputPaymentMethodTypes: [PrimerPaymentMethodType] = [.adyenBlik]
    
    // MARK: Account Info Payment Methods Array
    
    /// Array containing the payment method types expecting some account info
    /// to transfer the founds to
    let accountInfoPaymentMethodTypes: [PrimerPaymentMethodType] = [.rapydFast]
    
    // MARK: Account Info Payment
    
    /// Generic info view
    var accountInfoView: PrimerFormView?
    
    // MARK: Input completion block
    
    /// Input completion block callback
    var userInputCompletion: (() -> Void)?

    // MARK: - Init
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
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
                    paymentMethodType: self.config.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: event)
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.evaluateStepAfterSelectedPaymentMethodSessionActionFire()
            }
            .then { () -> Promise<Void> in
                return self.evaluatePaymentMethodNeedingFurtherUserActions()
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutTokenizationDidStart(for: self.config.type)
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
    
    override func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?> {
        return Promise { seal in
            if decodedClientToken.intent?.contains("_REDIRECTION") == true {
                   if let statusUrlStr = decodedClientToken.statusUrl,
                      let statusUrl = URL(string: statusUrlStr),
                      decodedClientToken.intent != nil {
                       
                       firstly {
                           self.presentPaymentMethodAppropriateViewController()
                       }
                       .then { () -> Promise<String> in
                           let pollingModule = PollingModule(url: statusUrl)
                           self.didCancel = {
                               pollingModule.cancel()
                               return
                           }
                           
                           return pollingModule.start()
                       }
                       .done { resumeToken in
                           seal.fulfill(resumeToken)
                       }
                       .catch { err in
                           seal.reject(err)
                       }
                   } else {
                       let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                       seal.reject(error)
                   }
            }
        }
    }
    
    private func evaluateStepAfterSelectedPaymentMethodSessionActionFire() -> Promise<Void> {
        switch self.config.type {
        case .adyenBlik:
            return self.presentPaymentMethodAppropriateViewController()
        default:
            return Promise()
        }
    }
    
    private func evaluatePaymentMethodNeedingFurtherUserActions() -> Promise<Void> {
        switch self.config.type {
        case .adyenBlik:
            return self.awaitUserInput()
        default:
            return Promise()
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.userInputCompletion = {
                seal.fulfill()
            }
        }
    }
    
    fileprivate func enableSubmitButton(_ flag: Bool) {
        self.uiModule.submitButton?.isEnabled = flag
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        self.uiModule.submitButton?.backgroundColor = flag ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
    }
    
    override func submitButtonTapped() {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .submit,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
        
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false

        switch config.type {
        case "ADYEN_BLIK":
            self.uiModule.submitButton?.startAnimating()
            self.userInputCompletion?()
            
        default:
            fatalError("Must be overridden")
        }
    }
    
    private func tokenize() -> Promise<PaymentMethodToken> {
        switch config.type {
        case "ADYEN_BLIK":
            return Promise { seal in
                guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let configId = config.id else {
                    let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
                                
                let tokenizationRequest = BlikPaymentMethodTokenizationRequest(
                    paymentInstrument: BlikPaymentMethodOptions(
                        paymentMethodType: config.type,
                        paymentMethodConfigId: configId,
                        sessionInfo: BlikPaymentMethodOptions.SessionInfo(
                            blikCode: blikCode,
                            locale: PrimerSettings.current.localeData.localeCode)))
                
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
        case .rapydFast:
            return Promise { seal in
                guard let configId = config.id else {
                    let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                var sessionInfo: AsyncPaymentMethodOptions.SessionInfo?
                sessionInfo = AsyncPaymentMethodOptions.SessionInfo(locale: PrimerSettings.current.localeData.localeCode)
                
                
                let request = AsyncPaymentMethodTokenizationRequest(
                    paymentInstrument: AsyncPaymentMethodOptions(
                        paymentMethodType: config.type,
                        paymentMethodConfigId: configId,
                        sessionInfo: sessionInfo))
                
                let tokenizationService: TokenizationServiceProtocol = TokenizationService()
                firstly {
                    tokenizationService.tokenize(request: request)
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
}

extension FormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {
    
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


extension FormPaymentMethodTokenizationViewModel: UITableViewDataSource, UITableViewDelegate {
    
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
        Primer.shared.primerRootVC?.popViewController()
    }
}

extension FormPaymentMethodTokenizationViewModel: SearchableItemsPaymentMethodTokenizationViewModelProtocol {
    
    func cancel() {
        didCancel?()
        
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        
        let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
        ErrorHandler.handle(error: err)
    }
}

extension FormPaymentMethodTokenizationViewModel: UITextFieldDelegate {
    
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
}

#endif
