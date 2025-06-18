//
//  CompositionRoot.swift
//
//
//  Created by Boris on 16. 5. 2025..
//

import SwiftUI
import Foundation

// CompositionRoot.swift
@available(iOS 15.0, *)
public final class CompositionRoot: LogReporter {

    public static func configure() async {
        logger.info(message: "🚀 [CompositionRoot] Starting DI container configuration")

        let container = Container()
        logger.debug(message: "🏗️ [CompositionRoot] Container created")

        logger.debug(message: "🔧 [CompositionRoot] Registering infrastructure...")
        await registerInfrastructure(in: container)

        logger.debug(message: "✅ [CompositionRoot] Registering validation...")
        await registerValidation(in: container)

        logger.debug(message: "🧩 [CompositionRoot] Registering components...")
        await registerComponents(in: container)

        logger.debug(message: "🎯 [CompositionRoot] Registering view models...")
        await registerViewModels(in: container)

        logger.debug(message: "💳 [CompositionRoot] Registering payment methods...")
        await registerPaymentMethods(in: container)

        logger.debug(message: "🧭 [CompositionRoot] Registering navigation...")
        await registerNavigation(in: container)

        logger.debug(message: "🎯 [CompositionRoot] Registering new API scopes...")
        await registerNewAPIScopes(in: container)

        logger.debug(message: "🏗️ [CompositionRoot] Registering Clean Architecture layers...")
        await registerCleanArchitecture(in: container)

        // Set as global container
        logger.debug(message: "🌍 [CompositionRoot] Setting global container...")
        await DIContainer.setContainer(container)
        logger.info(message: "✅ [CompositionRoot] DI container configuration completed")

        // Perform health checks in debug builds
        #if DEBUG
        logger.debug(message: "🏥 [CompositionRoot] Performing health checks...")
        await performHealthChecks(container: container)
        #endif
    }

    #if DEBUG
    private static func performHealthChecks(container: Container) async {
        logger.debug(message: "🔍 [CompositionRoot] Performing DI Container Health Checks...")

        // Get diagnostics
        let diagnostics = await container.getDiagnostics()
        logger.debug(message: "📊 [CompositionRoot] Container Diagnostics: \(diagnostics.totalRegistrations) registrations, \(diagnostics.singletonInstances) singletons, \(diagnostics.weakReferences) weak refs")

        // Perform health check
        let healthReport = await container.performHealthCheck()
        logger.debug(message: "🏥 [CompositionRoot] Health Status: \(healthReport.status)")

        if !healthReport.issues.isEmpty {
            logger.warn(message: "⚠️ [CompositionRoot] DI Issues: \(healthReport.issues.count) found")
        }

        // Test key dependency resolutions
        await testKeyDependencies(container: container)
    }

    private static func testKeyDependencies(container: Container) async {
        logger.debug(message: "🧪 [CompositionRoot] Testing key dependency resolutions...")

        // Test ValidationService resolution
        do {
            _ = try await container.resolve(ValidationService.self)
            logger.debug(message: "✅ [CompositionRoot] ValidationService resolution successful")
        } catch {
            logger.error(message: "❌ [CompositionRoot] ValidationService resolution failed: \(error.localizedDescription)")
        }

        // Test PaymentMethodsProvider resolution
        do {
            _ = try await container.resolve(PaymentMethodsProvider.self)
            logger.debug(message: "✅ [CompositionRoot] PaymentMethodsProvider resolution successful")
        } catch {
            logger.error(message: "❌ [CompositionRoot] PaymentMethodsProvider resolution failed: \(error.localizedDescription)")
        }

        // Test CardViewModel resolution
        do {
            _ = try await container.resolve(CardViewModel.self)
            logger.debug(message: "✅ [CompositionRoot] CardViewModel resolution successful")
        } catch {
            logger.error(message: "❌ [CompositionRoot] CardViewModel resolution failed: \(error.localizedDescription)")
        }

        // Test new API ViewModels
        do {
            _ = try await container.resolve(CheckoutViewModel.self)
            logger.debug(message: "✅ [CompositionRoot] CheckoutViewModel resolution successful")
        } catch {
            logger.error(message: "❌ [CompositionRoot] CheckoutViewModel resolution failed: \(error.localizedDescription)")
        }

        do {
            _ = try await container.resolve(CardFormViewModel.self)
            logger.debug(message: "✅ [CompositionRoot] CardFormViewModel resolution successful")
        } catch {
            logger.error(message: "❌ [CompositionRoot] CardFormViewModel resolution failed: \(error.localizedDescription)")
        }

        do {
            _ = try await container.resolve(PaymentMethodSelectionViewModel.self)
            logger.debug(message: "✅ [CompositionRoot] PaymentMethodSelectionViewModel resolution successful")
        } catch {
            logger.error(message: "❌ [CompositionRoot] PaymentMethodSelectionViewModel resolution failed: \(error.localizedDescription)")
        }

        logger.debug(message: "🎯 [CompositionRoot] Health checks completed")
    }
    #endif
}

