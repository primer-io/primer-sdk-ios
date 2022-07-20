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
    private var bankSelectionCompletion: ((Bank) -> Void)?
    private var tokenizationService: TokenizationServiceProtocol?
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
        textField.placeholder = Strings.BankSelector.searchBankTitle
        textField.rightViewMode = .always
        return textField
    }()
    
    private var selectedBank: Bank?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    func cancel() {
        self.webViewController = nil
        self.webViewCompletion = nil
        
//        if tokenizationCompletion != nil {
//            DispatchQueue.main.async {
//                firstly {
//                    ClientSession.Action.unselectPaymentMethodIfNeeded()
//                }
//                .done {
//                    self.tokenizationCompletion = nil
//                }
//                .catch { _ in }
//            }
//        }
        
        tmpTokenizationCallback = nil
    }
        
    override func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
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
                return self.presentBanksViewController()
            }
            .then { () -> Promise<Bank> in
                return self.awaitBankSelection()
            }
            .then { bank -> Promise<Void> in
                self.selectedBank = bank
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize(bank: self.selectedBank!)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .ensure { [unowned self] in
                DispatchQueue.main.async {
                    self.willDismissPaymentMethodUI?()
                    self.webViewController?.dismiss(animated: true, completion: {
                        self.didDismissPaymentMethodUI?()
                    })
                }

                self.webViewController = nil
                self.webViewCompletion = nil
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func presentBanksViewController() -> Promise<Void> {
        return Promise { seal in
            let bsvc = BankSelectorViewController(viewModel: self)
            DispatchQueue.main.async {
                Primer.shared.primerRootVC?.show(viewController: bsvc)
                seal.fulfill()
            }
        }
    }
    
    private func awaitBankSelection() -> Promise<Bank> {
        return Promise { seal in
            self.bankSelectionCompletion = { bank in
                seal.fulfill(bank)
            }
        }
    }
    
    private func fetchBanks() -> Promise<[Bank]> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
    
    private func tokenize(bank: Bank) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            self.tokenize(bank: bank) { paymentMethodTokenData, err in
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

    private func tokenize(bank: Bank, completion: @escaping (_ paymentMethodTokenData: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        let req = BankSelectorTokenizationRequest(
            paymentInstrument: PaymentInstrument(
                paymentMethodConfigId: self.config.id!,
                sessionInfo: BankSelectorSessionInfo(issuer: bank.id),
                type: "OFF_SESSION_PAYMENT",
                paymentMethodType: config.type.rawValue))
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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

#endif
