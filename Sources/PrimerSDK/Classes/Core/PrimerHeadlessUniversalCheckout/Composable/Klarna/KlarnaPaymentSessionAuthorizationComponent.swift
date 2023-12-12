//
//  KlarnaPaymentSessionAuthorizationComponent.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

public enum KlarnaPaymentSessionAuthorization: PrimerHeadlessStep {
    case paymentSessionAuthorized(tokenData: PrimerPaymentMethodTokenData)
    case paymentSessionAuthorizationFailed
    case paymentSessionFinalizationRequired
    
    case paymentSessionReauthorized(tokenData: PrimerPaymentMethodTokenData)
    case paymentSessionReauthorizationFailed
}

public class KlarnaPaymentSessionAuthorizationComponent: PrimerHeadlessComponent, PrimerHeadlessAnalyticsRecordable {
    // MARK: - Tokenization
    private let tokenizationManager: KlarnaTokenizationManagerProtocol?
    
    // MARK: - Provider
    private(set) weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Init
    init(tokenizationManager: KlarnaTokenizationManagerProtocol?) {
        self.tokenizationManager = tokenizationManager
    }
    
    // MARK: - Set
    func setProvider(provider: PrimerKlarnaProviding?) {
        self.klarnaProvider = provider
        self.klarnaProvider?.authorizationDelegate = self
    }
}

// MARK: - Authorization
public extension KlarnaPaymentSessionAuthorizationComponent {
    func authorizeSession(
        autoFinalize: Bool = true,
        jsonData: String? = nil
    ) {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.AUTHORIZE_SESSION_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
                KlarnaAnalyticsEvents.AUTO_FINALIZE_KEY: "\(autoFinalize)",
                KlarnaAnalyticsEvents.JSON_DATA_KEY: jsonData ?? KlarnaAnalyticsEvents.JSON_DATA_DEFAULT_VALUE
            ]
        )
        
        self.klarnaProvider?.authorize(autoFinalize: autoFinalize, jsonData: jsonData)
    }
    
    func reauthorizeSession(jsonData: String? = nil) {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.REAUTHORIZE_SESSION_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
                KlarnaAnalyticsEvents.JSON_DATA_KEY: jsonData ?? KlarnaAnalyticsEvents.JSON_DATA_DEFAULT_VALUE
            ]
        )
        
        self.klarnaProvider?.reauthorize(jsonData: jsonData)
    }
}

// MARK: - Private
private extension KlarnaPaymentSessionAuthorizationComponent {
    func finalizeSession(token: String, reauthorization: Bool) {
        self.tokenizationManager?.authorizePaymentSession(authorizationToken: token) { [weak self] (result) in
            switch result {
            case .success(let success):
                self?.tokenizationManager?.tokenize(customerToken: success) { (result) in
                    switch result {
                    case .success(let success):
                        var step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorized(tokenData: success)
                        if reauthorization {
                            step = KlarnaPaymentSessionAuthorization.paymentSessionReauthorized(tokenData: success)
                        }
                        self?.stepDelegate?.didReceiveStep(step: step)
                        
                    case .failure:
                        let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorizationFailed
                        self?.stepDelegate?.didReceiveStep(step: step)
                    }
                }
                
            case .failure:
                let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorizationFailed
                self?.stepDelegate?.didReceiveStep(step: step)
            }
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