// MARK: - Registration Categories
@available(iOS 15.0, *)
extension CompositionRoot {

    private static func registerInfrastructure(in container: Container) async {
        // Design tokens manager
        _ = try? await container.register(DesignTokensManager.self)
            .asSingleton()
            .with { _ in DesignTokensManager() }

        _ = try? await container.register(TaskManager.self)
            .asSingleton()
            .with { _ in TaskManager() }

    }

    // swiftlint:disable:next function_body_length
    private static func registerValidation(in container: Container) async {
        // Register the rules factory as singleton for reuse
        _ = try? await container.register(RulesFactory.self)
            .asSingleton()
            .with { _ in RulesFactory() }

        // Main validation service
        _ = try? await container.register(ValidationService.self)
            .asSingleton()
            .with { resolver in
                let factory = try await resolver.resolve(RulesFactory.self)
                return DefaultValidationService(rulesFactory: factory)
            }

        // Form validator
        _ = try? await container.register(FormValidator.self)
            .asTransient()
            .with { resolver in
                CardFormValidator(
                    validationService: try await resolver.resolve(ValidationService.self)
                )
            }

        // Register individual validators
        _ = try? await container.register(CardNumberValidator.self)
            .asTransient()
            .with { resolver in
                CardNumberValidator(
                    validationService: try await resolver.resolve(ValidationService.self),
                    onValidationChange: { _ in }, // Will be set by consumers
                    onErrorMessageChange: { _ in }
                )
            }

        _ = try? await container.register(CVVValidator.self)
            .asTransient()
            .with { resolver in
                CVVValidator(
                    validationService: try await resolver.resolve(ValidationService.self),
                    cardNetwork: .unknown, // Will be updated by consumers
                    onValidationChange: { _ in },
                    onErrorMessageChange: { _ in }
                )
            }

        _ = try? await container.register(ExpiryDateValidator.self)
            .asTransient()
            .with { resolver in
                ExpiryDateValidator(
                    validationService: try await resolver.resolve(ValidationService.self),
                    onValidationChange: { _ in },
                    onErrorMessageChange: { _ in },
                    onMonthChange: { _ in },
                    onYearChange: { _ in }
                )
            }

        _ = try? await container.register(CardholderNameValidator.self)
            .asTransient()
            .with { resolver in
                CardholderNameValidator(
                    validationService: try await resolver.resolve(ValidationService.self),
                    onValidationChange: { _ in },
                    onErrorMessageChange: { _ in }
                )
            }
    }

