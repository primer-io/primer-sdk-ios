//
//  CompositionRoot.swift
//
//
//  Created by Boris on 16. 5. 2025..
//

// CompositionRoot.swift
@available(iOS 15.0, *)
public final class CompositionRoot {

    public static func configure() async {
        let container = Container()
        await registerInfrastructure(in: container)
        await registerValidation(in: container)
        await registerComponents(in: container)
        await registerViewModels(in: container)
        await registerPaymentMethods(in: container)

        // Set as global container
        await DIContainer.setContainer(container)
    }
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


    private static func registerViewModels(in container: Container) async {
        // Checkout view model
        _ = try? await container.register(PrimerCheckoutViewModel.self)
            .asTransient() // Create a new instance each time
            .with { resolver in
                await MainActor.run {
                    // Resolve dependencies
                    let taskManager = try? await resolver.resolve(TaskManager.self)
                        ?? TaskManager() // Fallback

                    return PrimerCheckoutViewModel(taskManager: taskManager)
                }
            }

        // Card view model
        _ = try? await container.register(CardViewModel.self)
            .asTransient()
            .with { resolver in
                await CardViewModel(validationService: try await resolver.resolve(ValidationService.self))
            }
    }

    private static func registerComponents(in container: Container) async {
        // Register input field components with their dependencies
        // Note: These registrations are primarily for factories or scenarios where
        // components need to be created programmatically. Most of the time,
        // views will resolve dependencies directly from the environment.
    }

    private static func registerPaymentMethods(in container: Container) async {
        // Register ALL payment method implementations with the same protocol

        // Card payment
        _ = try? await container.register((any PaymentMethodProtocol).self)
            .named("card")  // Names help distinguish between implementations
            .asTransient()
            .with { resolver in
                let validationService = try await resolver.resolve(ValidationService.self)
                return await CardPaymentMethod(validationService: validationService)
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
    }
}
