//
//  ComposableContainer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
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
        _ = try? await container.register(PrimerSettings.self)
            .asSingleton()
            .with { _ in self.settings }

        _ = try? await container.register(PrimerCheckoutTheme.self)
            .asSingleton()
            .with { _ in self.theme }

        _ = try? await container.register(DesignTokensManager.self)
            .asSingleton()
            .with { _ in DesignTokensManager() }

        _ = try? await container.register(CheckoutComponentsAnalyticsServiceProtocol.self)
            .asSingleton()
            .with { _ in
                AnalyticsEventService.create(
                    environmentProvider: AnalyticsEnvironmentProvider()
                )
            }

        _ = try? await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { resolver in
                DefaultAnalyticsInteractor(
                    eventService: try await resolver.resolve(CheckoutComponentsAnalyticsServiceProtocol.self)
                )
            }

        _ = try? await container.register(AccessibilityAnnouncementService.self)
            .asSingleton()
            .with { _ in DefaultAccessibilityAnnouncementService() }

        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in DefaultConfigurationService() }
    }

    func registerValidation() async {
        _ = try? await container.register(RulesFactory.self)
            .asSingleton()
            .with { _ in DefaultRulesFactory() }

        _ = try? await container.register(ValidationService.self)
            .asSingleton()
            .with { resolver in
                let factory = try await resolver.resolve(RulesFactory.self)
                return DefaultValidationService(rulesFactory: factory)
            }
    }

    func registerDomain() async {
        _ = try? await container.register(GetPaymentMethodsInteractor.self)
            .asTransient()
            .with { resolver in
                GetPaymentMethodsInteractorImpl(
                    repository: try await resolver.resolve(HeadlessRepository.self)
                )
            }

        _ = try? await container.register(ProcessCardPaymentInteractor.self)
            .asTransient()
            .with { resolver in
                ProcessCardPaymentInteractorImpl(
                    repository: try await resolver.resolve(HeadlessRepository.self)
                )
            }

        _ = try? await container.register(ValidateInputInteractor.self)
            .asTransient()
            .with { resolver in
                ValidateInputInteractorImpl(
                    validationService: try await resolver.resolve(ValidationService.self)
                )
            }

        _ = try? await container.register(CardNetworkDetectionInteractor.self)
            .asTransient()
            .with { resolver in
                CardNetworkDetectionInteractorImpl(
                    repository: try await resolver.resolve(HeadlessRepository.self)
                )
            }
    }

    func registerData() async {
        // HeadlessRepository uses transient scope to ensure each checkout session gets a fresh instance.
        // This prevents stale state (e.g., cached card networks, validation handlers) from leaking
        // between checkout sessions when the user dismisses and re-presents the checkout UI.
        _ = try? await container.register(HeadlessRepository.self)
            .asTransient()
            .with { _ in HeadlessRepositoryImpl() }

        _ = try? await container.register(PaymentMethodMapper.self)
            .asSingleton()
            .with { container in
                let configService = try await container.resolve(ConfigurationService.self)
                return PaymentMethodMapperImpl(configurationService: configService)
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
