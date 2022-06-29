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
    
    private lazy var _title: String = {
        switch config.type {
        case .adyenDotPay:
            return "Dot Pay"
        case .adyenIDeal:
            return "iDeal"
        default:
            assert(true, "Shouldn't end up in here")
            return ""
        }
    }()
    override var title: String {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .adyenDotPay:
            return UIImage(named: "dot-pay-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenIDeal:
            return UIImage(named: "iDeal-logo", in: Bundle.primerResources, compatibleWith: nil)
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
        case .adyenDotPay:
            return .white
        case .adyenIDeal:
            return UIColor(red: 204.0/255, green: 0.0/255, blue: 102.0/255, alpha: 1.0)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonColor: UIColor? {
        get { return _buttonColor }
        set { _buttonColor = newValue }
    }
    
    private lazy var _buttonBorderWidth: CGFloat = {
        switch config.type {
        case .adyenDotPay:
            return 1.0
        case .adyenIDeal:
            return 0.0
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
        case .adyenDotPay:
            return .black
        case .adyenIDeal:
            return nil
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
        case .adyenDotPay:
            return nil
        case .adyenIDeal:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTintColor: UIColor? {
        get { return _buttonTintColor }
        set { _buttonTintColor = newValue }
    }
    
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
        
        if completion != nil {
            DispatchQueue.main.async {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                self.completion = nil
            }
        }
        
        tmpTokenizationCallback = nil
    }
        
    @objc
    override func startTokenizationFlow() {
        didStartTokenization?()
        
        self.completion = { (tok, err) in
            if let err = err {
                self.handleFailedTokenizationFlow(error: err)
            } else {
                self.handleSuccessfulTokenizationFlow()
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.beginIgnoringInteractionEvents()
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
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
        
        if PrimerDelegateProxy.isClientSessionActionsImplemented {
            let params: [String: Any] = ["paymentMethodType": config.type.rawValue]
            ClientSession.Action.selectPaymentMethod(resumeHandler: self, withParameters: params)
        } else {
            continueTokenizationFlow()
        }
    }
    
    fileprivate func continueTokenizationFlow() {
        do {
            try validate()
        } catch {
            DispatchQueue.main.async {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        firstly {
            self.fetchBanks()
        }
        .then { banks -> Promise<PaymentMethodToken> in
            self.banks = banks
            self.dataSource = banks
            let bsvc = BankSelectorViewController(viewModel: self)
            DispatchQueue.main.async {
                Primer.shared.primerRootVC?.show(viewController: bsvc)
                UIApplication.shared.endIgnoringInteractionEvents()
            }
            
            return self.fetchPaymentMethodToken()
        }
        .then { tmpPaymentMethod -> Promise<PaymentMethodToken> in
            self.paymentMethod = tmpPaymentMethod
            return self.continueTokenizationFlow(for: tmpPaymentMethod)
        }
        .done { paymentMethod in
            self.paymentMethod = paymentMethod
            
            DispatchQueue.main.async {
                self.completion?(self.paymentMethod, nil)
                self.handleSuccessfulTokenizationFlow()
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
        .catch { err in
            DispatchQueue.main.async {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                PrimerDelegateProxy.checkoutFailed(with: err)
                self.handleFailedTokenizationFlow(error: err)
            }
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
                case .success(let paymentMethod):
                    self.paymentMethod = paymentMethod
                    completion(paymentMethod, nil)
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
        ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
        self.completion?(nil, error)
        self.completion = nil
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
                DispatchQueue.main.async {
                    PrimerDelegateProxy.onResumeError(err)
                }
                self.handle(error: err)
            }
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
