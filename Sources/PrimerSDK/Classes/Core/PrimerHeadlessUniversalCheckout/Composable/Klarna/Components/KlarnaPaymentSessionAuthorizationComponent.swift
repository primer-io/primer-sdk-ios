//
//  KlarnaPaymentSessionAuthorizationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

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
    
    // MARK: - Set
    func setProvider(provider: PrimerKlarnaProviding?) {
        self.klarnaProvider = provider
        self.klarnaProvider?.authorizationDelegate = self
    }
}

// MARK: - Authorization
public extension KlarnaPaymentSessionAuthorizationComponent {
    func authorizeSession(autoFinalize: Bool = true, jsonData: String? = nil) {
        recordAuthorizeEvent(name: KlarnaAnalyticsEvents.AUTHORIZE_SESSION_METHOD, autoFinalize: autoFinalize, jsonData: jsonData)
        self.klarnaProvider?.authorize(autoFinalize: autoFinalize, jsonData: jsonData)
    }
    
    func reauthorizeSession(jsonData: String? = nil) {
        recordAuthorizeEvent(name: KlarnaAnalyticsEvents.REAUTHORIZE_SESSION_METHOD, jsonData: jsonData)
        self.klarnaProvider?.reauthorize(jsonData: jsonData)
    }
}

// MARK: - Private
private extension KlarnaPaymentSessionAuthorizationComponent {
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
    public func primerKlarnaWrapperAuthorized(
        approved: Bool,
        authToken: String?,
        finalizeRequired: Bool
    ) {
        if approved == false {
            if finalizeRequired == true {
                let step = KlarnaPaymentSessionAuthorization.paymentSessionFinalizationRequired
                self.stepDelegate?.didReceiveStep(step: step)
            } else {
                let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorizationFailed
                self.stepDelegate?.didReceiveStep(step: step)
            }
        }
        
        if let authToken = authToken, approved == true {
            self.finalizeSession(token: authToken, reauthorization: false)
        }
        
        if finalizeRequired == true {
            let step = KlarnaPaymentSessionAuthorization.paymentSessionFinalizationRequired
            self.stepDelegate?.didReceiveStep(step: step)
        }
    }
    
    public func primerKlarnaWrapperReauthorized(approved: Bool, authToken: String?) {
        if approved == false {
            let step = KlarnaPaymentSessionAuthorization.paymentSessionReauthorizationFailed
            self.stepDelegate?.didReceiveStep(step: step)
        }
        
        if let authToken = authToken, approved == true {
            self.finalizeSession(token: authToken, reauthorization: true)
        }
    }
}
#endif

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
