//
//  PrimerTestPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 25/05/22.
//

#if canImport(UIKit)

import UIKit

class PrimerTestPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    // MARK: - PROPERTIES

    internal private(set) var decisions = PrimerTestPaymentMethodOptions.FlowDecision.allCases
    private var selectedDecision: PrimerTestPaymentMethodOptions.FlowDecision!
    private var decisionSelectionCompletion: ((PrimerTestPaymentMethodOptions.FlowDecision) -> Void)?
    private var payButtonTappedCompletion: (() -> Void)?
    private var lastSelectedIndexPath: IndexPath?
    
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
    
    private lazy var _originalImage: UIImage? = {
        switch self.config.type {
        case .primerTestPayPal:
            return UIImage(named: "paypal-logo-1", in: Bundle.primerResources, compatibleWith: nil)
        default:
            return self.buttonImage
        }
    }()
    
//    lazy var submitButton: PrimerButton = {
//        let submitButton = PrimerButton()
//        submitButton.translatesAutoresizingMaskIntoConstraints = false
//        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        submitButton.isAccessibilityElement = true
//        submitButton.accessibilityIdentifier = "submit_btn"
//        submitButton.isEnabled = false
//        submitButton.setTitle(buttonTitle, for: .normal)
//        submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
//        submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
//        submitButton.layer.cornerRadius = 4
//        submitButton.clipsToBounds = true
//        submitButton.addTarget(self, action: #selector(payButtonTapped(_:)), for: .touchUpInside)
//        return submitButton
//    }()
    
    // MARK: - DEINIT
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    // MARK: - OVERRIDES

    override var originalImage: UIImage? {
        get {
            _originalImage
        }
        set {
            _originalImage = newValue
        }
    }
        
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
    
    // MARK: - Table View delegate methods
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? HeaderFooterLabelView
        header?.configure(text: "This is a mocked flow for sandbox. Choose the result you want to test from the list below.")
        return header
    }
        
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
        if let lastSelectedIndexPath = self.lastSelectedIndexPath {
            self.tableView.deselectRow(at: lastSelectedIndexPath, animated: true)
        }
        self.lastSelectedIndexPath = indexPath
        self.selectedDecision = decisions[indexPath.row]
        self.decisionSelectionCompletion?(self.selectedDecision)
    }
}

#endif
