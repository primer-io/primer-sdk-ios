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
    case paymentSessionAuthorized(authToken: String)
    case paymentSessionAuthorizationFailed
    case paymentSessionFinalizationRequired
    
    case paymentSessionReauthorized(authToken: String)
    case paymentSessionReauthorizationFailed
}

public class KlarnaPaymentSessionAuthorizationComponent: PrimerHeadlessComponent, PrimerHeadlessAnalyticsRecordable {
    // MARK: - ViewModel
    private let tokenizationViewModel: KlarnaHeadlessTokenizationViewModel
    
    // MARK: - Provider
    private(set) weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Init
    init(tokenizationViewModel: KlarnaHeadlessTokenizationViewModel) {
        self.tokenizationViewModel = tokenizationViewModel
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

// MARK: - Handlers
private extension KlarnaPaymentSessionAuthorizationComponent {
    func handleError() {
        let error = PrimerError.klarnaWrapperError(
            message: "Auhtorization failed",
            userInfo: [
                "file": #file,
                "class": "\(Self.self)",
                "function": #function,
                "line": "\(#line)"
            ],
            diagnosticsId: UUID().uuidString
        )
        
        self.tokenizationViewModel.klarnaPaymentSessionCompleted?(nil, error)
    }
    
    func handleSuccess(authToken: String) {
        self.tokenizationViewModel.klarnaPaymentSessionCompleted?(authToken, nil)
    }
    
    func handleFinalization() {
        self.tokenizationViewModel.klarnaPaymentSessionCompleted?(nil, nil)
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
                       
                self.handleFinalization()
                
                self.stepDelegate?.didReceiveStep(step: step)
            } else {
                let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorizationFailed
                
                self.handleError()
                
                self.stepDelegate?.didReceiveStep(step: step)
            }
        }
        
        if let authToken = authToken, approved == true {
            let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorized(authToken: authToken)
            
            self.handleSuccess(authToken: authToken)
            
            self.stepDelegate?.didReceiveStep(step: step)
        }
        
        if finalizeRequired == true {
            let step = KlarnaPaymentSessionAuthorization.paymentSessionFinalizationRequired
            
            self.handleFinalization()
            
            self.stepDelegate?.didReceiveStep(step: step)
        }
    }
    
    public func primerKlarnaWrapperReauthorized(approved: Bool, authToken: String?) {
        if approved == false {
            let step = KlarnaPaymentSessionAuthorization.paymentSessionReauthorizationFailed
            
            handleError()
            
            self.stepDelegate?.didReceiveStep(step: step)
        }
        
        if let authToken = authToken, approved == true {
            let step = KlarnaPaymentSessionAuthorization.paymentSessionReauthorized(authToken: authToken)
            self.stepDelegate?.didReceiveStep(step: step)
        }
    }
}
#endif
