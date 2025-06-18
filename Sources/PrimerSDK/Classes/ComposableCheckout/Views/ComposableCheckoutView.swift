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
    
    let container: ((_ content: @escaping () -> AnyView) -> AnyView)?
    let splashScreen: (() -> AnyView)?
    let loadingScreen: (() -> AnyView)?
    let paymentSelectionScreen: (() -> AnyView)?
    let cardFormScreen: (() -> AnyView)?
    let successScreen: (() -> AnyView)?
    let errorScreen: ((_ cause: String) -> AnyView)?
    
    // MARK: - State
    
    @State private var currentScreen: CheckoutScreen = .splash
    @State private var errorMessage: String = ""
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.diContainer) private var diContainer
    
    // MARK: - Initialization
    
    init(
        container: ((_ content: @escaping () -> AnyView) -> AnyView)? = nil,
        splashScreen: (() -> AnyView)? = nil,
        loadingScreen: (() -> AnyView)? = nil,
        paymentSelectionScreen: (() -> AnyView)? = nil,
        cardFormScreen: (() -> AnyView)? = nil,
        successScreen: (() -> AnyView)? = nil,
        errorScreen: ((_ cause: String) -> AnyView)? = nil
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
                AnyView(splashScreen?() ?? AnyView(DefaultSplashScreen()))
            case .loading:
                AnyView(loadingScreen?() ?? AnyView(DefaultLoadingScreen()))
            case .paymentSelection:
                AnyView(paymentSelectionScreen?() ?? AnyView(DefaultPaymentSelectionScreen(scope: paymentSelectionScope)))
            case .cardForm:
                AnyView(cardFormScreen?() ?? AnyView(DefaultCardFormScreen(scope: cardFormScope)))
            case .success:
                AnyView(successScreen?() ?? AnyView(DefaultSuccessScreen()))
            case .error:
                AnyView(errorScreen?(errorMessage) ?? AnyView(DefaultErrorScreen(errorMessage: errorMessage)))
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
        NotificationCenter.default.publisher(for: .composablePaymentMethodSelected)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                if let paymentMethod = notification.object as? PrimerComposablePaymentMethod {
                    handlePaymentMethodSelection(paymentMethod)
                }
            }
            .store(in: &cancellables)
        
        // Observe payment completion
        NotificationCenter.default.publisher(for: .composablePaymentCompleted)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                logger.info(message: "✅ [ComposableCheckoutView] Payment completed successfully")
                currentScreen = .success
            }
            .store(in: &cancellables)
        
        // Observe payment errors
        NotificationCenter.default.publisher(for: .composablePaymentError)
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
            logger.warn(message: "⚠️ [ComposableCheckoutView] Unsupported payment method: \(paymentMethod.paymentMethodType)")
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
    static let composablePaymentMethodSelected = Notification.Name("ComposablePaymentMethodSelected")
    static let composablePaymentCompleted = Notification.Name("ComposablePaymentCompleted")
    static let composablePaymentError = Notification.Name("ComposablePaymentError")
}

// MARK: - Preview

@available(iOS 15.0, *)
struct ComposableCheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        ComposableCheckoutView()
    }
}
