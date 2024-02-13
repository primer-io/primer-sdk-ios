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
        
        // MARK: - Session components
        
        /// Component responsible for managing session creation stages of the Klarna payment session.
        var sessionCreationComponent: KlarnaPaymentSessionCreationComponent?
        
        /// Component responsible for managing session authorization stages of the Klarna payment session.
        var sessionAuthorizationComponent: KlarnaPaymentSessionAuthorizationComponent?
        
        /// Component responsible for managing session finalization stages of the Klarna payment session.
        var sessionFinalizationComponent: KlarnaPaymentSessionFinalizationComponent?
        
        /// Component responsible for managing klarna view stages of the Klarna payment session.
        var viewHandlingComponent: KlarnaPaymentViewHandlingComponent?
        
        // MARK: - Manager properties
        
        /// A component that handles the tokenization process required for Klarna payments.
        private var tokenizationComponent: KlarnaTokenizationComponentProtocol?
        
        /// Global settings for the payment process, injected as a dependency.
        private let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        /// A delegate to handle errors that may occur during the payment process, involving KlarnaHeadlessManager logic.
        public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
        
        // MARK: - Klarna properties
        
        /// Responsible for performing operations related to Klarna's payment process.
        private var klarnaProvider: PrimerKlarnaProviding?
        
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
            
            self.sessionCreationComponent = KlarnaPaymentSessionCreationComponent(
                tokenizationComponent: tokenizationComponent
            )
            
            self.sessionAuthorizationComponent = KlarnaPaymentSessionAuthorizationComponent(
                tokenizationComponent: tokenizationComponent
            )
            
            self.sessionFinalizationComponent = KlarnaPaymentSessionFinalizationComponent(
                tokenizationComponent: tokenizationComponent
            )
            self.viewHandlingComponent = KlarnaPaymentViewHandlingComponent()
        }
        
        /// Sets a delegate to handle various events and errors during the Klarna payment process.
        public func setDelegate(_ delegate: PrimerHeadlessKlarnaComponent) {
            errorDelegate = delegate
            validate()
        }
        
        // MARK: - Session creation public methods
        
        /// Configures delegates for the session creation component to handle validation, errors, and steps in the payment process.
        public func setSessionCreationDelegates(_ delegate: PrimerHeadlessKlarnaComponent) {
            sessionCreationComponent?.validationDelegate = delegate
            sessionCreationComponent?.errorDelegate = delegate
            sessionCreationComponent?.stepDelegate = delegate
        }
        
        /// Initiates the creation of a Klarna payment session.
        public func startSession() {
            sessionCreationComponent?.start()
            validate()
        }
        
        /// Updates the payment session with data collected from the user.
        public func updateSessionCollectedData(collectableData: KlarnaPaymentSessionCollectableData) {
            sessionCreationComponent?.updateCollectedData(collectableData: collectableData)
        }
        
        // MARK: - Session authorization public methods
        
        /// Sets a delegate to handle steps during the session authorization process.
        public func setSessionAuthorizationDelegate(_ delegate: PrimerHeadlessKlarnaComponent) {
            sessionAuthorizationComponent?.setProvider(provider: klarnaProvider)
            sessionAuthorizationComponent?.stepDelegate = delegate
        }
        
        /// Authorizes the payment session, optionally finalizing it automatically.
        public func authorizeSession(autoFinalize: Bool, jsonData: String? = nil) {
            sessionAuthorizationComponent?.authorizeSession(autoFinalize: autoFinalize)
        }
        
        // MARK: - Session finalization public methods
        
        /// Sets a delegate to manage the finalization step of the payment session.
        public func setSessionFinalizationDelegate(_ delegate: PrimerHeadlessKlarnaComponent) {
            sessionFinalizationComponent?.setProvider(provider: klarnaProvider)
            sessionFinalizationComponent?.stepDelegate = delegate
        }
        
        /// Finalizes the payment session, completing the payment process.
        public func finalizeSession() {
            sessionFinalizationComponent?.finalise()
        }
        
        // MARK: - Klarna PaymentView handling methods
        
        /// Configures the Klarna provider and view handling component with necessary information for payment processing.
        public func setProvider(with clientToken: String, paymentCategory: String) {
            klarnaProvider = PrimerKlarnaProvider(clientToken: clientToken, paymentCategory: paymentCategory, urlScheme: settings.paymentMethodOptions.urlScheme)
            
            viewHandlingComponent?.setProvider(provider: klarnaProvider)
        }
        
        /// Sets a delegate to handle steps related to payment view management.
        public func setViewHandlingDelegate(_ delegate: PrimerHeadlessKlarnaComponent) {
            viewHandlingComponent?.stepDelegate = delegate
        }
        
        /// Creates and returns a payment view for the Klarna payment process.
        public func createPaymentView() -> UIView? {
            viewHandlingComponent?.createPaymentView()
        }
        
        /// Initializes the payment view, preparing it for user interaction.
        public func initPaymentView() {
            viewHandlingComponent?.initPaymentView()
        }
        
        /// Loads the payment view with optional JSON data for customization.
        public func loadPaymentView(jsonData: String? = nil) {
            viewHandlingComponent?.loadPaymentView(jsonData: jsonData)
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
