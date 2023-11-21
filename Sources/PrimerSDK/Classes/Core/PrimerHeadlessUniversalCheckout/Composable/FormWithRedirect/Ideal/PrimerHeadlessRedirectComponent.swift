//
//  PrimerHeadlessRedirectComponent.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 16.11.2023.
//

import Foundation
protocol PrimerHeadlessRedirectComponent: PrimerHeadlessStartable {}
class WebRedirectComponent: PrimerHeadlessRedirectComponent {
    let paymentMethodType: PrimerPaymentMethodType
    
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    private let tokenizationModelDelegate: BankSelectorTokenizationDelegate
    private(set) var step: WebStep = .loading

    init(paymentMethodType: PrimerPaymentMethodType, tokenizationModelDelegate: BankSelectorTokenizationDelegate) {
        self.paymentMethodType = paymentMethodType
        self.tokenizationModelDelegate = tokenizationModelDelegate
        self.stepDelegate = self
        self.errorDelegate = self
    }

    func start() {

    }
}


extension WebRedirectComponent: PrimerHeadlessSteppableDelegate {
    func didReceiveStep(step: PrimerHeadlessStep) {
        guard let step = step as? WebStep else {
            return
        }
        self.step = step
        switch step {
        case .loading: break
        case .loaded: break
        case .dismissed: break
        case .success: break
        }
        logStep()
    }
}

extension WebRedirectComponent: PrimerHeadlessErrorableDelegate {
    func didReceiveError(error: PrimerError) {
    }
}

extension WebRedirectComponent: LogReporter {
    func logStep() {
        logger.info(message: step.logMessage)
        logger.info(message: self.paymentMethodType.rawValue)
    }
}

extension WebStep {
    var logMessage: String {
        switch self {
        case .loading: return "Web redirect is loading"
        case .loaded: return "Web redirect has loaded"
        case .dismissed: return "Payment dismissed by user"
        case .success: return "Payment was successfull"
        }
    }
}
