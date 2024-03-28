//
//  PrimerTestPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 25/05/22.
//

import UIKit

// swiftlint:disable:next type_name
class PrimerTestPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {

    // MARK: - Properties

    private let decisions = PrimerTestPaymentMethodSessionInfo.FlowDecision.allCases
    private var selectedDecision: PrimerTestPaymentMethodSessionInfo.FlowDecision!
    private var decisionSelectionCompletion: ((PrimerTestPaymentMethodSessionInfo.FlowDecision) -> Void)?
    private var payButtonTappedCompletion: (() -> Void)?
    private var lastSelectedIndexPath: IndexPath?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()

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
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(FlowDecisionTableViewCell.self, forCellReuseIdentifier: FlowDecisionTableViewCell.identifier)
        tableView.register(HeaderFooterLabelView.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    // MARK: - Overrides

    override func start() {

        self.checkouEventsNotifierModule.didStartTokenization = {
            self.uiModule.submitButton?.startAnimating()
            PrimerUIManager.primerRootViewController?.enableUserInteraction(false)
        }

        self.checkouEventsNotifierModule.didFinishTokenization = {
            self.uiModule.submitButton?.stopAnimating()
            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
        }

        self.didStartPayment = {
            self.uiModule.submitButton?.startAnimating()
            PrimerUIManager.primerRootViewController?.enableUserInteraction(false)
        }

        self.didFinishPayment = { _ in
            self.uiModule.submitButton?.stopAnimating()
            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
        }

        super.start()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: config.type,
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
            .then { () -> Promise<Void> in
                self.willPresentPaymentMethodUI?()
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                self.didStartPayment?()
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                self.willDismissPaymentMethodUI?()
                seal.fulfill()
            }
            .ensure { [unowned self] in
                DispatchQueue.main.async {
                    self.didDismissPaymentMethodUI?()
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
                self.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
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
                PrimerUIManager.primerRootViewController?.show(viewController: testPaymentMethodsVC)
                self.didPresentPaymentMethodUI?()
                seal.fulfill()
            }
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.didPresentPaymentMethodUI?()

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
        let viewEvent = Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: config.type,
                url: nil),
            extra: nil,
            objectType: .button,
            objectId: .submit,
            objectClass: "\(Self.self)",
            place: .cardForm
        )
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
        if PrimerInternal.shared.intent == .checkout {
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
}

extension PrimerTestPaymentMethodTokenizationViewModel {

    private func tokenize(decision: PrimerTestPaymentMethodSessionInfo.FlowDecision, completion: @escaping (_ paymentMethodTokenData: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"],
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }

        let sessionInfo = PrimerTestPaymentMethodSessionInfo(flowDecision: selectedDecision)

        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: config.id!,
            paymentMethodType: config.type,
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FlowDecisionTableViewCell", for: indexPath) as? FlowDecisionTableViewCell
        else {
            fatalError("Unexpected cell dequed in PrimerTestPaymentMethodTokenizationViewModel")
        }
        cell.configure(decision: decision)
        return cell
    }
}
