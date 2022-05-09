//
//  DotPayTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Admin on 8/11/21.
//

#if canImport(UIKit)

import SafariServices
import UIKit

class BankSelectorTokenizationViewModel: ExternalPaymentMethodTokenizationViewModel {
    
    internal private(set) var banks: [Bank] = []
    internal private(set) var dataSource: [Bank] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private var tokenizationService: TokenizationServiceProtocol?
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    /**
     This callback is used when the user selects a bank (i.e. taps on a table cell) and a fake tokenization is performed. This payment method token is then
     used by the merchant to create a payment, and subsequently receive a **requiredAction**.
     
     It must be set before the user taps on a cell, and nullified when a **paymentMethod** is returned.
     */
    fileprivate var tmpTokenizationCallback: ((_ paymentMethod: PaymentMethodToken?, _ err: Error?) -> Void)?
    
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
        tableView.register(BankTableViewCell.self, forCellReuseIdentifier: BankTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
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
        textField.placeholder = NSLocalizedString("search-bank-placeholder",
                                                        tableName: nil,
                                                        bundle: Bundle.primerResources,
                                                        value: "Search bank",
                                                        comment: "Search bank - Search bank textfield placeholder")
        textField.rightViewMode = .always
        return textField
    }()
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    func cancel() {
        self.willPresentExternalView = nil
        self.didPresentExternalView = nil
        self.willDismissExternalView = nil
        self.didDismissExternalView = nil
        self.webViewController = nil
        self.webViewCompletion = nil
        self.onResumeTokenCompletion = nil
        self.onClientToken = nil
        
        if tokenizationCompletion != nil {
            DispatchQueue.main.async {
                firstly {
                    ClientSession.Action.unselectPaymentMethodIfNeeded()
                }
                .done {
                    self.tokenizationCompletion = nil
                }
                .catch { _ in }
            }
        }
        
        tmpTokenizationCallback = nil
    }
        
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
        DispatchQueue.main.async {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
        
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
                place: .bankSelectionList))
        Analytics.Service.record(event: event)
    }
    
    private func continueTokenizationFlow() {
        
        firstly {
            self.validateReturningPromise()
        }
        .then { () -> Promise<Void> in
            self.handlePrimerWillCreatePaymentEvent(PaymentMethodData(type: self.config.type))
        }
        .then {
            self.fetchBanks()
        }
        .then { banks -> Promise<PaymentMethodToken> in
            self.banks = banks
            self.dataSource = banks
            let bsvc = BankSelectorViewController(viewModel: self)
            DispatchQueue.main.async {
                Primer.shared.primerRootVC?.show(viewController: bsvc)
            }
            
            return self.fetchPaymentMethodToken()
        }
        .then { tmpPaymentMethodTokenData -> Promise<PaymentMethodToken> in
            self.paymentMethodTokenData = tmpPaymentMethodTokenData
            return self.continueTokenizationFlow(for: tmpPaymentMethodTokenData)
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData
            
            DispatchQueue.main.async {
                self.tokenizationCompletion?(self.paymentMethodTokenData, nil)
            }
        }
        .ensure { [unowned self] in
            DispatchQueue.main.async {
                self.willDismissExternalView?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })
            }
            
            self.willPresentExternalView = nil
            self.didPresentExternalView = nil
            self.willDismissExternalView = nil
            self.didDismissExternalView = nil
            self.webViewController = nil
            self.webViewCompletion = nil
            self.onResumeTokenCompletion = nil
            self.onClientToken = nil
        }
        .catch { error in
            PrimerDelegateProxy.primerDidFailWithError(error, data: nil, decisionHandler: nil)
        }
    }
    
    private func fetchBanks() -> Promise<[Bank]> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            var paymentMethodRequestValue: String = ""
            switch self.config.type {
            case .adyenDotPay:
                paymentMethodRequestValue = "dotpay"
            case .adyenIDeal:
                paymentMethodRequestValue = "ideal"
            default:
                break
            }
                    
            let client: PrimerAPIClientProtocol = PrimerAPIClient()
            let request = BankTokenizationSessionRequest(
                paymentMethodConfigId: config.id!,
                parameters: BankTokenizationSessionRequestParameters(paymentMethod: paymentMethodRequestValue))
            
            client.listAdyenBanks(clientToken: decodedClientToken, request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let banks):
                    seal.fulfill(banks)
                }
            }
        }
    }
    
    private func fetchPaymentMethodToken() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            self.tmpTokenizationCallback = { (paymentMethod, err) in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true, "Should never get in here.")
                }
            }
        }
    }
    
    private func tokenize(bank: Bank) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            self.tokenize(bank: bank) { paymentMethod, err in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true, "Should always receive a payment method or an error")
                }
            }
        }
    }

    private func tokenize(bank: Bank, completion: @escaping (_ paymentMethod: PaymentMethodToken?, _ err: Error?) -> Void) {
        let req = BankSelectorTokenizationRequest(
            paymentInstrument: PaymentInstrument(
                paymentMethodConfigId: self.config.id!,
                sessionInfo: BankSelectorSessionInfo(issuer: bank.id),
                type: "OFF_SESSION_PAYMENT",
                paymentMethodType: config.type.rawValue))
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
        apiClient.tokenizePaymentMethod(
            clientToken: decodedClientToken,
            paymentMethodTokenizationRequest: req) { result in
                switch result {
                case .success(let paymentMethodTokenData):
                    self.paymentMethodTokenData = paymentMethodTokenData
                    completion(self.paymentMethodTokenData, nil)
                case .failure(let err):
                    completion(nil, err)
                }
            }
    }
    
}

