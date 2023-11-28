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
    
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    private var tokenizationModelDelegate: WebRedirectTokenizationDelegate
    private(set) var step: WebStep = .loading

    init(paymentMethodType: PrimerPaymentMethodType, tokenizationModelDelegate: WebRedirectTokenizationDelegate) {
        self.paymentMethodType = paymentMethodType
        self.tokenizationModelDelegate = tokenizationModelDelegate
        self.stepDelegate = self
        self.tokenizationModelDelegate.didPresentPaymentMethodUI = {
            self.step = .loaded
            self.stepDelegate?.didReceiveStep(step: self.step)
        }
        self.tokenizationModelDelegate.didDismissPaymentMethodUI = {
            self.step = .dismissed
            self.stepDelegate?.didReceiveStep(step: self.step)
        }
        self.tokenizationModelDelegate.didFinishPayment = { error in
            self.step = error == nil ? .success : .failure
            self.stepDelegate?.didReceiveStep(step: self.step)
            self.tokenizationModelDelegate.cleanup()
        }
    }

    func start() {
        step = .loading
        self.stepDelegate?.didReceiveStep(step: self.step)
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

extension WebRedirectComponent: LogReporter {
    func logStep() {
        let logMessage = "\(step.logMessage) (\(paymentMethodType.rawValue))"
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
