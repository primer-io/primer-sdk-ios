//
//  KlarnaComponent+SessionFinalization.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

/**
 * Represents the possible outcomes of a Klarna payment session finalization process.
 *
 * This enum is used to communicate the result of attempting to finalize a payment session with Klarna.
 * It conforms to `PrimerHeadlessStep`.
 *
 * Cases:
 * - paymentSessionFinalized: Indicates a successful finalization of a payment session. It caries:
 *     - `authToken` string, which is used for further API interactions.
 * - paymentSessionFinalizationFailed: Represents a failure in finalizing the process.
 */
public enum KlarnaSessionFinalizationStep: PrimerHeadlessStep {
    case paymentSessionFinalized(authToken: String, checkoutData: PrimerCheckoutData)
    case paymentSessionFinalizationFailed(error: Error?)
}

extension KlarnaComponent {
    
    /// Sets Klarna provider finalization delegate
    func setFinalizationDelegate() {
        klarnaProvider?.finalizationDelegate = self
    }
}

// MARK: - PrimerKlarnaProviderFinalizationDelegate
extension KlarnaComponent: PrimerKlarnaProviderFinalizationDelegate {
    
    /**
     * Finalizes the Klarna payment session based on the approval status and authentication token.
     * It processes the outcome of the payment session based on the combination of:
     *  - `approved` - A `Bool` indicating whether the payment was approved.
     *  - `authToken` - An optional `String` containing the authorization token, which is returned only if `approved` is `true`.
     */
    public func primerKlarnaWrapperFinalized(approved: Bool, authToken: String?) {
        if approved == false {
            let step = KlarnaSessionFinalizationStep.paymentSessionFinalizationFailed(error: nil)
            stepDelegate?.didReceiveStep(step: step)
        }
        
        if let authToken = authToken, approved == true {
            finalizeSession(token: authToken, fromAuthorization: false)
        }
    }
}

// MARK: - Finalization
extension KlarnaComponent {
    public func finalise(jsonData: String? = nil) {
        recordFinalizationEvent(jsonData: jsonData)
        klarnaProvider?.finalise(jsonData: jsonData)
    }
}

#endif
