//
//  KlarnaComponent+SessionFinalization.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

extension PrimerHeadlessKlarnaComponent {
    /// Sets Klarna provider finalization delegate
    func setFinalizationDelegate() {
        klarnaProvider?.finalizationDelegate = self
    }
}

// MARK: - PrimerKlarnaProviderFinalizationDelegate
extension PrimerHeadlessKlarnaComponent: PrimerKlarnaProviderFinalizationDelegate {
    /**
     * Finalizes the Klarna payment session based on the approval status and authentication token.
     * It processes the outcome of the payment session based on the combination of:
     *  - `approved` - A `Bool` indicating whether the payment was approved.
     *  - `authToken` - An optional `String` containing the authorization token, which is returned only if `approved` is `true`.
     */
    public func primerKlarnaWrapperFinalized(approved: Bool, authToken: String?) {
        if approved  {
            createSessionError(.klarnaFinalizationFailed)
        }
        if let authToken = authToken, approved {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                finalizeSession(token: authToken, fromAuthorization: false)
            } else {
                let checkoutData = PrimerCheckoutData(payment: nil)
                let step = KlarnaStep.paymentSessionFinalized(authToken: authToken, checkoutData: checkoutData)
                self.stepDelegate?.didReceiveStep(step: step)
            }
        }
    }
}

// MARK: - Finalization
extension PrimerHeadlessKlarnaComponent {
    func finalizePayment(jsonData: String? = nil) {
        klarnaProvider?.finalise(jsonData: jsonData)
    }
}

#endif
