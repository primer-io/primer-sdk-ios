//
//  PrimerTestPaymentMethodTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

class PrimerTestPaymentMethodTokenizationModule: TokenizationModule {
    
    private let decisions = PrimerTestPaymentMethodSessionInfo.FlowDecision.allCases
    private var selectedDecision: PrimerTestPaymentMethodSessionInfo.FlowDecision!
    private var decisionSelectionCompletion: ((PrimerTestPaymentMethodSessionInfo.FlowDecision) -> Void)?
    private var payButtonTappedCompletion: (() -> Void)?
    private var lastSelectedIndexPath: IndexPath?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    // FIXME: Remove UI elements
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
    
    var viewHeight: CGFloat {
        180+(CGFloat(decisions.count)*tableView.rowHeight)
    }
    
    override func validate() -> Promise<Void> {
        return Promise { seal in
            if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            } else {
                seal.fulfill()
            }
        }
    }
    
    override func startFlow() -> Promise<PrimerPaymentMethodTokenData> {
//        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedNotification(_:)), name: Notification.Name.urlSchemeRedirect, object: nil)
        
        return super.startFlow()
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
                place: .bankSelectionList))
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
                return self.firePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodModule.paymentMethodConfiguration.type))
            }
            .done {
                seal.fulfill()
            }
            .ensure { [unowned self] in
                DispatchQueue.main.async {
//                    self.didDismissPaymentMethodUI?()
//                    self.didFinishPayment?(nil)
                }
            }
            .catch { err in
                DispatchQueue.main.async {
//                    self.didFinishPayment?(err)
                }
                seal.reject(err)
            }
        }
    }
    
    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
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
    
    private func tokenize(decision: PrimerTestPaymentMethodSessionInfo.FlowDecision, completion: @escaping (_ paymentMethodTokenData: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let sessionInfo = PrimerTestPaymentMethodSessionInfo(flowDecision: selectedDecision)
        
        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: self.paymentMethodModule.paymentMethodConfiguration.id!,
            paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
            sessionInfo: sessionInfo)
        
        let tokenizationService: TokenizationServiceProtocol = TokenizationService()
        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        
        firstly {
            tokenizationService.tokenize(requestBody: requestBody)
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData
            completion(self.paymentMethodTokenData, nil)
        }
        .catch { err in
            completion(nil, err)
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
                let testPaymentMethodsVC = PrimerTestPaymentMethodViewController(paymentMethodModule: self.paymentMethodModule)
                
//                self.willPresentPaymentMethodUI?()
                PrimerUIManager.primerRootViewController?.show(viewController: testPaymentMethodsVC)
//                self.didPresentPaymentMethodUI?()
                seal.fulfill()
            }
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
//            self.didPresentPaymentMethodUI?()
            
            firstly {
                self.awaitUserSelection()
            }
            .then { () -> Promise<Void> in
                return self.awaitPayButtonTappedUponDecisionSelection()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func awaitUserSelection() -> Promise<Void> {
        return Promise { seal in
            self.decisionSelectionCompletion = { decision in
                self.selectedDecision = decision
                seal.fulfill()
            }
        }
    }
    
    private func awaitPayButtonTappedUponDecisionSelection() -> Promise<Void> {
        return Promise { seal in
            self.payButtonTappedCompletion = {
                seal.fulfill()
            }
        }
    }
    
    func updateButtonUI() {
        if let amount = AppState.current.amount {
            self.configurePayButton(amount: amount)
        }
    }
    
    private func configurePayButton(amount: Int) {
        var title = Strings.PaymentButton.pay
        if PrimerInternal.shared.intent == .checkout {
            if let currency = AppState.current.currency {
                title += " \(amount.toCurrencyString(currency: currency))"
            }
            self.paymentMethodModule.userInterfaceModule.submitButton?.setTitle(title, for: .normal)
        }
    }
    
    private func enableSubmitButtonIfNeeded() {
        if lastSelectedIndexPath != nil {
            self.paymentMethodModule.userInterfaceModule.submitButton?.isEnabled = true
            self.paymentMethodModule.userInterfaceModule.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            self.paymentMethodModule.userInterfaceModule.submitButton?.isEnabled = false
            self.paymentMethodModule.userInterfaceModule.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }
}

extension PrimerTestPaymentMethodTokenizationModule: UITableViewDataSource, UITableViewDelegate {
    
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
        let stackView = UIStackView(arrangedSubviews: [self.paymentMethodModule.userInterfaceModule.submitButton!])
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
