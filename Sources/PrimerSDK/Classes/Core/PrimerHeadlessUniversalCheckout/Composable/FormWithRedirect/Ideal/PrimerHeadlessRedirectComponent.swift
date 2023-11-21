//
//  PrimerHeadlessRedirectComponent.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 16.11.2023.
//

import Foundation
protocol PrimerHeadlessRedirectComponent: PrimerHeadlessStartable {}
final class WebRedirectComponent: PrimerHeadlessRedirectComponent {
    let paymentMethodType: PrimerPaymentMethodType
    
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    private var tokenizationModelDelegate: WebRedirectTokenizationDelegate
    private(set) var step: WebStep = .loading {
        didSet {
            logStep()
        }
    }

    init(paymentMethodType: PrimerPaymentMethodType, tokenizationModelDelegate: WebRedirectTokenizationDelegate) {
        self.paymentMethodType = paymentMethodType
        self.tokenizationModelDelegate = tokenizationModelDelegate
        self.stepDelegate = self
        self.errorDelegate = self
        self.tokenizationModelDelegate.didPresentPaymentMethodUI = { [weak self] in
            guard let self else { return }
            self.step = .loaded
        }
        self.tokenizationModelDelegate.didDismissPaymentMethodUI = { [weak self] in
            guard let self else { return }
            self.step = .dismissed
        }
        self.tokenizationModelDelegate.didFinishPayment = { [weak self] error in
            guard let self else { return }
            self.step = error == nil ? .success : .failure
        }
    }

    func start() {
        step = .loading
    }
}


extension WebRedirectComponent: PrimerHeadlessSteppableDelegate {
    func didReceiveStep(step: PrimerHeadlessStep) {
        guard let step = step as? WebStep else {
            return
        }
        self.step = step
        logStep()
    }
}

extension WebRedirectComponent: PrimerHeadlessErrorableDelegate {
    func didReceiveError(error: PrimerError) {
        print("Did receive error \(error)")
    }
}

extension WebRedirectComponent: LogReporter {
    func logStep() {
        let logMessage = step.logMessage
        logger.info(message: logMessage)
        logger.info(message: paymentMethodType.rawValue)
        let stepEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: MessageEventProperties(
                message: logMessage,
                messageType: .info,
                severity: .info))
        Analytics.Service.record(events: [stepEvent])
    }
}

extension WebStep {
    var logMessage: String {
        switch self {
        case .loading: return "Web redirect is loading"
        case .loaded: return "Web redirect has loaded"
        case .dismissed: return "Payment dismissed by user"
        case .success: return "Payment was successfull"
        case .failure: return "Payment was not successfull"
        }
    }
}
