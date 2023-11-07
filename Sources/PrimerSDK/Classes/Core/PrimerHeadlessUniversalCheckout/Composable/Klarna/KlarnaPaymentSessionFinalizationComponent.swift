//
//  KlarnaPaymentSessionFinalizationComponent.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 07.11.2023.
//

import Foundation
import PrimerKlarnaSDK

public enum KlarnaPaymentSessionFinalization: PrimerHeadlessStep {
    case paymentSessionFinalized(authToken: String)
    case paymentSessionFinalizationFailed
}

public class KlarnaPaymentSessionFinalizationComponent: PrimerHeadlessComponent {
    // MARK: - Provider
    private weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Set
    func setProvider(provider: PrimerKlarnaProviding?) {
        self.klarnaProvider = provider
        self.klarnaProvider?.finalizationDelegate = self
    }
}

// MARK: - Finalization
public extension KlarnaPaymentSessionFinalizationComponent {
    func finalise(jsonData: String? = nil) {
        klarnaProvider?.finalise(jsonData: jsonData)
    }
}

// MARK: - PrimerKlarnaProviderFinalizationDelegate
extension KlarnaPaymentSessionFinalizationComponent: PrimerKlarnaProviderFinalizationDelegate {
    public func primerKlarnaWrapperFinalized(approved: Bool, authToken: String?) {
        if approved == false {
            let step = KlarnaPaymentSessionFinalization.paymentSessionFinalizationFailed
            self.stepDelegate?.didReceiveStep(step: step)
        }
        
        if let authToken = authToken, approved == true {
            let step = KlarnaPaymentSessionFinalization.paymentSessionFinalized(authToken: authToken)
            self.stepDelegate?.didReceiveStep(step: step)
        }
    }
}
