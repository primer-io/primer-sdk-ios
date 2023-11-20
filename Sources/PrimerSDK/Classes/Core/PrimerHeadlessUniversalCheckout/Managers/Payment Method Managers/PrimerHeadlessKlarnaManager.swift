//
//  PrimerHeadlessKlarnaManager.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

extension PrimerHeadlessUniversalCheckout {
    
    public class PrimerHeadlessKlarnaManager: NSObject, PrimerKlarnaProviderErrorDelegate {
        // MARK: - Provider
        private var klarnaProvider: PrimerKlarnaProviding?
        
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
            self.sessionCreationComponent = KlarnaPaymentSessionCreationComponent()
            self.viewHandlingComponent = KlarnaPaymentViewHandlingComponent()
            self.sessionAuthorizationComponent = KlarnaPaymentSessionAuthorizationComponent()
            self.sessionFinalizationComponent = KlarnaPaymentSessionFinalizationComponent()
            
            super.init()
        }
        
        // MARK: - Public
        public func provideKlarnaPaymentSessionCreationComponent(type: KlarnaSessionType) -> KlarnaPaymentSessionCreationComponent {
            self.sessionCreationComponent.setSessionType(type: type)
            self.sessionCreationComponent.setSettings(settings: self.settings)
            
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
