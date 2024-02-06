//
//  KlarnaPaymentSessionFinalizationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

public enum KlarnaPaymentSessionFinalization: PrimerHeadlessStep {
    case paymentSessionFinalized(authToken: String)
    case paymentSessionFinalizationFailed
}

public class KlarnaPaymentSessionFinalizationComponent: PrimerHeadlessAnalyticsRecordable {
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
        self.klarnaProvider?.finalizationDelegate = self
    }
}

// MARK: - Finalization
public extension KlarnaPaymentSessionFinalizationComponent {
    func finalise(jsonData: String? = nil) {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.FINALIZE_SESSION_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
                KlarnaAnalyticsEvents.JSON_DATA_KEY: jsonData ?? KlarnaAnalyticsEvents.JSON_DATA_DEFAULT_VALUE
            ]
        )
        
        self.klarnaProvider?.finalise(jsonData: jsonData)
    }
}

// MARK: - Handlers
private extension KlarnaPaymentSessionFinalizationComponent {
    func finalizeSession(token: String) {
        firstly {
            tokenizationComponent.authorizePaymentSession(authorizationToken: token)
        }
        .then { customerToken in
            self.tokenizationComponent.tokenize(customerToken: customerToken, offSessionAuthorizationId: token)
        }
        .done { _ in
            let step = KlarnaPaymentSessionFinalization.paymentSessionFinalized(authToken: token)
            self.stepDelegate?.didReceiveStep(step: step)
        }
        .catch { _ in
            let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorizationFailed
            self.stepDelegate?.didReceiveStep(step: step)
        }
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
            self.finalizeSession(token: authToken)
        }
    }
}
#endif

