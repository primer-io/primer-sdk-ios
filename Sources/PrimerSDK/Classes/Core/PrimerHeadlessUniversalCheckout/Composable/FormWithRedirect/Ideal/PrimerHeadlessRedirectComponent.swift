//
//  PrimerHeadlessRedirectComponent.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 16.11.2023.
//

import Foundation
protocol PrimerHeadlessRedirectComponent {}
class WebRedirectComponent: PrimerHeadlessRedirectComponent {
    let paymentMethodType: PrimerPaymentMethodType
    
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    private let tokenizationModelDelegate: BankSelectorTokenizationDelegate

    init(paymentMethodType: PrimerPaymentMethodType, tokenizationModelDelegate: BankSelectorTokenizationDelegate) {
        self.paymentMethodType = paymentMethodType
        self.tokenizationModelDelegate = tokenizationModelDelegate
        self.stepDelegate = self
        self.errorDelegate = self
    }
}


extension WebRedirectComponent: PrimerHeadlessSteppableDelegate {
    func didReceiveStep(step: PrimerHeadlessStep) {
        guard let step = step as? WebStep else {
            return
        }
        switch step {
        case .loading: break
        case .loaded: break
        case .dismissed: break
        case .success: break
        }
    }
}

extension WebRedirectComponent: PrimerHeadlessErrorableDelegate {
    func didReceiveError(error: PrimerError) {
    }
}

extension WebRedirectComponent {
    var logger: PrimerLogging {
        PrimerLogging.shared
    }
    func trackSubmit() {

    }
}
