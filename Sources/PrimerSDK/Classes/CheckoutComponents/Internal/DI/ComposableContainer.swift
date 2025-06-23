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

    init() {
        self.container = Container()
    }

    /// Configure and register all dependencies for CheckoutComponents.
    func configure() async {
        logger.info(message: "🚀 [ComposableContainer] Starting CheckoutComponents DI configuration")

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

        logger.info(message: "✅ [ComposableContainer] DI configuration completed")

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
        logger.debug(message: "🔧 [ComposableContainer] Registering infrastructure...")

        // Design tokens manager
        _ = try? await container.register(DesignTokensManager.self)
            .asSingleton()
            .with { _ in DesignTokensManager() }
    }

    /// Register validation framework.
    func registerValidation() async {
        logger.debug(message: "✅ [ComposableContainer] Registering validation...")

        // Rules factory
        // Skip RulesFactory for now
        // _ = try? await container.register(RulesFactory.self)
        //     .asSingleton()
        //     .with { _ in RulesFactory() }

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
        logger.debug(message: "🎯 [ComposableContainer] Registering domain layer...")

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

        _ = try? await container.register(TokenizeCardInteractor.self)
            .asTransient()
            .with { resolver in
                TokenizeCardInteractorImpl(
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
    }

    /// Register data layer (repositories, mappers).
    func registerData() async {
        logger.debug(message: "📚 [ComposableContainer] Registering data layer...")

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
        logger.debug(message: "🎨 [ComposableContainer] Registering presentation layer...")

        // Scope implementations will be registered here in Phase 5
        // Examples:
        // - DefaultCheckoutScope (implements PrimerCheckoutScope)
        // - DefaultCardFormScope (implements PrimerCardFormScope)
        // - DefaultPaymentMethodSelectionScope
        // - DefaultSelectCountryScope
    }

    #if DEBUG
    /// Perform health check on the container.
    func performHealthCheck() async {
        logger.debug(message: "🏥 [ComposableContainer] Performing health check...")

        let diagnostics = await container.getDiagnostics()
        logger.debug(message: "📊 [ComposableContainer] Registrations: \(diagnostics.totalRegistrations)")

        let healthReport = await container.performHealthCheck()
        if healthReport.status == .healthy {
            logger.info(message: "✅ [ComposableContainer] Container is healthy")
        } else {
            logger.warn(message: "⚠️ [ComposableContainer] Health issues: \(healthReport.issues)")
        }
    }
    #endif
}
