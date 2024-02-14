//
//  KlarnaPaymentSessionAuthorizationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
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
public enum KlarnaPaymentSessionAuthorization: PrimerHeadlessStep {
    case paymentSessionAuthorized(authToken: String)
    case paymentSessionAuthorizationFailed
    case paymentSessionFinalizationRequired
    
    case paymentSessionReauthorized(authToken: String)
    case paymentSessionReauthorizationFailed
}

public class KlarnaPaymentSessionAuthorizationComponent: PrimerHeadlessAnalyticsRecordable {
    // MARK: - Tokenization
    private var tokenizationComponent: KlarnaTokenizationComponentProtocol
    
    // MARK: - Provider
    private(set) weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Init
    init(tokenizationComponent: KlarnaTokenizationComponentProtocol) {
        self.tokenizationComponent = tokenizationComponent
    }
    
    // MARK: - Set Klarna provider
    func setProvider(provider: PrimerKlarnaProviding?) {
        klarnaProvider = provider
        klarnaProvider?.authorizationDelegate = self
    }
}

// MARK: - Authorization / Reauthorize session
public extension KlarnaPaymentSessionAuthorizationComponent {
    func authorizeSession(autoFinalize: Bool = true) {
        var extraMerchantDataString: String?
        
        if let paymentMethod = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.type == PrimerPaymentMethodType.klarna.rawValue }) {
            if let merchantOptions = paymentMethod.options as? MerchantOptions {
                if let extraMerchantData = merchantOptions.extraMerchantData?.jsonString {
                    extraMerchantDataString = KlarnaHelpers.getSerializedAttachmentString(from: extraMerchantData)
                }
            }
        }
        
        recordAuthorizeEvent(name: KlarnaAnalyticsEvents.AUTHORIZE_SESSION_METHOD, autoFinalize: autoFinalize, jsonData: extraMerchantDataString)
        klarnaProvider?.authorize(autoFinalize: autoFinalize, jsonData: extraMerchantDataString)
    }
    
    func reauthorizeSession(jsonData: String? = nil) {
        recordAuthorizeEvent(name: KlarnaAnalyticsEvents.REAUTHORIZE_SESSION_METHOD, jsonData: jsonData)
        klarnaProvider?.reauthorize(jsonData: jsonData)
    }
}

// MARK: - Finalize session
private extension KlarnaPaymentSessionAuthorizationComponent {
    
    /**
     * Finalizes the payment session with specific authorization and tokenization processes.
     *
     * - Parameters:
     *   - token: A `String` representing the authorization token used for payment session authorization.
     *            This token is necessary for both the initial authorization request and the tokenization process that follows.
     *   - reauthorization: A `Bool` indicating whether the current operation is a reauthorization.
     *
     * This method first attempts to authorize the payment session using the provided `token`.
     * Upon successful authorization, it proceeds to tokenize the customer token received in response.
     * Based on the `reauthorization` flag, it then determines the correct step to proceed with.
     */
    func finalizeSession(token: String, reauthorization: Bool) {
        firstly {
            tokenizationComponent.authorizePaymentSession(authorizationToken: token)
        }
        .then { customerToken in
            self.tokenizationComponent.tokenize(customerToken: customerToken, offSessionAuthorizationId: token)
        }
        .done { _ in
            var step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorized(authToken: token)
            if reauthorization {
                step = KlarnaPaymentSessionAuthorization.paymentSessionReauthorized(authToken: token)
            }
            self.stepDelegate?.didReceiveStep(step: step)
        }
        .catch { _ in
            let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorizationFailed
            self.stepDelegate?.didReceiveStep(step: step)
        }
    }
}

// MARK: - PrimerKlarnaProviderAuthorizationDelegate
extension KlarnaPaymentSessionAuthorizationComponent: PrimerKlarnaProviderAuthorizationDelegate {
    
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
                let step = KlarnaPaymentSessionAuthorization.paymentSessionFinalizationRequired
                stepDelegate?.didReceiveStep(step: step)
            } else {
                let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorizationFailed
                stepDelegate?.didReceiveStep(step: step)
            }
        }
        
        if let authToken = authToken, approved == true {
            finalizeSession(token: authToken, reauthorization: false)
        }
        
        if finalizeRequired == true {
            let step = KlarnaPaymentSessionAuthorization.paymentSessionFinalizationRequired
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
            let step = KlarnaPaymentSessionAuthorization.paymentSessionReauthorizationFailed
            stepDelegate?.didReceiveStep(step: step)
        }
        
        if let authToken = authToken, approved == true {
            finalizeSession(token: authToken, reauthorization: true)
        }
    }
}

// MARK: - Helpers
private extension KlarnaPaymentSessionAuthorizationComponent {
    private func recordAuthorizeEvent(name: String, autoFinalize: Bool? = nil, jsonData: String?) {
        var params = [
            KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
            KlarnaAnalyticsEvents.JSON_DATA_KEY: jsonData ?? KlarnaAnalyticsEvents.JSON_DATA_DEFAULT_VALUE
        ]
        
        if let autoFinalize {
            params[KlarnaAnalyticsEvents.AUTO_FINALIZE_KEY] = "\(autoFinalize)"
        }
        
        recordEvent(
            type: .sdkEvent,
            name: name,
            params: params
        )
    }
}
#endif
