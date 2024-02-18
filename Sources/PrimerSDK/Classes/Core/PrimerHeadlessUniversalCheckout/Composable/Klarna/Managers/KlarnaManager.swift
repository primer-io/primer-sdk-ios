//
//  KlarnaManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 17.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import UIKit
import PrimerKlarnaSDK

extension PrimerHeadlessUniversalCheckout {
    
    public class KlarnaManager: NSObject, PrimerKlarnaProviderErrorDelegate {
        
        // MARK: - Klarna properties
        
        /// Component responsible for managing session creation stages of the Klarna payment session.
        var klarnaComponent: KlarnaComponent?
        
        /// A component that handles the tokenization process required for Klarna payments.
        private var tokenizationComponent: KlarnaTokenizationComponentProtocol?
        
        /// Responsible for performing operations related to Klarna's payment process.
        private var klarnaProvider: PrimerKlarnaProviding?
        
        // MARK: - Manager properties
        
        /// A delegate to handle errors that may occur during the payment process, involving KlarnaHeadlessManager logic.
        public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
        
        /// Global settings for the payment process, injected as a dependency.
        private let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        // MARK: - Init
        public init(paymentMethodType: String, intent: PrimerSessionIntent) {
            super.init()
            
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?.first(where: { $0.type == paymentMethodType }) else {
                let err = PrimerError.generic(message: "Unable to locate a valid payment method component",
                                              userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                              diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                return
            }
            
            if (intent == .vault && !paymentMethod.isVaultingEnabled) ||
                (intent == .checkout && !paymentMethod.isCheckoutEnabled) {
                let err = PrimerError.unsupportedIntent(intent: intent,
                                                        userInfo: ["file": #file,
                                                                   "class": "\(Self.self)",
                                                                   "function": #function,
                                                                   "line": "\(#line)"],
                                                        diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                return
            }
            
            PrimerInternal.shared.intent = intent
            
            let tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
            self.tokenizationComponent = tokenizationComponent
            
            self.klarnaComponent = KlarnaComponent(tokenizationComponent: tokenizationComponent)
        }
        
        // MARK: - Session creation public methods
        
        /// Configures delegates for the session creation component to handle validation, errors, and steps in the payment process.
        public func setKlarnaDelegates(_ delegate: PrimerHeadlessKlarnaComponent) {
            klarnaComponent?.validationDelegate = delegate
            klarnaComponent?.errorDelegate = delegate
            klarnaComponent?.stepDelegate = delegate
            
            /// Sets a delegate to handle various errors during the Klarna payment process.
            errorDelegate = delegate
            validate()
        }
        
        public func setPaymentSessionDelegates() {
            klarnaComponent?.setAuthorizationDelegate()
            klarnaComponent?.setFinalizationDelegate()
            klarnaComponent?.setPaymentViewDelegate()
        }
        
        /// Initiates the creation of a Klarna payment session.
        public func startSession() {
            klarnaComponent?.start()
            validate()
        }
        
        // MARK: - Session authorization public methods
        
        /// Authorizes the payment session, optionally finalizing it automatically.
        public func authorizeSession(autoFinalize: Bool, jsonData: String? = nil) {
            klarnaComponent?.authorizeSession(autoFinalize: autoFinalize)
        }
        
        // MARK: - Session finalization public methods
        
        /// Finalizes the payment session, completing the payment process.
        public func finalizeSession() {
            klarnaComponent?.finalise()
        }
        
        // MARK: - Klarna PaymentView handling methods
        
        /// Configures the Klarna provider and view handling component with necessary information for payment processing.
        public func setProvider(with clientToken: String, paymentCategory: String) {
            klarnaProvider = PrimerKlarnaProvider(clientToken: clientToken, paymentCategory: paymentCategory, urlScheme: settings.paymentMethodOptions.urlScheme)
            
            klarnaComponent?.setProvider(provider: klarnaProvider)
        }
        
        /// Creates and returns a payment view for the Klarna payment process.
        public func createPaymentView() -> UIView? {
            klarnaComponent?.createPaymentView()
        }
        
        /// Initializes the payment view, preparing it for user interaction.
        public func initPaymentView() {
            klarnaComponent?.initPaymentView()
        }
        
        /// Loads the payment view with optional JSON data for customization.
        public func loadPaymentView(jsonData: String? = nil) {
            klarnaComponent?.loadPaymentView(jsonData: jsonData)
        }
        
        /// Validates the current state of the Klarna payment process, handling any errors that may occur.
        public func validate() {
            handleValidation()
        }
        
        // MARK: - PrimerKlarnaProviderErrorDelegate
        
        /// Handles errors from the Klarna SDK, forwarding them to the configured error delegate.
        public func primerKlarnaWrapperFailed(with error: PrimerKlarnaSDK.PrimerKlarnaError) {
            let primerError = PrimerError.klarnaWrapperError(
                message: error.errorDescription,
                userInfo: error.info,
                diagnosticsId: error.diagnosticsId
            )
            errorDelegate?.didReceiveError(error: primerError)
        }
        
        // MARK: - Handle errors from validate method
        
        /// Validates the tokenization component, handling any errors that occur during the process.
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

