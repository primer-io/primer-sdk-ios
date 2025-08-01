//
//  BankSelectorTokenizationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable file_length

import SafariServices
import UIKit

final class BankSelectorTokenizationViewModel: WebRedirectPaymentMethodTokenizationViewModel {
    internal private(set) var banks: [AdyenBank] = []
    internal private(set) var dataSource: [AdyenBank] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    var bankSelectionCompletion: ((AdyenBank) -> Void)?

    let paymentMethodType: PrimerPaymentMethodType

    let apiClient: PrimerAPIClientBanksProtocol

    convenience init(config: PrimerPaymentMethod,
                     apiClient: PrimerAPIClientBanksProtocol = PrimerAPIClient()) {
        self.init(config: config,
                  uiManager: PrimerUIManager.shared,
                  tokenizationService: TokenizationService(),
                  createResumePaymentService: CreateResumePaymentService(paymentMethodType: config.type),
                  apiClient: apiClient
        )
    }

    init(config: PrimerPaymentMethod,
         uiManager: PrimerUIManaging,
         tokenizationService: TokenizationServiceProtocol,
         createResumePaymentService: CreateResumePaymentServiceProtocol,
         apiClient: PrimerAPIClientBanksProtocol
    ) {
        self.paymentMethodType = config.internalPaymentMethodType!
        self.apiClient = apiClient
        super.init(config: config,
                   uiManager: uiManager,
                   tokenizationService: tokenizationService,
                   createResumePaymentService: createResumePaymentService)
    }

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            throw handled(primerError: .invalidClientToken())
        }
    }

    internal lazy var tableView: UITableView = {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = theme.view.backgroundColor
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.rowHeight = 41
        tableView.register(BankTableViewCell.self, forCellReuseIdentifier: BankTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = AccessibilityIdentifier.BanksComponent.banksList.rawValue
        return tableView
    }()

    internal lazy var searchBankTextField: PrimerSearchTextField? = {
        let textField = PrimerSearchTextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textField.delegate = self
        textField.borderStyle = .none
        textField.layer.cornerRadius = 3.0
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.placeholder = Strings.BankSelector.searchBankTitle
        textField.rightViewMode = .always
        textField.accessibilityIdentifier = AccessibilityIdentifier.BanksComponent.searchBar.rawValue
        return textField
    }()

    private var selectedBank: AdyenBank?

    override func cancel() {
        self.webViewController = nil
        self.webViewCompletion = nil
        super.cancel()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        if !PrimerInternal.isInHeadlessMode {
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(true)
            }
        }

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
            place: .bankSelectionList
        )
        Analytics.Service.record(event: event)

        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then {
                self.fetchBanks()
            }
            .then { banks -> Promise<Void> in
                self.banks = banks
                self.dataSource = banks
                return self.presentBankList()
            }
            .then { () -> Promise<Void> in
                return self.awaitBankSelection()
            }
            .then { () -> Promise<Void> in
                self.bankSelectionCompletion = nil
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                seal.fulfill()
            }
            .ensure { [unowned self] in
                DispatchQueue.main.async {
                    self.willDismissPaymentMethodUI?()
                    self.webViewController?.dismiss(animated: true, completion: {
                        self.didDismissPaymentMethodUI?()
                    })
                }

                self.bankSelectionCompletion = nil
                self.webViewController = nil
                self.webViewCompletion = nil
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performPreTokenizationSteps() async throws {
        if !PrimerInternal.isInHeadlessMode {
            await uiManager.primerRootViewController?.enableUserInteraction(true)
        }

        Analytics.Service.fire(event: Analytics.Event.ui(
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
            place: .bankSelectionList
        ))

        defer {
            DispatchQueue.main.async {
                self.willDismissPaymentMethodUI?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissPaymentMethodUI?()
                })
            }

            self.bankSelectionCompletion = nil
            self.webViewController = nil
            self.webViewCompletion = nil
        }

        try validate()
        banks = try await fetchBanks()
        dataSource = banks
        await presentBankList_main_actor()
        await awaitBankSelection()
        bankSelectionCompletion = nil
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
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
            .ensure { [unowned self] in
                DispatchQueue.main.async {
                    self.willDismissPaymentMethodUI?()
                    self.webViewController?.dismiss(animated: true, completion: {
                        self.didDismissPaymentMethodUI?()
                    })
                }

                self.bankSelectionCompletion = nil
                self.selectedBank = nil
                self.webViewController = nil
                self.webViewCompletion = nil
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performTokenizationStep() async throws {
        defer {
            DispatchQueue.main.async {
                    self.willDismissPaymentMethodUI?()
                    self.webViewController?.dismiss(animated: true, completion: {
                        self.didDismissPaymentMethodUI?()
                    })
                }

                self.bankSelectionCompletion = nil
                self.selectedBank = nil
                self.webViewController = nil
                self.webViewCompletion = nil
        }

        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    private func presentBankList() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                let bsvc = BankSelectorViewController(viewModel: self)
                self.uiManager.primerRootViewController?.show(viewController: bsvc)
                seal.fulfill()
            }
        }
    }

    @MainActor
    private func presentBankList_main_actor() {
        uiManager.primerRootViewController?.show(viewController: BankSelectorViewController(viewModel: self))
    }

    private func awaitBankSelection() -> Promise<Void> {
        return Promise { seal in
            self.bankSelectionCompletion = { bank in
                self.selectedBank = bank
                seal.fulfill()
            }
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.config.type)
        }
    }

    private func awaitBankSelection() async {
        await withCheckedContinuation { continuation in
            self.bankSelectionCompletion = { bank in
                self.selectedBank = bank
                continuation.resume()
            }
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: config.type)
        }
    }

    private func fetchBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                return seal.reject(handled(primerError: .invalidClientToken()))
            }

            var paymentMethodRequestValue: String = ""
            switch self.config.type {
            case PrimerPaymentMethodType.adyenDotPay.rawValue:
                paymentMethodRequestValue = "dotpay"
            case PrimerPaymentMethodType.adyenIDeal.rawValue:
                paymentMethodRequestValue = "ideal"
            default:
                break
            }

            let request = Request.Body.Adyen.BanksList(
                paymentMethodConfigId: config.id!,
                parameters: BankTokenizationSessionRequestParameters(paymentMethod: paymentMethodRequestValue))

            self.apiClient.listAdyenBanks(clientToken: decodedJWTToken, request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)

                case .success(let banks):
                    seal.fulfill(banks.result)
                }
            }
        }
    }

    private func fetchBanks() async throws -> [AdyenBank] {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let configId = config.id else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        let paymentMethodRequestValue = switch config.type {
        case PrimerPaymentMethodType.adyenDotPay.rawValue: "dotpay"
        case PrimerPaymentMethodType.adyenIDeal.rawValue: "ideal"
        default: ""
        }

        return try await apiClient.listAdyenBanks(
            clientToken: decodedJWTToken,
            request: Request.Body.Adyen.BanksList(
                paymentMethodConfigId: configId,
                parameters: BankTokenizationSessionRequestParameters(paymentMethod: paymentMethodRequestValue)
            )
        ).result
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            self.tokenize(bank: self.selectedBank!) { paymentMethodTokenData, err in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethodTokenData = paymentMethodTokenData {
                    seal.fulfill(paymentMethodTokenData)
                } else {
                    assert(true, "Should always receive a payment method or an error")
                }
            }
        }
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let selectedBank else {
            throw PrimerError.invalidValue(key: "selectedBank")
        }

        return try await tokenize(bank: selectedBank)
    }

    private func tokenize(bank: AdyenBank, completion: @escaping (_ paymentMethodTokenData: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            return completion(nil, handled(primerError: .invalidClientToken()))
        }

        let requestBody = Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: self.config.id!,
                paymentMethodType: config.type,
                sessionInfo: BankSelectorSessionInfo(issuer: bank.id)))

        firstly {
            self.tokenizationService.tokenize(requestBody: requestBody)
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData
            completion(self.paymentMethodTokenData, nil)
        }
        .catch { err in
            completion(nil, err)
        }
    }

    private func tokenize(bank: AdyenBank) async throws -> PrimerPaymentMethodTokenData {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let configId = config.id else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        paymentMethodTokenData = try await tokenizationService.tokenize(requestBody: Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: configId,
                paymentMethodType: config.type,
                sessionInfo: BankSelectorSessionInfo(issuer: bank.id)
            )
        ))

        return paymentMethodTokenData!
    }
}

