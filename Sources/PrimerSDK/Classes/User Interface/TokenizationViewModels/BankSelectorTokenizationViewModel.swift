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
    
    override lazy var title: String = {
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
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .adyenDotPay,
                .adyenIDeal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
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
    
    override lazy var buttonColor: UIColor? = {
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
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .adyenDotPay:
            return nil
        case .adyenIDeal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
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
    
    override lazy var buttonBorderColor: UIColor? = {
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
    
    override lazy var buttonTintColor: UIColor? = {
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
    
    override lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    override lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    internal private(set) var banks: [Bank] = []
    internal private(set) var dataSource: [Bank] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private var tokenizationService: TokenizationServiceProtocol?
    override func validate() throws {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = state.decodedClientToken, decodedClientToken.isValid else {
            let err = PaymentException.missingClientToken
            _ = ErrorHandler.shared.handle(error: err)
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
        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
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
        textField.backgroundColor = UIColor(red: 36.0/255, green: 42.0/255, blue: 47.0/255, alpha: 0.03)
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
        super.startTokenizationFlow()
    }
    
    fileprivate func continueTokenizationFlow() {
        do {
            try validate()
        } catch {
            DispatchQueue.main.async {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                Primer.shared.delegate?.checkoutFailed?(with: error)
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
                if Primer.shared.flow.internalSessionFlow.vaulted {
                    Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
                }
                
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
                Primer.shared.delegate?.checkoutFailed?(with: err)
                self.handleFailedTokenizationFlow(error: err)
            }
        }
    }
    
    private func fetchBanks() -> Promise<[Bank]> {
        return Promise { seal in
            let state: AppStateProtocol = DependencyContainer.resolve()
            let decodedClientToken = state.decodedClientToken!
            
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
            
            client.adyenBanksList(clientToken: decodedClientToken, request: request) { result in
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
//                    self.handleFailedTokenizationFlow(error: err)
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
//                    Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
    //                self.handleSuccessfulTokenizationFlow()
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
        let state: AppStateProtocol = DependencyContainer.resolve()

        let req = BankSelectorTokenizationRequest(
            paymentInstrument: PaymentInstrument(
                paymentMethodConfigId: self.config.id!,
                sessionInfo: BankSelectorSessionInfo(issuer: bank.id),
                type: "OFF_SESSION_PAYMENT",
                paymentMethodType: config.type.rawValue))
        
        guard let clientToken = state.decodedClientToken else {
            completion(nil, PrimerError.clientTokenNull)
            return
        }
        
        let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
        apiClient.tokenizePaymentMethod(
            clientToken: clientToken,
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
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        
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
        do {
            // For Apaya there's no redirection URL, once the webview is presented it will get its response from a URL redirection.
            // We'll end up in here only for surcharge.
            
            guard let decodedClientToken = clientToken.jwtTokenPayload else {
                let err = PrimerError.clientTokenNull
                self.handle(error: err)
                return
            }
            
            if decodedClientToken.intent?.contains("_REDIRECTION") == true {
                super.handle(newClientToken: clientToken)
            } else if decodedClientToken.intent == "CHECKOUT" {
                try ClientTokenService.storeClientToken(clientToken)
                
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                
                firstly {
                    configService.fetchConfig()
                }
                .done {
                    self.continueTokenizationFlow()
                }
                .catch { err in
                    self.handle(error: err)
                }
            } else {
                let err = PrimerError.clientTokenNull
                self.handle(error: err)
                return
            }
        } catch {
            DispatchQueue.main.async {
                Primer.shared.delegate?.onResumeError?(error)
                self.handle(error: error)
            }
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