    // swiftlint:disable:next function_body_length
    private static func registerViewModels(in container: Container) async {
        // Checkout view model
        _ = try? await container.register(PrimerCheckoutViewModel.self)
            .asSingleton() // Keep the same instance with loaded payment methods
            .with { resolver in
                // Resolve dependencies
                let taskManager = (try? await resolver.resolve(TaskManager.self)) ?? TaskManager()
                let paymentMethodsProvider = (try? await resolver.resolve(PaymentMethodsProvider.self)) ??
                    DefaultPaymentMethodsProvider(container: container)

                return await MainActor.run {
                    return PrimerCheckoutViewModel(
                        taskManager: taskManager,
                        paymentMethodsProvider: paymentMethodsProvider
                    )
                }
            }

        // Card view model
        _ = try? await container.register(CardViewModel.self)
            .asTransient()
            .with { resolver in
                let validationService = (try? await resolver.resolve(ValidationService.self)) ??
                    DefaultValidationService(rulesFactory: RulesFactory())
                let formValidator = (try? await resolver.resolve(FormValidator.self)) ??
                    CardFormValidator(validationService: validationService)

                // Create validators with callback placeholders (will be set up in CardViewModel)
                let cardNumberValidator = (try? await resolver.resolve(CardNumberValidator.self)) ??
                    CardNumberValidator(
                        validationService: validationService,
                        onValidationChange: { _ in },
                        onErrorMessageChange: { _ in }
                    )
                let cvvValidator = (try? await resolver.resolve(CVVValidator.self)) ??
                    CVVValidator(
                        validationService: validationService,
                        cardNetwork: .unknown,
                        onValidationChange: { _ in },
                        onErrorMessageChange: { _ in }
                    )
                let expiryDateValidator = (try? await resolver.resolve(ExpiryDateValidator.self)) ??
                    ExpiryDateValidator(
                        validationService: validationService,
                        onValidationChange: { _ in },
                        onErrorMessageChange: { _ in },
                        onMonthChange: { _ in },
                        onYearChange: { _ in }
                    )
                let cardholderNameValidator = (try? await resolver.resolve(CardholderNameValidator.self)) ??
                    CardholderNameValidator(
                        validationService: validationService,
                        onValidationChange: { _ in },
                        onErrorMessageChange: { _ in }
                    )

                return await MainActor.run {
                    return CardViewModel(
                        validationService: validationService,
                        formValidator: formValidator,
                        cardNumberValidator: cardNumberValidator,
                        cvvValidator: cvvValidator,
                        expiryDateValidator: expiryDateValidator,
                        cardholderNameValidator: cardholderNameValidator
                    )
                }
            }

        // Payment methods list view model
        _ = try? await container.register(PaymentMethodsListViewModel.self)
            .asTransient()
            .with { _ in
                return await MainActor.run {
                    return PaymentMethodsListViewModel()
                }
            }

        // Navigation screen view models
        _ = try? await container.register(SplashViewModel.self)
            .asTransient()
            .with { container in
                try await SplashViewModel.create(container: container)
            }

        _ = try? await container.register(PaymentMethodsListScreenViewModel.self)
            .asTransient()
            .with { container in
                try await PaymentMethodsListScreenViewModel.create(container: container)
            }

        _ = try? await container.register(PaymentMethodScreenViewModel.self)
            .asTransient()
            .with { container in
                try await PaymentMethodScreenViewModel.create(container: container)
            }

        _ = try? await container.register(ResultScreenViewModel.self)
            .asTransient()
            .with { container in
                try await ResultScreenViewModel.create(container: container)
            }
    }

    private static func registerComponents(in container: Container) async {
        // Register payment methods provider
        _ = try? await container.register(PaymentMethodsProvider.self)
            .asSingleton()
            .with { _ in
                DefaultPaymentMethodsProvider(container: container)
            }

        // Register input field components with their dependencies
        // Note: These registrations are primarily for factories or scenarios where
        // components need to be created programmatically. Most of the time,
        // views will resolve dependencies directly from the environment.
    }

    private static func registerPaymentMethods(in container: Container) async {
        logger.info(message: "💳 [CompositionRoot] Starting payment methods registration")

        // Register ALL payment method implementations with the same protocol

        // Card payment - use actual implementation
        logger.debug(message: "🃏 [CompositionRoot] Registering card payment method...")
        do {
            _ = try await container.register((any PaymentMethodProtocol).self)
                .named("card")  // Names help distinguish between implementations
                .asSingleton()  // Use singleton so resolveAll can find it
                .with { _ in
                    logger.debug(message: "🏭 [CompositionRoot] Creating CardPaymentMethod instance")
                    let cardMethod = try await CardPaymentMethod()
                    logger.info(message: "✅ [CompositionRoot] CardPaymentMethod created successfully")
                    return cardMethod
                }
            logger.info(message: "✅ [CompositionRoot] Card payment method registered successfully")
        } catch {
            logger.error(message: "🚨 [CompositionRoot] Failed to register card payment method: \(error.localizedDescription)")
        }

        //        // Apple Pay
        //        _ = try? await container.register((any PaymentMethodProtocol).self)
        //            .named("apple_pay")
        //            .asTransient()
        //            .with { resolver in
        //                return await ApplePayPaymentMethod()
        //            }
        //
        //        // PayPal
        //        _ = try? await container.register((any PaymentMethodProtocol).self)
        //            .named("paypal")
        //            .asTransient()
        //            .with { resolver in
        //                return await PayPalPaymentMethod()
        //            }

        // Easily add new payment methods by just registering them here
        // No need to modify the ViewModel!

        logger.info(message: "✅ [CompositionRoot] Payment methods registration completed")
    }