extension BankSelectorTokenizationViewModel: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bank = dataSource[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BankTableViewCell",
                                                       for: indexPath) as? BankTableViewCell
        else {
            fatalError("Unexpected cell dequed in BankSelectorTokenizationViewModel")
        }
        cell.configure(viewModel: bank)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bank = self.dataSource[indexPath.row]
        self.bankSelectionCompletion?(bank)
    }
}

extension BankSelectorTokenizationViewModel: UITextFieldDelegate {

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
            dataSource = banks
            return true
        }
        dataSource = filterBanks(query: query)
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        dataSource = banks
        return true
    }
}

extension BankSelectorTokenizationViewModel: BankSelectorTokenizationProviding {
    func retrieveListOfBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then {
                self.fetchBanks()
            }
            .done { banks in
                self.banks = banks
                seal.fulfill(banks)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func retrieveListOfBanks() async throws -> [AdyenBank] {
        try validate()
        banks = try await fetchBanks()
        return banks
    }

    func filterBanks(query: String) -> [AdyenBank] {
        guard !query.isEmpty else {
            return banks
        }
        return banks.filter {
            $0.name.lowercased()
                .folding(options: .diacriticInsensitive, locale: nil)
                .contains(query.lowercased()
                            .folding(options: .diacriticInsensitive, locale: nil))
        }
    }

    func tokenize(bankId: String) -> Promise<Void> {
        self.selectedBank = banks.first(where: { $0.id == bankId })
        return performTokenizationStep()
            .then { () -> Promise<Void> in
                return self.performPostTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                return self.handlePaymentMethodTokenData()
            }
    }

    func tokenize(bankId: String) async throws {
        selectedBank = banks.first(where: { $0.id == bankId })
        try await performTokenizationStep()
        try await performPostTokenizationSteps()
        try await handlePaymentMethodTokenData()
    }

    func handlePaymentMethodTokenData() -> Promise<Void> {
        return Promise { _ in
            processPaymentMethodTokenData()
        }
    }

    func handlePaymentMethodTokenData() async throws {
        await processPaymentMethodTokenData()
    }
}

extension BankSelectorTokenizationViewModel: WebRedirectTokenizationDelegate {}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
