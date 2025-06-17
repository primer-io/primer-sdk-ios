//
//  ComposableCheckoutView.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Main checkout view that handles navigation and screen transitions
@available(iOS 15.0, *)
internal struct ComposableCheckoutView: View, LogReporter {
    
    // MARK: - Customization Closures
    
    let container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)?
    let splashScreen: (@ViewBuilder () -> any View)?
    let loadingScreen: (@ViewBuilder () -> any View)?
    let paymentSelectionScreen: (@ViewBuilder () -> any View)?
    let cardFormScreen: (@ViewBuilder () -> any View)?
    let successScreen: (@ViewBuilder () -> any View)?
    let errorScreen: (@ViewBuilder (_ cause: String) -> any View)?
    
    // MARK: - State
    
    @State private var currentScreen: CheckoutScreen = .splash
    @State private var errorMessage: String = ""
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.diContainer) private var diContainer
    
    // MARK: - Initialization
    
    init(
        container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)? = nil,
        splashScreen: (@ViewBuilder () -> any View)? = nil,
        loadingScreen: (@ViewBuilder () -> any View)? = nil,
        paymentSelectionScreen: (@ViewBuilder () -> any View)? = nil,
        cardFormScreen: (@ViewBuilder () -> any View)? = nil,
        successScreen: (@ViewBuilder () -> any View)? = nil,
        errorScreen: (@ViewBuilder (_ cause: String) -> any View)? = nil
    ) {
        self.container = container
        self.splashScreen = splashScreen
        self.loadingScreen = loadingScreen
        self.paymentSelectionScreen = paymentSelectionScreen
        self.cardFormScreen = cardFormScreen
        self.successScreen = successScreen
        self.errorScreen = errorScreen
    }
    
    // MARK: - Body
    
    var body: some View {
        AsyncScopeView { checkoutScope, cardFormScope, paymentSelectionScope in
            let content = {
                AnyView(
                    checkoutContent(
                        checkoutScope: checkoutScope,
                        cardFormScope: cardFormScope,
                        paymentSelectionScope: paymentSelectionScope
                    )
                )
            }
            
            if let container = container {
                container(content)
            } else {
                defaultContainer(content)
            }
        }
        .onAppear {
            logger.debug(message: "🏁 [ComposableCheckoutView] View appeared, starting checkout flow")
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private func checkoutContent(
        checkoutScope: any PrimerCheckoutScope,
        cardFormScope: any CardFormScope,
        paymentSelectionScope: any PaymentMethodSelectionScope
    ) -> some View {
        VStack {
            switch currentScreen {
            case .splash:
                splashScreen?() ?? DefaultSplashScreen()
            case .loading:
                loadingScreen?() ?? DefaultLoadingScreen()
            case .paymentSelection:
                paymentSelectionScreen?() ?? DefaultPaymentSelectionScreen(scope: paymentSelectionScope)
            case .cardForm:
                cardFormScreen?() ?? DefaultCardFormScreen(scope: cardFormScope)
            case .success:
                successScreen?() ?? DefaultSuccessScreen()
            case .error:
                errorScreen?(errorMessage) ?? DefaultErrorScreen(errorMessage: errorMessage)
            }
        }
        .onReceive(checkoutScope.state) { state in
            handleCheckoutStateChange(state)
        }
        .onAppear {
            setupNavigationObservers(
                checkoutScope: checkoutScope,
                paymentSelectionScope: paymentSelectionScope
            )
        }
    }
    
    @ViewBuilder
    private func defaultContainer<Content: View>(_ content: @escaping () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    
    // MARK: - Navigation Logic
    
    private func handleCheckoutStateChange(_ state: CheckoutState) {
        Task { @MainActor in
            logger.debug(message: "🔄 [ComposableCheckoutView] Checkout state changed: \(state)")
            
            switch state {
            case .notInitialized:
                currentScreen = .splash
            case .initializing:
                currentScreen = .loading
            case .ready:
                currentScreen = .paymentSelection
            case .error(let error):
                errorMessage = error
                currentScreen = .error
            }
        }
    }
    
    private func setupNavigationObservers(
        checkoutScope: any PrimerCheckoutScope,
        paymentSelectionScope: any PaymentMethodSelectionScope
    ) {
        logger.debug(message: "🔗 [ComposableCheckoutView] Setting up navigation observers")
        
        // Observe payment method selection
        NotificationCenter.default.publisher(for: .paymentMethodSelected)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                if let paymentMethod = notification.object as? PrimerComposablePaymentMethod {
                    handlePaymentMethodSelection(paymentMethod)
                }
            }
            .store(in: &cancellables)
        
        // Observe payment completion
        NotificationCenter.default.publisher(for: .paymentCompleted)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                logger.info(message: "✅ [ComposableCheckoutView] Payment completed successfully")
                currentScreen = .success
            }
            .store(in: &cancellables)
        
        // Observe payment errors
        NotificationCenter.default.publisher(for: .paymentError)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                if let error = notification.object as? Error {
                    logger.error(message: "❌ [ComposableCheckoutView] Payment error: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    currentScreen = .error
                }
            }
            .store(in: &cancellables)
    }
    
    private func handlePaymentMethodSelection(_ paymentMethod: PrimerComposablePaymentMethod) {
        logger.debug(message: "💳 [ComposableCheckoutView] Payment method selected: \(paymentMethod.paymentMethodType)")
        
        switch paymentMethod.paymentMethodType {
        case "PAYMENT_CARD":
            currentScreen = .cardForm
        default:
            logger.warning(message: "⚠️ [ComposableCheckoutView] Unsupported payment method: \(paymentMethod.paymentMethodType)")
            // Handle other payment methods in future iterations
            break
        }
    }
    
    // MARK: - Screen Enum
    
    private enum CheckoutScreen {
        case splash
        case loading
        case paymentSelection
        case cardForm
        case success
        case error
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let paymentMethodSelected = Notification.Name("PaymentMethodSelected")
    static let paymentCompleted = Notification.Name("PaymentCompleted")
    static let paymentError = Notification.Name("PaymentError")
}

// MARK: - Preview

@available(iOS 15.0, *)
struct ComposableCheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        ComposableCheckoutView()
            .environment(\.diContainer, MockDIContainer())
    }
}

// MARK: - Mock DI Container for Preview

@available(iOS 15.0, *)
private class MockDIContainer: DIContainerProtocol {
    func resolve<T>(_ type: T.Type) async throws -> T {
        throw ContainerError.typeNotRegistered(String(describing: type))
    }
    
    func isRegistered<T>(_ type: T.Type) async -> Bool {
        false
    }
    
    func getDiagnostics() async -> ContainerDiagnostics {
        ContainerDiagnostics(
            registeredTypes: [],
            singletonCount: 0,
            weakReferenceCount: 0,
            transientResolutions: 0
        )
    }
    
    func performHealthCheck() async -> ContainerHealthReport {
        ContainerHealthReport(
            isHealthy: false,
            issues: ["Mock container for preview"],
            performanceMetrics: [:]
        )
    }
}