extension BankSelectorTokenizationViewModel: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bank = dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BankTableViewCell", for: indexPath) as! BankTableViewCell
        cell.configure(viewModel: bank)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
        
        let bank = self.dataSource[indexPath.row]
        self.tokenize(bank: bank) { (paymentMethod, err) in
            if let err = err {
                self.tmpTokenizationCallback?(nil, err)
            } else if let paymentMethod = paymentMethod {
                self.tmpTokenizationCallback?(paymentMethod, nil)
            } else {
                assert(true, "Should never get in here.")
            }
        }
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
        
        var bankResults: [Bank] = []
        
        for bank in banks {
            if bank.name.lowercased().folding(options: .diacriticInsensitive, locale: nil).contains(query.lowercased().folding(options: .diacriticInsensitive, locale: nil)) == true {
                bankResults.append(bank)
            }
        }
        
        dataSource = bankResults
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        dataSource = banks
        return true
    }
}

extension BankSelectorTokenizationViewModel {
    
    override func handle(error: Error) {
        firstly {
            ClientSession.Action.unselectPaymentMethodIfNeeded()
        }
        .ensure {
            self.executeCompletionAndNullifyAfter(error: error)
            self.handleFailureFlow(error: error)
        }
        .catch { _ in }
    }
    
    override func handle(newClientToken clientToken: String) {
        
        guard let decodedClientToken = clientToken.jwtTokenPayload else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            self.handle(error: err)
            return
        }
        
        if decodedClientToken.intent?.contains("_REDIRECTION") == true {
            super.handle(newClientToken: clientToken)
        } else if decodedClientToken.intent == "CHECKOUT" {
            
            firstly {
                ClientTokenService.storeClientToken(clientToken)
            }
            .then{ () -> Promise<Void> in
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                return configService.fetchConfig()
            }
            .done {
                self.continueTokenizationFlow()
            }
            .catch { err in
                self.raisePrimerDidFailWithError(err)
            }
        }
    }
    
    override func handleSuccess() {
        self.tokenizationCompletion?(self.paymentMethodTokenData, nil)
        self.tokenizationCompletion = nil
    }
    
}

#endif
