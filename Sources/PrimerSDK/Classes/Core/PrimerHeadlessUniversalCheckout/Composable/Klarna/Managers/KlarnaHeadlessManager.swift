//
//  KlarnaHeadlessManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.01.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

extension PrimerHeadlessUniversalCheckout {
    
    public class KlarnaHeadlessManager: NSObject, PrimerKlarnaProviderErrorDelegate {
        // MARK: - Provider
        private var klarnaProvider: PrimerKlarnaProviding?
        
        // MARK: - Tokenization
        private var tokenizationComponent: KlarnaTokenizationComponentProtocol?
        
        // MARK: - Settings
        private let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        // MARK: - Delegate
        public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
        
        // MARK: - Components
        var sessionCreationComponent: KlarnaPaymentSessionCreationComponent?
        var sessionAuthorizationComponent: KlarnaPaymentSessionAuthorizationComponent?
        var sessionFinalizationComponent: KlarnaPaymentSessionFinalizationComponent?
        var viewHandlingComponent: KlarnaPaymentViewHandlingComponent?
        
        // MARK: - Init
        public override init() {
            super.init()
            
            guard let tokenizationComponentProtocol = PrimerAPIConfiguration.paymentMethodConfigTokenizationComponent.first else {
                let error = PrimerError.unknown(
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                return
            }
            self.tokenizationComponent = tokenizationComponentProtocol
            
            self.sessionCreationComponent = KlarnaPaymentSessionCreationComponent(
                tokenizationComponent: tokenizationComponentProtocol
            )
            
            self.sessionAuthorizationComponent = KlarnaPaymentSessionAuthorizationComponent(
                tokenizationComponent: tokenizationComponentProtocol
            )
            
            self.sessionFinalizationComponent = KlarnaPaymentSessionFinalizationComponent(
                tokenizationComponent: tokenizationComponentProtocol
            )
            self.viewHandlingComponent = KlarnaPaymentViewHandlingComponent()
        }
        
        public func setDelegate(_ delegate: PrimerHeadlessKlarnaComponent) {
            errorDelegate = delegate
            validate()
        }
        
        // MARK: - Session creation public methods
        public func setSessionCreationDelegates(_ delegate: PrimerHeadlessKlarnaComponent) {
            sessionCreationComponent?.validationDelegate = delegate
            sessionCreationComponent?.errorDelegate = delegate
            sessionCreationComponent?.stepDelegate = delegate
        }
        
        public func startSession() {
            sessionCreationComponent?.start()
            validate()
        }
        
        public func updateSessionCollectedData(collectableData: KlarnaPaymentSessionCollectableData) {
            sessionCreationComponent?.updateCollectedData(collectableData: collectableData)
        }
        
        // MARK: - Session authorization public methods
        public func setSessionAuthorizationDelegate(_ delegate: PrimerHeadlessKlarnaComponent) {
            sessionAuthorizationComponent?.setProvider(provider: klarnaProvider)
            sessionAuthorizationComponent?.stepDelegate = delegate
        }
        
        public func authorizeSession(autoFinalize: Bool, jsonData: String? = nil) {
            sessionAuthorizationComponent?.authorizeSession(autoFinalize: autoFinalize)
        }
        
        // MARK: - Session finalization public methods
        public func setSessionFinalizationDelegate(_ delegate: PrimerHeadlessKlarnaComponent) {
            sessionFinalizationComponent?.setProvider(provider: klarnaProvider)
            sessionFinalizationComponent?.stepDelegate = delegate
        }
        
        public func finalizeSession() {
            sessionFinalizationComponent?.finalise()
        }
        
        // MARK: - Klarna PaymentView handling methods
        public func setProvider(with clientToken: String, paymentCategory: String) {
            klarnaProvider = PrimerKlarnaProvider(clientToken: clientToken, paymentCategory: paymentCategory, urlScheme: settings.paymentMethodOptions.urlScheme)
            
            viewHandlingComponent?.setProvider(provider: klarnaProvider)
        }
        
        public func setViewHandlingDelegate(_ delegate: PrimerHeadlessKlarnaComponent) {
            viewHandlingComponent?.stepDelegate = delegate
        }
        
        public func createPaymentView() -> UIView? {
            viewHandlingComponent?.createPaymentView()
        }
        
        public func initPaymentView() {
            viewHandlingComponent?.initPaymentView()
        }
        
        public func loadPaymentView(jsonData: String? = nil) {
            viewHandlingComponent?.loadPaymentView(jsonData: jsonData)
        }
        
        public func validate() {
            handleValidation()
        }
        
        // MARK: - PrimerKlarnaProviderErrorDelegate
        public func primerKlarnaWrapperFailed(with error: PrimerKlarnaSDK.PrimerKlarnaError) {
            let primerError = PrimerError.klarnaWrapperError(
                message: error.errorDescription,
                userInfo: error.info,
                diagnosticsId: error.diagnosticsId
            )
            errorDelegate?.didReceiveError(error: primerError)
        }
        
        // MARK: - Handle errors from validate method
        private func handleValidation() {
            do {
                try tokenizationComponent?.validate()
            } catch {
                if let err = error as? PrimerError {
                    errorDelegate?.didReceiveError(error: err)
                }
            }
        }
    }
    
}
#endif
