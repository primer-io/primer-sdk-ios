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
        print("🔍 Performing DI Container Health Checks...")

        // Get diagnostics
        let diagnostics = await container.getDiagnostics()
        print("📊 Container Diagnostics:")
        print("   - Total Registrations: \(diagnostics.totalRegistrations)")
        print("   - Singleton Instances: \(diagnostics.singletonInstances)")
        print("   - Weak References: \(diagnostics.weakReferences)")

        // Perform health check
        let healthReport = await container.performHealthCheck()
        print("🏥 Health Status: \(healthReport.status)")

        if !healthReport.issues.isEmpty {
            print("⚠️ Issues Found:")
            for issue in healthReport.issues {
                print("   - \(issue)")
            }
        }

        if !healthReport.recommendations.isEmpty {
            print("💡 Recommendations:")
            for recommendation in healthReport.recommendations {
                print("   - \(recommendation)")
            }
        }

        // Test key dependency resolutions
        await testKeyDependencies(container: container)
    }

    private static func testKeyDependencies(container: Container) async {
        print("🧪 Testing Key Dependency Resolutions...")

        // Test ValidationService resolution
        do {
            _ = try await container.resolve(ValidationService.self)
            print("✅ ValidationService resolution successful")
        } catch {
            print("❌ ValidationService resolution failed: \(error)")
        }

        // Test PaymentMethodsProvider resolution
        do {
            _ = try await container.resolve(PaymentMethodsProvider.self)
            print("✅ PaymentMethodsProvider resolution successful")
        } catch {
            print("❌ PaymentMethodsProvider resolution failed: \(error)")
        }

        // Test CardViewModel resolution
        do {
            _ = try await container.resolve(CardViewModel.self)
            print("✅ CardViewModel resolution successful")
        } catch {
            print("❌ CardViewModel resolution failed: \(error)")
        }

        print("🎯 Health checks completed!")
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
            .asTransient() // Create a new instance each time
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
}