    @available(iOS 15.0, *)
    private static func registerNavigation(in container: Container) async {
        logger.info(message: "🧭 [CompositionRoot] Starting navigation registration")

        // Register CheckoutCoordinator directly in the main container
        do {
            _ = try await container.register(CheckoutCoordinator.self)
                .asSingleton()
                .with { container in
                    try await CheckoutCoordinator.create(container: container)
                }
            logger.info(message: "✅ [CompositionRoot] CheckoutCoordinator registered successfully")
        } catch {
            logger.error(message: "🚨 [CompositionRoot] Failed to register CheckoutCoordinator: \(error.localizedDescription)")
        }

        logger.info(message: "✅ [CompositionRoot] Navigation registration completed")
    }

    /// Register new API scope implementations for the refactored public API
    @available(iOS 15.0, *)
    private static func registerNewAPIScopes(in container: Container) async {
        logger.info(message: "🎯 [CompositionRoot] Starting new API scopes registration")

        // Register the new ViewModel implementations that implement the scope protocols
        
        // CheckoutViewModel - implements PrimerCheckoutScope
        _ = try? await container.register(CheckoutViewModel.self)
            .asTransient()
            .with { container in
                return try await CheckoutViewModel(container: container)
            }
        
        // CardFormViewModel - implements CardFormScope
        _ = try? await container.register(CardFormViewModel.self)
            .asTransient()
            .with { container in
                let validationService = try await container.resolve(ValidationService.self, name: nil)
                return try await CardFormViewModel(
                    container: container,
                    validationService: validationService
                )
            }
            
        // PaymentMethodSelectionViewModel - implements PaymentMethodSelectionScope
        _ = try? await container.register(PaymentMethodSelectionViewModel.self)
            .asTransient()
            .with { container in
                return try await PaymentMethodSelectionViewModel(container: container)
            }

        // Register protocol implementations using the new ViewModels
        _ = try? await container.register((any PrimerCheckoutScope).self)
            .asTransient()
            .with { resolver in
                try await resolver.resolve(CheckoutViewModel.self)
            }
            
        _ = try? await container.register((any CardFormScope).self)
            .asTransient()
            .with { resolver in
                try await resolver.resolve(CardFormViewModel.self)
            }
            
        _ = try? await container.register((any PaymentMethodSelectionScope).self)
            .asTransient()
            .with { resolver in
                try await resolver.resolve(PaymentMethodSelectionViewModel.self)
            }

        logger.info(message: "✅ [CompositionRoot] New API scopes registration completed")
        logger.debug(message: "📝 [CompositionRoot] Using proper ViewModel implementations that implement scope protocols")
    }

    /// Register Clean Architecture layers (Services, Repositories, Interactors)
    /// Preserves existing DI container, validation system, and design tokens
    @available(iOS 15.0, *)
    private static func registerCleanArchitecture(in container: Container) async {
        logger.info(message: "🏗️ [CompositionRoot] Starting Clean Architecture registration")
        
        // Register Services (Data Layer - adapters to existing SDK)
        await registerServices(in: container)
        
        // Register Repositories (Data Layer - abstract data sources)
        await registerRepositories(in: container)
        
        // Register Interactors (Domain Layer - business logic use cases)
        await registerInteractors(in: container)
        
        logger.info(message: "✅ [CompositionRoot] Clean Architecture registration completed")
    }
    
    /// Register Service layer that integrates with existing SDK
    @available(iOS 15.0, *)
    private static func registerServices(in container: Container) async {
        logger.debug(message: "🔧 [CompositionRoot] Registering Services...")
        
        // Configuration Service
        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in 
                logger.debug(message: "🏭 [CompositionRoot] Creating ConfigurationService")
                return ConfigurationServiceImpl() 
            }
        
        // Payment Method Service
        _ = try? await container.register(PaymentMethodService.self)
            .asSingleton()
            .with { _ in 
                logger.debug(message: "🏭 [CompositionRoot] Creating PaymentMethodService")
                return PaymentMethodServiceImpl() 
            }
        
        // Payment Service
        _ = try? await container.register(PaymentService.self)
            .asSingleton()
            .with { _ in 
                logger.debug(message: "🏭 [CompositionRoot] Creating PaymentService")
                return PaymentServiceImpl() 
            }
        
