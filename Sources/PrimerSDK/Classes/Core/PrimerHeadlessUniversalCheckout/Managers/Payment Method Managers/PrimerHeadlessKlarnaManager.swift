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
        
        // MARK: - Components
        private let sessionCreationComponent: KlarnaPaymentSessionCreationComponent
        private let viewHandlingComponent: KlarnaPaymentViewHandlingComponent
        
        // MARK: - Init
        override init() {
            self.sessionCreationComponent = KlarnaPaymentSessionCreationComponent()
            self.viewHandlingComponent = KlarnaPaymentViewHandlingComponent()
            
            super.init()
        }
        
        // MARK: - Public
        public func provideKlarnaPaymentSessionCreationComponent() -> KlarnaPaymentSessionCreationComponent {
            return self.sessionCreationComponent
        }
        
        public func provideKlarnaPaymentViewHandlingComponent(
            clientToken: String,
            paymentCategory: String,
            urlScheme: String? = nil
        ) -> KlarnaPaymentViewHandlingComponent {
            self.klarnaProvider = PrimerKlarnaProvider(
                clientToken: clientToken,
                paymentCategory: paymentCategory,
                urlScheme: urlScheme
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
    }
    
}
#endif
