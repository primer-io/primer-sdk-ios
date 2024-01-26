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
        
        // MARK: - Delegate
        public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
        
        // MARK: - Settings
        private let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        // MARK: - Components
        let sessionCreationComponent: KlarnaPaymentSessionCreationComponent
        let viewHandlingComponent: KlarnaPaymentViewHandlingComponent
        let sessionAuthorizationComponent: KlarnaPaymentSessionAuthorizationComponent
        let sessionFinalizationComponent: KlarnaPaymentSessionFinalizationComponent
        
        // MARK: - Init
        public override init() {
            self.tokenizationComponent = PrimerAPIConfiguration.paymentMethodConfigTokenizationManagers.first(where: {
                $0 is KlarnaTokenizationComponentProtocol
            }) as? KlarnaTokenizationComponentProtocol
            
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
        }
        
        // MARK: - Public
        public func provideKlarnaPaymentSessionCreationComponent() -> KlarnaPaymentSessionCreationComponent {
            return self.sessionCreationComponent
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
        
        public func provideKlarnaPaymentSessionAuthorizationComponent() -> KlarnaPaymentSessionAuthorizationComponent {
            self.sessionAuthorizationComponent.setProvider(provider: self.klarnaProvider)
            
            return self.sessionAuthorizationComponent
        }
        
        public func provideKlarnaPaymentSessionFinalizationComponent() -> KlarnaPaymentSessionFinalizationComponent {
            self.sessionFinalizationComponent.setProvider(provider: self.klarnaProvider)
            
            return self.sessionFinalizationComponent
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
    }
    
}
#endif
