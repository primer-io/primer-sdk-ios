//
//  KlarnaPaymentSessionAuthorizationComponent.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
//

import Foundation
import PrimerKlarnaSDK

public enum KlarnaPaymentSessionAuthorization: PrimerHeadlessStep {
    case paymentSessionAuthorized(approved: Bool, authToken: String?, finalizeRequired: Bool)
    case paymentSessionReauthorized(approved: Bool, authToken: String?)
}

public class KlarnaPaymentSessionAuthorizationComponent: PrimerHeadlessComponent {
    // MARK: - Provider
    private weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
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
        klarnaProvider?.authorize(autoFinalize: autoFinalize, jsonData: jsonData)
    }
    
    func reauthorizeSession(jsonData: String? = nil) {
        klarnaProvider?.reauthorize(jsonData: jsonData)
    }
}

// MARK: - PrimerKlarnaProviderAuthorizationDelegate
extension KlarnaPaymentSessionAuthorizationComponent: PrimerKlarnaProviderAuthorizationDelegate {
    public func primerKlarnaWrapperAuthorized(
        approved: Bool,
        authToken: String?,
        finalizeRequired: Bool
    ) {
        let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorized(
            approved: approved,
            authToken: authToken,
            finalizeRequired: finalizeRequired
        )
        self.stepDelegate?.didReceiveStep(step: step)
    }
    
    public func primerKlarnaWrapperReauthorized(approved: Bool, authToken: String?) {
        let step = KlarnaPaymentSessionAuthorization.paymentSessionReauthorized(
            approved: approved,
            authToken: authToken
        )
        self.stepDelegate?.didReceiveStep(step: step)
    }
}
