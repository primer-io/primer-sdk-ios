//
//  KlarnaComponent+Authorization.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

extension PrimerHeadlessKlarnaComponent {
    /// Sets Klarna provider authorization delegate
    func setAuthorizationDelegate() {
        klarnaProvider?.authorizationDelegate = self
    }
}

// MARK: - Session authorization
extension PrimerHeadlessKlarnaComponent {
    func authorizeSession() {
        var isMocked = false
#if DEBUG
        if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
            isMocked = true
        }
#endif
        if isMocked {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.finalizeSession(token: UUID().uuidString, fromAuthorization: true)
            }
        } else {
            var extraMerchantDataString: String?
            if let paymentMethod = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.type == PrimerPaymentMethodType.klarna.rawValue }) {
                if let merchantOptions = paymentMethod.options as? MerchantOptions {
                    if let extraMerchantData = merchantOptions.extraMerchantData {
                        extraMerchantDataString = KlarnaHelpers.getSerializedAttachmentString(from: extraMerchantData)
                    }
                }
            }
            let autoFinalize = PrimerInternal.shared.sdkIntegrationType != .headless
            klarnaProvider?.authorize(autoFinalize: autoFinalize, jsonData: extraMerchantDataString)
        }
    }
}

// MARK: - PrimerKlarnaProviderAuthorizationDelegate
extension PrimerHeadlessKlarnaComponent: PrimerKlarnaProviderAuthorizationDelegate {
    /**
     * Handles the authorization response from the Primer Klarna Wrapper.
     * This function is called in response to the authorization attempt via the Primer Klarna Wrapper.
     * It processes the result of the authorization attempt, which can lead to various outcomes based on the combination of:
     *  - `approved` - A `Bool` indicating whether the authorization was approved or not.
     *  -  `authToken` - An optional `String` containing the authorization token.  Returned only if `approved` is `true`.
     *  - `finalizeRequired`. - A `Bool` indicating whether additional steps are required to finalize the payment session.
     */
    public func primerKlarnaWrapperAuthorized(approved: Bool, authToken: String?, finalizeRequired: Bool) {
        isFinalizationRequired = finalizeRequired
        if approved == false {
            if finalizeRequired == true {
                let step = KlarnaStep.paymentSessionFinalizationRequired
                stepDelegate?.didReceiveStep(step: step)
            } else {
                createSessionError(.klarnaAuthorizationFailed)
            }
        }
        if let authToken = authToken, approved == true {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                finalizeSession(token: authToken, fromAuthorization: true)
            } else {
                let checkoutData = PrimerCheckoutData(payment: nil)
                let step = KlarnaStep.paymentSessionAuthorized(authToken: authToken, checkoutData: checkoutData)
                self.stepDelegate?.didReceiveStep(step: step)
            }
        }
        if finalizeRequired == true {
            let step = KlarnaStep.paymentSessionFinalizationRequired
            stepDelegate?.didReceiveStep(step: step)
        }
    }
    /**
     * Handles the re-authorization response from the Primer Klarna Wrapper.
     * It processes the result of the re-authorization attempt, which can lead to various outcomes based on the combination of:
     *  - `approved` - A `Bool` indicating whether the authorization was approved or not.
     *  -  `authToken` - An optional `String` containing the authorization token.  Returned only if `approved` is `true`.
     */
    public func primerKlarnaWrapperReauthorized(approved: Bool, authToken: String?) {
        // no-op
    }
}

#endif
