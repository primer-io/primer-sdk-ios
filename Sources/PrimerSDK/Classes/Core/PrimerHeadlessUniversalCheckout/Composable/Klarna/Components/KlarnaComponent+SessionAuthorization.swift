//
//  KlarnaComponent+Authorization.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

/**
 * Enumerates the possible states and outcomes related to the authorization of a Klarna payment session.
 * This enum is designed to communicate the various stages of authorization (and reauthorization, if necessary) for a Klarna payment session.
 * It conforms to `PrimerHeadlessStep`.
 *
 * - Cases:
 *  - paymentSessionAuthorized: Indicates that the payment session has been successfully authorized. It carries an `authToken` string for subsequent operations that require authorization.
 *  - paymentSessionAuthorizationFailed: Represents a failure in the authorization process.
 *  - paymentSessionFinalizationRequired: Signals that the payment session requires finalization steps to be completed by the user or the system.
 *
 *  - paymentSessionReauthorized: Similar to `paymentSessionAuthorized`.
 *  - paymentSessionReauthorizationFailed: Indicates a failure in the reauthorization process of an existing payment session.
 */
public enum KlarnaSessionAuthorizationStep: PrimerHeadlessStep {
    case paymentSessionAuthorized(authToken: String, checkoutData: PrimerCheckoutData)
    case paymentSessionAuthorizationFailed(error: Error?)
    case paymentSessionFinalizationRequired
    
    case paymentSessionReauthorized(authToken: String, checkoutData: PrimerCheckoutData)
    case paymentSessionReauthorizationFailed(error: Error?)
}

extension KlarnaComponent {
    
    /// Sets Klarna provider authorization delegate
    func setAuthorizationDelegate() {
        klarnaProvider?.authorizationDelegate = self
    }
}

// MARK: - PrimerKlarnaProviderAuthorizationDelegate
extension KlarnaComponent: PrimerKlarnaProviderAuthorizationDelegate {
    
    /**
     * Handles the authorization response from the Primer Klarna Wrapper.
     * This function is called in response to the authorization attempt via the Primer Klarna Wrapper.
     * It processes the result of the authorization attempt, which can lead to various outcomes based on the combination of:
     *  - `approved` - A `Bool` indicating whether the authorization was approved or not.
     *  -  `authToken` - An optional `String` containing the authorization token.  Returned only if `approved` is `true`.
     *  - `finalizeRequired`. - A `Bool` indicating whether additional steps are required to finalize the payment session.
     */
    public func primerKlarnaWrapperAuthorized(approved: Bool, authToken: String?, finalizeRequired: Bool) {
        if approved == false {
            if finalizeRequired == true {
                let step = KlarnaSessionAuthorizationStep.paymentSessionFinalizationRequired
                stepDelegate?.didReceiveStep(step: step)
            } else {
                let step = KlarnaSessionAuthorizationStep.paymentSessionAuthorizationFailed(error: nil)
                stepDelegate?.didReceiveStep(step: step)
            }
        }
        
        if let authToken = authToken, approved == true {
            finalizeSession(token: authToken, fromAuthorization: true)
        }
        
        if finalizeRequired == true {
            let step = KlarnaSessionAuthorizationStep.paymentSessionFinalizationRequired
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
        if approved == false {
            let step = KlarnaSessionAuthorizationStep.paymentSessionReauthorizationFailed(error: nil)
            stepDelegate?.didReceiveStep(step: step)
        }
        
        if let authToken = authToken, approved == true {
            finalizeSession(token: authToken, reauthorization: true, fromAuthorization: true)
        }
    }
}

// MARK: - Authorization / Reauthorize session
extension KlarnaComponent {
    func authorizeSession(autoFinalize: Bool, jsonData: String? = nil) {
        recordAuthorizeEvent(name: KlarnaAnalyticsEvents.AUTHORIZE_SESSION_METHOD, autoFinalize: autoFinalize, jsonData: jsonData)
        klarnaProvider?.authorize(autoFinalize: autoFinalize, jsonData: jsonData)
    }
    
    func reauthorizeSession(jsonData: String? = nil) {
        recordAuthorizeEvent(name: KlarnaAnalyticsEvents.REAUTHORIZE_SESSION_METHOD, jsonData: jsonData)
        klarnaProvider?.reauthorize(jsonData: jsonData)
    }
}

#endif
