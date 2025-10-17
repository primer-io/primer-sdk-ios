//
//  CheckoutSDKInitializer.swift
//  PrimerSDK
//
//  Created by Boris on 23.12.24.
//

import Foundation

/// Service responsible for SDK initialization for CheckoutComponents
@available(iOS 15.0, *)
@MainActor
final class CheckoutSDKInitializer {

    // MARK: - Types

    struct InitializationResult {
        let checkoutScope: DefaultCheckoutScope
    }

    // MARK: - Properties

    private let clientToken: String
    private let primerSettings: PrimerSettings
    private let diContainer: DIContainer
    private let navigator: CheckoutNavigator
    private let presentationContext: PresentationContext

    // MARK: - Initialization

    init(
        clientToken: String,
        primerSettings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        presentationContext: PresentationContext
    ) {
        self.clientToken = clientToken
        self.primerSettings = primerSettings
        self.diContainer = diContainer
        self.navigator = navigator
        self.presentationContext = presentationContext
    }

    // MARK: - Public Methods

    /// Initialize the SDK and create the checkout scope
    func initialize() async throws -> InitializationResult {
        setupSDKIntegration()

        try await initializeAPIConfiguration()

        let composableContainer = ComposableContainer(settings: primerSettings)
        await composableContainer.configure()

        let checkoutScope = createCheckoutScope()

        if presentationContext == .direct {
            checkoutScope.checkoutNavigator.navigateToPaymentMethod("PAYMENT_CARD", context: .direct)
        }

        return InitializationResult(checkoutScope: checkoutScope)
    }

    /// Clean up resources when checkout session ends
    func cleanup() {
        Task {
            await DIContainer.clearContainer()
        }
    }

    // MARK: - Private Methods

    private func setupSDKIntegration() {
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        PrimerInternal.shared.intent = .checkout
        PrimerInternal.shared.checkoutSessionId = UUID().uuidString
    }

    private func initializeAPIConfiguration() async throws {
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        try await apiConfigurationModule.setupSession(
            forClientToken: clientToken,
            requestDisplayMetadata: true,
            requestClientTokenValidation: false,
            requestVaultedPaymentMethods: false
        )
    }

    private func createCheckoutScope() -> DefaultCheckoutScope {
        let settingsService = CheckoutComponentsSettingsService(settings: primerSettings)

        return DefaultCheckoutScope(
            clientToken: clientToken,
            settingsService: settingsService,
            diContainer: diContainer,
            navigator: navigator,
            presentationContext: presentationContext
        )
    }
}
