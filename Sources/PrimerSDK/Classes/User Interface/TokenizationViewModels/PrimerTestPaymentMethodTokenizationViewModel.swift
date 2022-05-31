//
//  PrimerTestPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 25/05/22.
//

#if canImport(UIKit)

import UIKit

class PrimerTestPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    internal private(set) var decisions = PrimerTestPaymentMethodOptions.FlowDecision.allCases
    private var selectedDecision: PrimerTestPaymentMethodOptions.FlowDecision!
    private var decisionSelectionCompletion: ((PrimerTestPaymentMethodOptions.FlowDecision) -> Void)?
    private var payButtonTappedCompletion: (() -> Void)?
    private var lastSelection: NSIndexPath!

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

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
        tableView.register(FlowDecisionTableViewCell.self, forCellReuseIdentifier: FlowDecisionTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
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
                self.presentDecisionsViewController()
            }
            .then { () -> Promise<PrimerTestPaymentMethodOptions.FlowDecision> in
                self.awaitDecisionSelection()
            }
            .then { decision -> Promise<Void> in
                self.selectedDecision = decision
                return self.awaitPayButtonTappedUponDecisionSelection()
            }
            .then { () -> Promise<Void> in
                self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                self.tokenize(decision: self.selectedDecision!)
            }
            .ensure { [unowned self] in
                DispatchQueue.main.async {
                    self.willDismissPaymentMethodUI?()
                    self.didDismissPaymentMethodUI?()
                }
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
}

extension PrimerTestPaymentMethodTokenizationViewModel {
    
    private func presentDecisionsViewController() -> Promise<Void> {
        return Promise { seal in
            let testPaymentMethodsVC = PrimerTestPaymentMethodViewController(viewModel: self)
            DispatchQueue.main.async {
                Primer.shared.primerRootVC?.show(viewController: testPaymentMethodsVC)
                seal.fulfill()
            }
        }
    }

    private func awaitDecisionSelection() -> Promise<PrimerTestPaymentMethodOptions.FlowDecision> {
        return Promise { seal in
            self.decisionSelectionCompletion = { decision in
                seal.fulfill(decision)
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
    
    private func tokenize(decision: PrimerTestPaymentMethodOptions.FlowDecision) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            self.tokenize(decision: decision) { paymentMethodTokenData, err in
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
    
    private func tokenize(decision: PrimerTestPaymentMethodOptions.FlowDecision, completion: @escaping (_ paymentMethodTokenData: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        let req = TestPaymentMethodTokenizationRequest(
            paymentInstrument: PrimerTestPaymentMethodOptions(paymentMethodType: self.config.type,
                                                              paymentMethodConfigId: self.config.id!,
                                                              sessionInfo: PrimerTestPaymentMethodOptions.SessionInfo(flowDecision: self.selectedDecision!)))
        
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return decisions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let decision = decisions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlowDecisionTableViewCell", for: indexPath) as! FlowDecisionTableViewCell
        cell.configure(decision: decision)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.lastSelection != nil {
            self.tableView.cellForRow(at: self.lastSelection as IndexPath)?.accessoryType = .none
        }
        self.tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        self.lastSelection = indexPath as NSIndexPath
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.decisionSelectionCompletion?(self.selectedDecision)
    }
}

#endif
