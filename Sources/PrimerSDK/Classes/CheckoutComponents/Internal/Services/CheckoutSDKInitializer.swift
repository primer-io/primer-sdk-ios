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
    private var analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

    // MARK: - Initialization

    init(
        clientToken: String,
        settings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        presentationContext: PresentationContext
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.diContainer = diContainer
        self.navigator = navigator
        self.presentationContext = presentationContext
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
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        try await apiConfigurationModule.setupSession(
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
        // Extract session data from client token JWT
        guard let tokenPayload = decodeClientToken(clientToken) else {
            #if DEBUG
            print("⚠️ Failed to decode client token for analytics")
            #endif
            return
        }

        // Determine environment from token
        let environmentString = tokenPayload["env"] as? String ?? "PRODUCTION"
        let environment = AnalyticsEnvironment(rawValue: environmentString.uppercased()) ?? .production

        // Prefer identifiers from the fetched API configuration (matches Web SDK behaviour)
        let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration
        let configClientSessionId = apiConfiguration?.clientSession?.clientSessionId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let configPrimerAccountId = apiConfiguration?.primerAccountId?.trimmingCharacters(in: .whitespacesAndNewlines)

        // Fallback to token payload only if configuration does not include the identifiers
        let tokenClientSessionId = (tokenPayload["clientSessionId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokenPrimerAccountId = (tokenPayload["primerAccountId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        let clientSessionId = configClientSessionId?.isEmpty == false
            ? configClientSessionId!
            : (tokenClientSessionId ?? "")
        let primerAccountId = configPrimerAccountId?.isEmpty == false
            ? configPrimerAccountId!
            : (tokenPrimerAccountId ?? "")

        guard !clientSessionId.isEmpty, !primerAccountId.isEmpty else {
            #if DEBUG
            print("⚠️ Missing analytics identifiers: clientSessionId=\(clientSessionId.isEmpty), primerAccountId=\(primerAccountId.isEmpty)")
            #endif
            return
        }

        // Get checkout session ID (generated in setupSDKIntegration)
        let checkoutSessionId = PrimerInternal.shared.checkoutSessionId ?? UUID().uuidString

        // Get SDK version
        let sdkVersion = VersionUtils.releaseVersionNumber ?? "unknown"

        // Create analytics session config
        let analyticsConfig = AnalyticsSessionConfig(
            environment: environment,
            checkoutSessionId: checkoutSessionId,
            clientSessionId: clientSessionId,
            primerAccountId: primerAccountId,
            sdkVersion: sdkVersion,
            clientSessionToken: clientToken
        )

        // Initialize analytics service
        guard let container = await DIContainer.current else { return }

        if let analyticsService = try? await container.resolve(CheckoutComponentsAnalyticsServiceProtocol.self) {
            await analyticsService.initialize(config: analyticsConfig)
        }
    }

    private func trackSDKInitStart() async {
        await analyticsInteractor?.trackEvent(.sdkInitStart, metadata: .withLocale())
    }

    private func trackSDKInitEnd() async {
        await analyticsInteractor?.trackEvent(.sdkInitEnd, metadata: .withLocale())
    }

    private func decodeClientToken(_ token: String) -> [String: Any]? {
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { return nil }

        // Decode the payload (middle segment)
        let payloadSegment = components[1]
        let paddedPayload = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .padding(toLength: ((payloadSegment.count + 3) / 4) * 4, withPad: "=", startingAt: 0)

        guard let payloadData = Data(base64Encoded: paddedPayload),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }

        return json
    }
}
