//
//  KlarnaPaymentSessionFinalizationComponent.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 07.11.2023.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

public enum KlarnaPaymentSessionFinalization: PrimerHeadlessStep {
    case paymentSessionFinalized(authToken: String)
    case paymentSessionFinalizationFailed
}

public class KlarnaPaymentSessionFinalizationComponent: PrimerHeadlessComponent, PrimerHeadlessAnalyticsRecordable {
    // MARK: - ViewModel
    private var tokenizationViewModel: KlarnaHeadlessTokenizationViewModel?
    
    // MARK: - Provider
    private(set) weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Set
    func setProvider(provider: PrimerKlarnaProviding?) {
        self.klarnaProvider = provider
        self.klarnaProvider?.finalizationDelegate = self
    }
    
    // MARK: - Init
    init() {
        self.tokenizationViewModel = self.getViewModel(
            with: "KLARNA",
            viewModelType: KlarnaHeadlessTokenizationViewModel.self
        )
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
    func handleError() {
        let error = PrimerError.klarnaWrapperError(
            message: "Finalization failed",
            userInfo: [
                "file": #file,
                "class": "\(Self.self)",
                "function": #function,
                "line": "\(#line)"
            ],
            diagnosticsId: UUID().uuidString
        )
        
        self.tokenizationViewModel?.klarnaPaymentSessionFinalized?(nil, error)
    }
    
    func handleSuccess(authToken: String) {
        self.tokenizationViewModel?.klarnaPaymentSessionFinalized?(authToken, nil)
    }
}

// MARK: - PrimerKlarnaProviderFinalizationDelegate
extension KlarnaPaymentSessionFinalizationComponent: PrimerKlarnaProviderFinalizationDelegate {
    public func primerKlarnaWrapperFinalized(approved: Bool, authToken: String?) {
        if approved == false {
            let step = KlarnaPaymentSessionFinalization.paymentSessionFinalizationFailed
            
            self.handleError()
            
            self.stepDelegate?.didReceiveStep(step: step)
        }
        
        if let authToken = authToken, approved == true {
            let step = KlarnaPaymentSessionFinalization.paymentSessionFinalized(authToken: authToken)
            
            self.handleSuccess(authToken: authToken)
            
            self.stepDelegate?.didReceiveStep(step: step)
        }
    }
}
#endif
