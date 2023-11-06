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
    
    public class PrimerHeadlessKlarnaManager: NSObject {
        // MARK: - Properties
        private var clientToken: String?
        
        // MARK: - Provider
        
        // MARK: - Components
        private let sessionCreationComponent: KlarnaPaymentSessionCreationComponent
        
        // MARK: - Init
        override init() {
            self.sessionCreationComponent = KlarnaPaymentSessionCreationComponent()
            
            super.init()
        }
        
        // MARK: - Public
        public func provideKlarnaPaymentSessionCreationComponent() -> KlarnaPaymentSessionCreationComponent {
            return self.sessionCreationComponent
        }
    }
    
}
#endif
