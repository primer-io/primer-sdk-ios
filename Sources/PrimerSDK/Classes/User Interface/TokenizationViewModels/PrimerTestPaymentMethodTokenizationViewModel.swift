//
//  PrimerTestPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 25/05/22.
//

#if canImport(UIKit)

import UIKit

class PrimerTestPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    // MARK: - Properties
    
    internal private(set) var decisions = PrimerTestPaymentMethodOptions.FlowDecision.allCases
    private var selectedDecision: PrimerTestPaymentMethodOptions.FlowDecision!
    private var decisionSelectionCompletion: ((PrimerTestPaymentMethodOptions.FlowDecision) -> Void)?
    private var payButtonTappedCompletion: (() -> Void)?
    private var lastSelectedIndexPath: IndexPath?
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    var viewHeight: CGFloat {
        180+(CGFloat(decisions.count)*tableView.rowHeight)
    }
    
    internal lazy var tableView: UITableView = {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.rowHeight = 56
        tableView.backgroundColor = theme.view.backgroundColor
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }        
        tableView.register(FlowDecisionTableViewCell.self, forCellReuseIdentifier: FlowDecisionTableViewCell.identifier)
        tableView.register(HeaderFooterLabelView.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    // MARK: - Deinit
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    // MARK: - Overrides
    
    override func start() {
        
        self.didStartTokenization = {
            self.uiModule.submitButton?.startAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false
        }
        
        self.didFinishTokenization = { err in
            self.uiModule.submitButton?.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        
        self.didStartPayment = {
            self.uiModule.submitButton?.startAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false
        }
        
        self.didFinishPayment = { err in
            self.uiModule.submitButton?.stopAnimating()
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        
        super.start()
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: config.type,
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
            .then { () -> Promise<Void> in
                self.willPresentPaymentMethodUI?()
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                self.didPresentPaymentMethodUI?()
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                return self.awaitPayButtonTappedUponDecisionSelection()
            }
            .then { () -> Promise<Void> in
                self.didStartPayment?()
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                self.willDismissPaymentMethodUI?()
                self.didStartTokenization?()
                seal.fulfill()
            }
            .ensure { [unowned self] in
                DispatchQueue.main.async {
                    self.didDismissPaymentMethodUI?()
                    self.didFinishTokenization?(nil)
                    self.didFinishPayment?(nil)
                }
            }
            .catch { err in
                DispatchQueue.main.async {
                    self.didFinishPayment?(err)
                }
                seal.reject(err)
            }
        }
    }
    
    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.tokenize()
            }
            .done { paymentMethodTokenData in
                self.paymentMethodTokenData = paymentMethodTokenData
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
    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                let testPaymentMethodsVC = PrimerTestPaymentMethodViewController(viewModel: self)
                
                self.willPresentPaymentMethodUI?()
                Primer.shared.primerRootVC?.show(viewController: testPaymentMethodsVC)
                self.didPresentPaymentMethodUI?()
                seal.fulfill()
            }
        }
    }
    
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.decisionSelectionCompletion = { decision in
                self.selectedDecision = decision
                seal.fulfill()
            }
        }
    }
    
    override func validate() throws {
        
    }
    
    // MARK: - Tokenize
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            self.tokenize(decision: self.selectedDecision!) { paymentMethodTokenData, err in
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
    
    // MARK: - Pay Action
    
    override func submitButtonTapped() {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: config.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .submit,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
        
        payButtonTappedCompletion?()
    }
}

extension PrimerTestPaymentMethodTokenizationViewModel {
    
    // MARK: - UI Helpers
    
    func updateButtonUI() {
        if let amount = AppState.current.amount {
            self.configurePayButton(amount: amount)
        }
    }
    
    private func configurePayButton(amount: Int) {
        var title = Strings.PaymentButton.pay
        if Primer.shared.intent == .checkout {
            if let currency = AppState.current.currency {
                title += " \(amount.toCurrencyString(currency: currency))"
            }
            self.uiModule.submitButton?.setTitle(title, for: .normal)
        }
    }
    
    private func enableSubmitButtonIfNeeded() {
        if lastSelectedIndexPath != nil {
            self.uiModule.submitButton?.isEnabled = true
            self.uiModule.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            self.uiModule.submitButton?.isEnabled = false
            self.uiModule.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }
}

extension PrimerTestPaymentMethodTokenizationViewModel {
    
    // MARK: - Flow Promises
    
    private func awaitPayButtonTappedUponDecisionSelection() -> Promise<Void> {
        return Promise { seal in
            self.payButtonTappedCompletion = {
                seal.fulfill()
            }
        }
    }
}

extension PrimerTestPaymentMethodTokenizationViewModel {
    
    private func tokenize(decision: PrimerTestPaymentMethodOptions.FlowDecision, completion: @escaping (_ paymentMethodTokenData: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        let req = TestPaymentMethodTokenizationRequest(
            paymentInstrument: PrimerTestPaymentMethodOptions(paymentMethodType: config.type,
                                                              paymentMethodConfigId: config.id!,
                                                              sessionInfo: PrimerTestPaymentMethodOptions.SessionInfo(flowDecision: selectedDecision!)))
        
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

extension PrimerTestPaymentMethodTokenizationViewModel: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View delegate methods
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? HeaderFooterLabelView
        header?.configure(text: Strings.PrimerTest.headerViewText)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        updateButtonUI()
        let stackView = UIStackView(arrangedSubviews: [uiModule.submitButton!])
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let lastSelectedIndexPath = lastSelectedIndexPath {
            tableView.deselectRow(at: lastSelectedIndexPath, animated: true)
        }
        lastSelectedIndexPath = indexPath
        selectedDecision = decisions[indexPath.row]
        decisionSelectionCompletion?(selectedDecision)
        enableSubmitButtonIfNeeded()
    }

    
    // MARK: - Table View data source methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return decisions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let decision = decisions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlowDecisionTableViewCell", for: indexPath) as! FlowDecisionTableViewCell
        cell.configure(decision: decision)
        return cell
    }
}

#endif
