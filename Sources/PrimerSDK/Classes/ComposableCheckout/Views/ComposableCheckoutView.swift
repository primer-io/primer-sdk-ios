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
    @State private var stateTask: Task<Void, Never>?
    @Environment(\.diContainer) private var diContainer
    @StateObject private var navigator = CheckoutNavigator()

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
        .environment(\.checkoutNavigator, navigator)
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
        .task {
            for await state in checkoutScope.state() {
                handleCheckoutStateChange(state)
            }
        }
        .onAppear {
            setupNavigationObservers()
        }
        .onDisappear {
            stateTask?.cancel()
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

    private func setupNavigationObservers() {
        logger.debug(message: "🔗 [ComposableCheckoutView] Setting up navigation observers")

        // Observe navigation events from CheckoutNavigator
        navigator.navigationEvents
            .receive(on: DispatchQueue.main)
            .sink { event in
                handleNavigationEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handleNavigationEvent(_ event: NavigationEvent) {
        logger.debug(message: "🧭 [ComposableCheckoutView] Handling navigation event: \(event)")

        switch event {
        case .navigateToPaymentSelection:
            currentScreen = .paymentSelection
        case .navigateToCardForm:
            currentScreen = .cardForm
        case .navigateToApplePay:
            // Handle Apple Pay navigation in future iterations
            logger.debug(message: "📱 [ComposableCheckoutView] Apple Pay navigation not implemented yet")
        case .navigateToPayPal:
            // Handle PayPal navigation in future iterations
            logger.debug(message: "💰 [ComposableCheckoutView] PayPal navigation not implemented yet")
        case .navigateToSuccess:
            logger.info(message: "✅ [ComposableCheckoutView] Payment completed successfully")
            currentScreen = .success
        case .navigateToError(let message):
            logger.error(message: "❌ [ComposableCheckoutView] Payment error: \(message)")
            errorMessage = message
            currentScreen = .error
        case .navigateBack:
            // Handle back navigation based on current screen
            handleBackNavigation()
        }
    }

    private func handleBackNavigation() {
        switch currentScreen {
        case .cardForm, .paymentSelection:
            currentScreen = .paymentSelection
        case .error:
            currentScreen = .paymentSelection
        default:
            logger.debug(message: "🔙 [ComposableCheckoutView] Back navigation not applicable for current screen")
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

// MARK: - Preview

@available(iOS 15.0, *)
struct ComposableCheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        ComposableCheckoutView()
    }
}
