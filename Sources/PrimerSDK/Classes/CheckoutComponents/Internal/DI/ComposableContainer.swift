//
//  ComposableContainer.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// The main DI container for CheckoutComponents module.
/// Registers all dependencies needed for the checkout flow.
@available(iOS 15.0, *)
internal final class ComposableContainer: LogReporter {

    private let container: Container
    private let settings: PrimerSettings

    init(settings: PrimerSettings) {
        self.container = Container()
        self.settings = settings
    }

    /// Configure and register all dependencies for CheckoutComponents.
    func configure() async {
        // Starting CheckoutComponents DI configuration

        // Register core infrastructure
        await registerInfrastructure()

        // Register validation system
        await registerValidation()

        // Register domain layer
        await registerDomain()

        // Register data layer
        await registerData()

        // Register presentation layer
        await registerPresentation()

        // Set as global container
        await DIContainer.setContainer(container)

        // DI configuration completed

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
        // Registering infrastructure

        // Settings service
        await CheckoutComponentsSettingsService.register(in: container, with: settings)

        // Settings observer for dynamic updates
        await SettingsObserver.register(in: container, with: settings)

        // Design tokens manager
        _ = try? await container.register(DesignTokensManager.self)
            .asSingleton()
            .with { _ in DesignTokensManager() }
    }

    /// Register validation framework.
    func registerValidation() async {
        // Registering validation

        // Rules factory
        _ = try? await container.register(RulesFactory.self)
            .asSingleton()
            .with { _ in DefaultRulesFactory() }

        // Validation service
        _ = try? await container.register(ValidationService.self)
            .asSingleton()
            .with { resolver in
                let factory = try await resolver.resolve(RulesFactory.self)
                return DefaultValidationService(rulesFactory: factory)
            }
    }

    /// Register domain layer (interactors, models).
    func registerDomain() async {
        // Registering domain layer

        // Register interactors
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
        // Registering data layer

        // Register repository
        _ = try? await container.register(HeadlessRepository.self)
            .asSingleton()
            .with { _ in HeadlessRepositoryImpl() }

        // Register mapper
        _ = try? await container.register(PaymentMethodMapper.self)
            .asSingleton()
            .with { _ in PaymentMethodMapperImpl() }
    }

    /// Register presentation layer (scopes, view models).
    func registerPresentation() async {
        // Registering presentation layer
    }

    #if DEBUG
    /// Perform health check on the container.
    func performHealthCheck() async {
        // Performing health check

        let diagnostics = await container.getDiagnostics()
        // Total registrations: \(diagnostics.totalRegistrations)

        let healthReport = await container.performHealthCheck()
        if healthReport.status == .healthy {
            // Container is healthy
        } else {
            logger.warn(message: "Health issues: \(healthReport.issues)")
        }
    }
    #endif
}
