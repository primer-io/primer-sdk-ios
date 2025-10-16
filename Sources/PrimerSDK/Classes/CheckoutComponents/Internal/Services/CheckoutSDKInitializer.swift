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
    private let settings: PrimerSettings
    private let diContainer: DIContainer
    private let navigator: CheckoutNavigator
    private let presentationContext: PresentationContext
    private let configurationModule: (PrimerAPIConfigurationModuleProtocol & AnalyticsSessionConfigProviding)
    private var analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

    // MARK: - Initialization

    init(
        clientToken: String,
        settings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        presentationContext: PresentationContext,
        configurationModule: (PrimerAPIConfigurationModuleProtocol & AnalyticsSessionConfigProviding) = PrimerAPIConfigurationModule()
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.diContainer = diContainer
        self.navigator = navigator
        self.presentationContext = presentationContext
        self.configurationModule = configurationModule
    }

    // MARK: - Public Methods

    /// Initialize the SDK and create the checkout scope
    func initialize() async throws -> InitializationResult {
        setupSDKIntegration()
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let composableContainer = ComposableContainer(settings: settings)
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

        if presentationContext == .direct {
            checkoutScope.checkoutNavigator.navigateToPaymentMethod("PAYMENT_CARD", context: .direct)
        }

        return InitializationResult(checkoutScope: checkoutScope)
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
        let settingsService = CheckoutComponentsSettingsService(settings: settings)

        return DefaultCheckoutScope(
            clientToken: clientToken,
            settingsService: settingsService,
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
        await analyticsInteractor?.trackEvent(.sdkInitStart, metadata: .general(GeneralEvent()))
    }

    private func trackSDKInitEnd() async {
        await analyticsInteractor?.trackEvent(.sdkInitEnd, metadata: .general(GeneralEvent()))
    }
}