        // Tokenization Service
        _ = try? await container.register(ComposableTokenizationService.self)
            .asSingleton()
            .with { _ in 
                logger.debug(message: "🏭 [CompositionRoot] Creating ComposableTokenizationService")
                return ComposableTokenizationServiceImpl() 
            }
        
        logger.debug(message: "✅ [CompositionRoot] Services registration completed")
    }
    
    /// Register Repository layer
    @available(iOS 15.0, *)
    private static func registerRepositories(in container: Container) async {
        logger.debug(message: "📚 [CompositionRoot] Registering Repositories...")
        
        // Configuration Repository
        _ = try? await container.register(ConfigurationRepository.self)
            .asSingleton()
            .with { resolver in
                logger.debug(message: "🏭 [CompositionRoot] Creating ConfigurationRepository")
                return ConfigurationRepositoryImpl(
                    configurationService: try await resolver.resolve(ConfigurationService.self)
                )
            }
        
        // Payment Method Repository
        _ = try? await container.register(PaymentMethodRepository.self)
            .asSingleton()
            .with { resolver in
                logger.debug(message: "🏭 [CompositionRoot] Creating PaymentMethodRepository")
                return PaymentMethodRepositoryImpl(
                    paymentMethodService: try await resolver.resolve(PaymentMethodService.self)
                )
            }
        
        // Payment Repository
        _ = try? await container.register(PaymentRepository.self)
            .asSingleton()
            .with { resolver in
                logger.debug(message: "🏭 [CompositionRoot] Creating PaymentRepository")
                return PaymentRepositoryImpl(
                    paymentService: try await resolver.resolve(PaymentService.self)
                )
            }
        
        // Tokenization Repository
        _ = try? await container.register(TokenizationRepository.self)
            .asSingleton()
            .with { resolver in
                logger.debug(message: "🏭 [CompositionRoot] Creating TokenizationRepository")
                return TokenizationRepositoryImpl(
                    tokenizationService: try await resolver.resolve(ComposableTokenizationService.self)
                )
            }
        
        logger.debug(message: "✅ [CompositionRoot] Repositories registration completed")
    }
    
    /// Register Interactor layer (Use Cases)
    @available(iOS 15.0, *)
    private static func registerInteractors(in container: Container) async {
        logger.debug(message: "🎯 [CompositionRoot] Registering Interactors...")
        
        // Initialize Checkout Interactor
        _ = try? await container.register(InitializeCheckoutInteractor.self)
            .asTransient()
            .with { resolver in
                logger.debug(message: "🏭 [CompositionRoot] Creating InitializeCheckoutInteractor")
                return InitializeCheckoutInteractorImpl(
                    configurationRepository: try await resolver.resolve(ConfigurationRepository.self),
                    paymentMethodRepository: try await resolver.resolve(PaymentMethodRepository.self)
                )
            }
        
        // Process Card Payment Interactor
        _ = try? await container.register(ProcessCardPaymentInteractor.self)
            .asTransient()
            .with { resolver in
                logger.debug(message: "🏭 [CompositionRoot] Creating ProcessCardPaymentInteractor")
                return ProcessCardPaymentInteractorImpl(
                    paymentRepository: try await resolver.resolve(PaymentRepository.self),
                    tokenizationRepository: try await resolver.resolve(TokenizationRepository.self)
                )
            }
        
        // Get Payment Methods Interactor
        _ = try? await container.register(GetPaymentMethodsInteractor.self)
            .asTransient()
            .with { resolver in
                logger.debug(message: "🏭 [CompositionRoot] Creating GetPaymentMethodsInteractor")
                return GetPaymentMethodsInteractorImpl(
                    paymentMethodRepository: try await resolver.resolve(PaymentMethodRepository.self)
                )
            }
        
        // Validate Payment Data Interactor (uses existing validation system)
        _ = try? await container.register(ValidatePaymentDataInteractor.self)
            .asTransient()
            .with { resolver in
                logger.debug(message: "🏭 [CompositionRoot] Creating ValidatePaymentDataInteractor")
                return ValidatePaymentDataInteractorImpl(
                    validationService: try await resolver.resolve(ValidationService.self)
                )
            }
        
        logger.debug(message: "✅ [CompositionRoot] Interactors registration completed")
    }
}
