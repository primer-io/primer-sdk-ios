//
//  ComposableContainer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// The main DI container for CheckoutComponents module.
/// Registers all dependencies needed for the checkout flow.
@available(iOS 15.0, *)
final class ComposableContainer: LogReporter {

    private let container: Container
    private let settings: PrimerSettings
    private let theme: PrimerCheckoutTheme

    init(
        settings: PrimerSettings,
        theme: PrimerCheckoutTheme = PrimerCheckoutTheme()
    ) {
        self.container = Container()
        self.settings = settings
        self.theme = theme
    }

    func configure() async {
        await registerInfrastructure()

        await registerValidation()

        await registerDomain()

        await registerData()

        await registerLogging()

        await DIContainer.setContainer(container)

        #if DEBUG
        await performHealthCheck()
        #endif
    }

    var diContainer: Container {
        container
    }
}

// MARK: - Registration Methods

@available(iOS 15.0, *)
private extension ComposableContainer {

    func registerInfrastructure() async {
        try? await container.register(PrimerSettings.self)
            .asSingleton()
            .with { _ in self.settings }

        try? await container.register(PrimerCheckoutTheme.self)
            .asSingleton()
            .with { _ in self.theme }

        try? await container.register(DesignTokensManager.self)
            .asSingleton()
            .with { _ in DesignTokensManager() }

        try? await container.register(CheckoutComponentsAnalyticsServiceProtocol.self)
            .asSingleton()
            .with { _ in
                AnalyticsEventService.create(
                    environmentProvider: AnalyticsEnvironmentProvider()
                )
            }

        try? await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { resolver in
                DefaultAnalyticsInteractor(
                    eventService: try await resolver.resolve(CheckoutComponentsAnalyticsServiceProtocol.self)
                )
            }

        try? await container.register(AccessibilityAnnouncementService.self)
            .asSingleton()
            .with { _ in DefaultAccessibilityAnnouncementService() }

        try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in DefaultConfigurationService() }
    }

    func registerValidation() async {
        try? await container.register(RulesFactory.self)
            .asSingleton()
            .with { _ in DefaultRulesFactory() }

        try? await container.register(ValidationService.self)
            .asSingleton()
            .with { resolver in
                let factory = try await resolver.resolve(RulesFactory.self)
                return DefaultValidationService(rulesFactory: factory)
            }
    }

    func registerDomain() async {
        try? await container.register(GetPaymentMethodsInteractor.self)
            .asTransient()
            .with { resolver in
                GetPaymentMethodsInteractorImpl(
                    repository: try await resolver.resolve(HeadlessRepository.self)
                )
            }

        try? await container.register(ProcessCardPaymentInteractor.self)
            .asTransient()
            .with { resolver in
                ProcessCardPaymentInteractorImpl(
                    repository: try await resolver.resolve(HeadlessRepository.self)
                )
            }

        try? await container.register(ValidateInputInteractor.self)
            .asTransient()
            .with { resolver in
                ValidateInputInteractorImpl(
                    validationService: try await resolver.resolve(ValidationService.self)
                )
            }

        try? await container.register(CardNetworkDetectionInteractor.self)
            .asTransient()
            .with { resolver in
                CardNetworkDetectionInteractorImpl(
                    repository: try await resolver.resolve(HeadlessRepository.self)
                )
            }

        try? await container.register(ProcessPayPalPaymentInteractor.self)
            .asTransient()
            .with { resolver in
                ProcessPayPalPaymentInteractorImpl(
                    repository: try await resolver.resolve(PayPalRepository.self)
                )
            }

        try? await container.register(ProcessKlarnaPaymentInteractor.self)
            .asTransient()
            .with { resolver in
                ProcessKlarnaPaymentInteractorImpl(
                    repository: try await resolver.resolve(KlarnaRepository.self)
                )
            }

        try? await container.register(ProcessApplePayPaymentInteractor.self)
            .asTransient()
            .with { _ in
                ProcessApplePayPaymentInteractorImpl(
                    tokenizationService: TokenizationService(),
                    createPaymentService: CreateResumePaymentService(paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
                )
            }

        try? await container.register(SubmitVaultedPaymentInteractor.self)
            .asTransient()
            .with { resolver in
                SubmitVaultedPaymentInteractorImpl(
                    repository: try await resolver.resolve(HeadlessRepository.self)
                )
            }
    }

    func registerData() async {
        // HeadlessRepository uses transient scope to ensure each checkout session gets a fresh instance.
        // This prevents stale state (e.g., cached card networks, validation handlers) from leaking
        // between checkout sessions when the user dismisses and re-presents the checkout UI.
        // Note: VaultManager is lazily initialized within HeadlessRepositoryImpl for vault payments.
        try? await container.register(HeadlessRepository.self)
            .asTransient()
            .with { _ in HeadlessRepositoryImpl() }

        try? await container.register(PaymentMethodMapper.self)
            .asSingleton()
            .with { container in
                let configService = try await container.resolve(ConfigurationService.self)
                return PaymentMethodMapperImpl(configurationService: configService)
            }

        try? await container.register(PayPalRepository.self)
            .asTransient()
            .with { _ in
                PayPalRepositoryImpl()
            }

        try? await container.register(KlarnaRepository.self)
            .asTransient()
            .with { _ in
                KlarnaRepositoryImpl()
            }
    }

    func registerLogging() async {
        try? await container.register(LogNetworkClient.self)
            .asSingleton()
            .with { _ in LogNetworkClient() }

        try? await container.register(SensitiveDataMasker.self)
            .asSingleton()
            .with { _ in SensitiveDataMasker() }

        try? await container.register(LogPayloadBuilding.self)
            .asSingleton()
            .with { _ in LogPayloadBuilder() }

        try? await container.register(LoggingService.self)
            .asSingleton()
            .with { resolver in
                LoggingService(
                    networkClient: try await resolver.resolve(LogNetworkClient.self),
                    payloadBuilder: try await resolver.resolve(LogPayloadBuilding.self),
                    masker: try await resolver.resolve(SensitiveDataMasker.self)
                )
            }
    }

    #if DEBUG
    func performHealthCheck() async {
        let diagnostics = await container.getDiagnostics()
        logger.debug(message: "Container diagnostics - Total registrations: \(diagnostics.totalRegistrations), Singletons: \(diagnostics.singletonInstances), Weak refs: \(diagnostics.weakReferences)/\(diagnostics.activeWeakReferences)")

        let healthReport = await container.performHealthCheck()
        if healthReport.status == .healthy {
            logger.debug(message: "Container is healthy")
        } else {
            logger.warn(message: "Health issues: \(healthReport.issues)")
        }
    }
    #endif
}
