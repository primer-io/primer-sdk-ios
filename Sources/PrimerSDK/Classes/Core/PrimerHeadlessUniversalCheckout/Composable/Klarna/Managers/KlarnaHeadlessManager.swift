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
        let sessionCreationComponent: KlarnaPaymentSessionCreationComponent
        let sessionAuthorizationComponent: KlarnaPaymentSessionAuthorizationComponent
        let sessionFinalizationComponent: KlarnaPaymentSessionFinalizationComponent
        let viewHandlingComponent: KlarnaPaymentViewHandlingComponent
        
        // MARK: - Init
        public override init() {
            self.tokenizationComponent = PrimerAPIConfiguration.paymentMethodConfigTokenizationComponent.first
            
            self.sessionCreationComponent = KlarnaPaymentSessionCreationComponent(
                tokenizationManager: self.tokenizationComponent
            )
            
            self.sessionAuthorizationComponent = KlarnaPaymentSessionAuthorizationComponent(
                tokenizationManager: self.tokenizationComponent
            )
            
            self.sessionFinalizationComponent = KlarnaPaymentSessionFinalizationComponent(
                tokenizationManager: self.tokenizationComponent
            )
            self.viewHandlingComponent = KlarnaPaymentViewHandlingComponent()
            
            super.init()
            self.handleValidate()
        }
        
        // MARK: - Public
        public func provideKlarnaPaymentSessionCreationComponent() -> KlarnaPaymentSessionCreationComponent {
            return self.sessionCreationComponent
        }
        
        public func provideKlarnaPaymentSessionAuthorizationComponent() -> KlarnaPaymentSessionAuthorizationComponent {
            self.sessionAuthorizationComponent.setProvider(provider: self.klarnaProvider)
            
            return self.sessionAuthorizationComponent
        }
        
        public func provideKlarnaPaymentSessionFinalizationComponent() -> KlarnaPaymentSessionFinalizationComponent {
            self.sessionFinalizationComponent.setProvider(provider: self.klarnaProvider)
            
            return self.sessionFinalizationComponent
        }
        
        public func provideKlarnaPaymentViewHandlingComponent(
            clientToken: String,
            paymentCategory: String
        ) -> KlarnaPaymentViewHandlingComponent {
            self.klarnaProvider = PrimerKlarnaProvider(
                clientToken: clientToken,
                paymentCategory: paymentCategory,
                urlScheme: self.settings.paymentMethodOptions.urlScheme
            )
            
            self.viewHandlingComponent.setProvider(provider: self.klarnaProvider)
            
            return self.viewHandlingComponent
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
        private func handleValidate() {
            do {
                try tokenizationComponent?.validate()
            } catch {
                if let err = error as? PrimerError {
                    PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: nil)
                }
            }
        }
    }
    
}
#endif
