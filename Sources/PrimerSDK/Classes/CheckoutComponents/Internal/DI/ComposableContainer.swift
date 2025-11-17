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

    init(settings: PrimerSettings) {
        self.container = Container()
        self.settings = settings
    }

    /// Configure and register all dependencies for CheckoutComponents.
    func configure() async {
        await registerInfrastructure()

        await registerValidation()

        await registerDomain()

        await registerData()

        await registerPresentation()

        await DIContainer.setContainer(container)

        #if DEBUG
        await performHealthCheck()
        #endif
    }

    /// Get the configured container.
    var diContainer: Container {
        container
    }
}

// MARK: - Registration Methods

@available(iOS 15.0, *)
private extension ComposableContainer {

    /// Register infrastructure components.
    func registerInfrastructure() async {
        _ = try? await container.register(PrimerSettings.self)
            .asSingleton()
            .with { _ in self.settings }

        _ = try? await container.register(PrimerThemeProtocol.self)
            .asSingleton()
            .with { _ in self.settings.uiOptions.theme }

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
    }

    /// Register validation framework.
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

    /// Register domain layer (interactors, models).
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

    /// Register data layer (repositories, mappers).
    func registerData() async {
        _ = try? await container.register(HeadlessRepository.self)
            .asSingleton()
            .with { _ in HeadlessRepositoryImpl() }

        _ = try? await container.register(PaymentMethodMapper.self)
            .asSingleton()
            .with { _ in PaymentMethodMapperImpl() }
    }

    /// Register presentation layer (scopes, view models).
    func registerPresentation() async {
    }

    #if DEBUG
    /// Perform health check on the container.
    func performHealthCheck() async {
        let diagnostics = await container.getDiagnostics()

        let healthReport = await container.performHealthCheck()
        if healthReport.status == .healthy {
            logger.debug(message: "Container is healthy")
        } else {
            logger.warn(message: "Health issues: \(healthReport.issues)")
        }
    }
    #endif
}
