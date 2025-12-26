//
//  CheckoutSDKInitializer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

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
    private let primerTheme: PrimerCheckoutTheme
    private let diContainer: DIContainer
    private let navigator: CheckoutNavigator
    private let presentationContext: PresentationContext
    private let configurationModule: (PrimerAPIConfigurationModuleProtocol & AnalyticsSessionConfigProviding)
    private var analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

    // MARK: - Initialization

    init(
        clientToken: String,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        presentationContext: PresentationContext,
        configurationModule: (PrimerAPIConfigurationModuleProtocol & AnalyticsSessionConfigProviding) = PrimerAPIConfigurationModule()
    ) {
        self.clientToken = clientToken
        self.primerSettings = primerSettings
        self.primerTheme = primerTheme
        self.diContainer = diContainer
        self.navigator = navigator
        self.presentationContext = presentationContext
        self.configurationModule = configurationModule
    }

    // MARK: - Public Methods

    func initialize() async throws -> InitializationResult {
        setupSDKIntegration()

        // Bridge: Register settings in old DI for core SDK compatibility
        // Core SDK (KlarnaHelpers, ACHHelpers, 3DS, etc.) uses PrimerSettings.current
        DependencyContainer.register(primerSettings)

        let composableContainer = ComposableContainer(
            settings: primerSettings,
            theme: primerTheme
        )
        await composableContainer.configure()

        // Resolve analytics interactor
        if let container = await DIContainer.current {
            analyticsInteractor = try? await container.resolve(CheckoutComponentsAnalyticsInteractorProtocol.self)
        }

        // Track SDK initialization start - after DI container is ready, before BE calls
        await trackSDKInitStart()

        try await initializeAPIConfiguration()

        // Initialize analytics session
        await initializeAnalytics()

        // Track SDK initialization end - after all API calls complete
        await trackSDKInitEnd()

        let checkoutScope = createCheckoutScope()

        // Note: Navigation is handled by DefaultCheckoutScope.loadPaymentMethods() which:
        // - Waits for payment methods from server
        // - If single payment method: navigates directly to it (any type, not just cards)
        // - If multiple payment methods: shows payment method selection screen

        return InitializationResult(checkoutScope: checkoutScope)
    }

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
        try await configurationModule.setupSession(
            forClientToken: clientToken,
            requestDisplayMetadata: true,
            requestClientTokenValidation: false,
            requestVaultedPaymentMethods: false
        )
    }

    private func createCheckoutScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: clientToken,
            settings: primerSettings,
            diContainer: diContainer,
            navigator: navigator,
            presentationContext: presentationContext
        )
    }

    // MARK: - Analytics Initialization

    private func initializeAnalytics() async {
        let checkoutSessionId = PrimerInternal.shared.checkoutSessionId ?? UUID().uuidString
        let sdkVersion = VersionUtils.releaseVersionNumber ?? "unknown"

        guard let analyticsConfig = configurationModule.makeAnalyticsSessionConfig(
            checkoutSessionId: checkoutSessionId,
            clientToken: clientToken,
            sdkVersion: sdkVersion
        ) else {
            #if DEBUG
            print("⚠️ Unable to create analytics session config")
            #endif
            return
        }

        guard let container = await DIContainer.current else { return }

        if let analyticsService = try? await container.resolve(CheckoutComponentsAnalyticsServiceProtocol.self) {
            await analyticsService.initialize(config: analyticsConfig)
        }
    }

    private func trackSDKInitStart() async {
        await analyticsInteractor?.trackEvent(.sdkInitStart, metadata: nil)
    }

    private func trackSDKInitEnd() async {
        await analyticsInteractor?.trackEvent(.sdkInitEnd, metadata: nil)
    }
}
