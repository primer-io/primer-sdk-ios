//
//  PrimerTestPaymentMethodTokenizationViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
import PrimerFoundation
import PrimerFoundation
import PrimerNetworking
import PrimerUI
import UIKit

// swiftlint:disable:next type_name
final class PrimerTestPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {

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

    lazy var tableView: UITableView = {
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

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            throw handled(primerError: .invalidClientToken())
        }
    }

    override func start() {
        checkoutEventsNotifierModule.didStartTokenization = {
            self.enableUserInteraction(false)
        }

        self.checkoutEventsNotifierModule.didFinishTokenization = {
            self.enableUserInteraction(true)
        }

        self.didStartPayment = {
            self.enableUserInteraction(false)
        }

        self.didFinishPayment = { _ in
            self.enableUserInteraction(true)
        }

        super.start()
    }

    override func performPreTokenizationSteps() async throws {
        Analytics.Service.fire(event: Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: config.type,
                url: nil
            ),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .bankSelectionList
        ))

        defer {
            Task { @MainActor in
                self.didDismissPaymentMethodUI?()
                self.didFinishPayment?(nil)
            }
        }

        do {
            try validate()
            willPresentPaymentMethodUI?()
            try await presentPaymentMethodUserInterface()
            try await awaitUserInput()
            didStartPayment?()
            try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
            willDismissPaymentMethodUI?()
        } catch {
            Task { @MainActor in
                self.didFinishPayment?(error)
            }
            throw error
        }
    }

    override func performTokenizationStep() async throws {
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    @MainActor
    override func presentPaymentMethodUserInterface() async throws {
        let testPaymentMethodsVC = PrimerTestPaymentMethodViewController(viewModel: self)
        willPresentPaymentMethodUI?()
        PrimerUIManager.primerRootViewController?.show(viewController: testPaymentMethodsVC)
        didPresentPaymentMethodUI?()
    }

    override func awaitUserInput() async throws {
        didPresentPaymentMethodUI?()
        try await awaitUserSelection()
        try await awaitPayButtonTappedUponDecisionSelection()
    }

    // MARK: - Tokenize

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let selectedDecision else {
            throw handled(primerError: .invalidValue(key: "amount"))
        }

        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            throw handled(primerError: .invalidClientToken())
        }

        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: config.id!,
            paymentMethodType: config.type,
            sessionInfo: PrimerTestPaymentMethodSessionInfo(
                flowDecision: selectedDecision
            )
        )

        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        paymentMethodTokenData = try await tokenizationService.tokenize(requestBody: requestBody)
        return paymentMethodTokenData!
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
        Analytics.Service.fire(event: viewEvent)

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

    private func awaitUserSelection() async throws {
        await withCheckedContinuation { continuation in
            self.decisionSelectionCompletion = { decision in
                self.selectedDecision = decision
                continuation.resume()
            }
        }
    }

    private func awaitPayButtonTappedUponDecisionSelection() async throws {
        await withCheckedContinuation { continuation in
            self.payButtonTappedCompletion = {
                continuation.resume()
            }
        }
    }
}

extension PrimerTestPaymentMethodTokenizationViewModel {

    // MARK: Private helper methods

    private func enableUserInteraction(_ enable: Bool) {
        DispatchQueue.main.async {
            if enable {
                self.uiModule.submitButton?.stopAnimating()
            } else {
                self.uiModule.submitButton?.startAnimating()
            }
            PrimerUIManager.primerRootViewController?.enableUserInteraction(enable)
        }
    }

}

extension PrimerTestPaymentMethodTokenizationViewModel: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Table View delegate methods

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        8
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? HeaderFooterLabelView
        header?.configure(text: Strings.PrimerTest.headerViewText)
        return header
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        66
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
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
        decisions.count
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
