//
//  DefaultCheckoutScope.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default implementation of PrimerCheckoutScope
@available(iOS 15.0, *)
@MainActor
internal final class DefaultCheckoutScope: PrimerCheckoutScope, ObservableObject, LogReporter {
    // MARK: - Internal Navigation State
    
    internal enum NavigationState {
        case loading
        case paymentMethodSelection
        case cardForm
        case success(PaymentResult)
        case error(PrimerError)
    }
    
    // MARK: - Properties
    
    /// The current checkout state
    @Published private var internalState = PrimerCheckoutScope.State.initializing
    
    /// The current navigation state
    @Published internal var navigationState = NavigationState.loading
    
    /// State stream for external observation
    public var state: AsyncStream<PrimerCheckoutScope.State> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await value in $internalState.values {
                    continuation.yield(value)
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - UI Customization Properties
    
    public var container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)?
    public var splashScreen: (@ViewBuilder () -> any View)?
    public var loadingScreen: (@ViewBuilder () -> any View)?
    public var successScreen: (@ViewBuilder () -> any View)?
    public var errorScreen: (@ViewBuilder (_ error: PrimerError) -> any View)?
    public var paymentMethodSelectionScreen: (@ViewBuilder (_ scope: PrimerPaymentMethodSelectionScope) -> any View)?
    public var cardFormScreen: (@ViewBuilder (_ scope: PrimerCardFormScope) -> any View)?
    
    // MARK: - Child Scopes
    
    private var _cardForm: PrimerCardFormScope?
    public var cardForm: PrimerCardFormScope {
        if let existing = _cardForm {
            return existing
        }
        let scope = DefaultCardFormScope(checkoutScope: self)
        _cardForm = scope
        return scope
    }
    
    private var _paymentMethodSelection: PrimerPaymentMethodSelectionScope?
    public var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        if let existing = _paymentMethodSelection {
            return existing
        }
        let scope = DefaultPaymentMethodSelectionScope(checkoutScope: self)
        _paymentMethodSelection = scope
        return scope
    }
    
    // MARK: - Services
    
    private let diContainer: DIContainer
    private let navigator: CheckoutNavigator
    private var getPaymentMethodsInteractor: GetPaymentMethodsInteractor?
    
    // MARK: - Other Properties
    
    private let clientToken: String
    private let settings: PrimerSettings
    private var availablePaymentMethods: [InternalPaymentMethod] = []
    
    // MARK: - Initialization
    
    init(clientToken: String, settings: PrimerSettings, diContainer: DIContainer, navigator: CheckoutNavigator) {
        self.clientToken = clientToken
        self.settings = settings
        self.diContainer = diContainer
        self.navigator = navigator
        
        Task {
            await setupInteractors()
            await loadPaymentMethods()
        }
    }
    
    // MARK: - Setup
    
    private func setupInteractors() async {
        do {
            getPaymentMethodsInteractor = try await diContainer.resolve(GetPaymentMethodsInteractor.self)
        } catch {
            log(logLevel: .error, message: "Failed to setup interactors: \\(error)")
            let primerError = PrimerError.failedToLoadAvailablePaymentMethods(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            updateNavigationState(.error(primerError))
            updateState(.error(primerError))
        }
    }
    
    private func loadPaymentMethods() async {
        updateNavigationState(.loading)
        
        do {
            guard let interactor = getPaymentMethodsInteractor else {
                throw PrimerError.failedToLoadAvailablePaymentMethods(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
            }
            
            availablePaymentMethods = try await interactor.execute()
            
            if availablePaymentMethods.isEmpty {
                let error = PrimerError.failedToLoadAvailablePaymentMethods(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                updateNavigationState(.error(error))
                updateState(.error(error))
            } else {
                updateState(.ready)
                
                // Check if we have only card payment method
                if availablePaymentMethods.count == 1, 
                   availablePaymentMethods.first?.type == "PAYMENT_CARD" {
                    // Go directly to card form
                    updateNavigationState(.cardForm)
                } else {
                    // Show payment method selection
                    updateNavigationState(.paymentMethodSelection)
                }
            }
        } catch {
            log(logLevel: .error, message: "Failed to load payment methods: \\(error)")
            let primerError = error as? PrimerError ?? PrimerError.failedToLoadAvailablePaymentMethods(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            updateNavigationState(.error(primerError))
            updateState(.error(primerError))
        }
    }
    
    // MARK: - State Management
    
    private func updateState(_ newState: PrimerCheckoutScope.State) {
        log(logLevel: .debug, message: "Checkout state updating to: \\(newState)")
        internalState = newState
    }
    
    private func updateNavigationState(_ newState: NavigationState) {
        log(logLevel: .debug, message: "Navigation state updating to: \\(newState)")
        navigationState = newState
        
        // Update navigation based on state
        switch newState {
        case .loading:
            navigator.navigateToLoading()
        case .paymentMethodSelection:
            navigator.navigateToPaymentSelection()
        case .cardForm:
            navigator.navigateToCardForm()
        case .success:
            navigator.navigateToSuccess()
        case .error(let error):
            navigator.navigateToError(error.localizedDescription)
        }
    }
    
    // MARK: - Public Methods
    
    public func onDismiss() {
        log(logLevel: .debug, message: "Checkout dismissed")
        // Clean up any resources
        _cardForm = nil
        _paymentMethodSelection = nil
        
        // Notify parent
        // This would be handled by the parent view controller
    }
    
    // MARK: - Internal Methods
    
    internal func handlePaymentMethodSelection(_ method: InternalPaymentMethod) {
        log(logLevel: .debug, message: "Payment method selected: \\(method.type)")
        
        switch method.type {
        case "PAYMENT_CARD":
            updateNavigationState(.cardForm)
        default:
            // For now, only card is supported
            log(logLevel: .warning, message: "Unsupported payment method: \\(method.type)")
        }
    }
    
    internal func handlePaymentSuccess(_ result: PaymentResult) {
        log(logLevel: .debug, message: "Payment successful")
        updateNavigationState(.success(result))
    }
    
    internal func handlePaymentError(_ error: PrimerError) {
        log(logLevel: .error, message: "Payment error: \\(error)")
        updateNavigationState(.error(error))
        updateState(.error(error))
    }
}