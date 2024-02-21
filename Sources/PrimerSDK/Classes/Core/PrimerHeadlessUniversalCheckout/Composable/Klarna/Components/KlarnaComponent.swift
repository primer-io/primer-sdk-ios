//
//  KlarnaComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

public class KlarnaComponent {
    
    // MARK: - Tokenization
    var tokenizationComponent: KlarnaTokenizationComponentProtocol
    
    // MARK: - Provider
    weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    
    // MARK: - Init
    init(tokenizationComponent: KlarnaTokenizationComponentProtocol) {
        self.tokenizationComponent = tokenizationComponent
    }
    
    // MARK: - Set Klarna provider
    func setProvider(provider: PrimerKlarnaProviding?) {
        klarnaProvider = provider
    }
}

// MARK: - Finalize payment session and Tokenization process
extension KlarnaComponent {
    
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
    func finalizeSession(token: String, reauthorization: Bool = false, fromAuthorization: Bool) {
        firstly {
            tokenizationComponent.authorizePaymentSession(authorizationToken: token)
        }
        .then { customerToken in
            self.tokenizationComponent.tokenize(customerToken: customerToken, offSessionAuthorizationId: token)
        }
        .done { checkoutData in
            if fromAuthorization {
                let step = reauthorization ?
                KlarnaSessionAuthorizationStep.paymentSessionReauthorized(authToken: token, checkoutData: checkoutData) :
                KlarnaSessionAuthorizationStep.paymentSessionAuthorized(authToken: token, checkoutData: checkoutData)
                
                self.stepDelegate?.didReceiveStep(step: step)
            } else {
                // Finalization
                let step = KlarnaSessionFinalizationStep.paymentSessionFinalized(authToken: token, checkoutData: checkoutData)
                self.stepDelegate?.didReceiveStep(step: step)
            }
        }
        .catch { error in
            if fromAuthorization {
                let step = KlarnaSessionAuthorizationStep.paymentSessionAuthorizationFailed(error: error)
                self.stepDelegate?.didReceiveStep(step: step)
            } else {
                // Finalization
                let step = KlarnaSessionFinalizationStep.paymentSessionFinalizationFailed(error: error)
                self.stepDelegate?.didReceiveStep(step: step)
            }
        }
    }
    
}

// MARK: Recording Analytics
extension KlarnaComponent: PrimerHeadlessAnalyticsRecordable {
    func recordCreationEvent() {
        recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.CREATE_SESSION_START_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
            ]
        )
    }
    
    func recordAuthorizeEvent(name: String, autoFinalize: Bool? = nil, jsonData: String?) {
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
    
    func recordFinalizationEvent(jsonData: String?) {
        recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.FINALIZE_SESSION_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
                KlarnaAnalyticsEvents.JSON_DATA_KEY: jsonData ?? KlarnaAnalyticsEvents.JSON_DATA_DEFAULT_VALUE
            ]
        )
    }
    
    func recordPaymentViewEvent(name: String, jsonData: String? = nil) {
        var params = [KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE]
        
        if let jsonData {
            params[KlarnaAnalyticsEvents.JSON_DATA_KEY] = jsonData
        }
        
        recordEvent(
            type: .sdkEvent,
            name: name,
            params: params
        )
    }
}
#endif
