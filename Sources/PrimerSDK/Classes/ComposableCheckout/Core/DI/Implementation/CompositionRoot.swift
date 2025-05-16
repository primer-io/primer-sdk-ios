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
    }

    private static func registerValidation(in container: Container) async {
        // Validation rules
        _ = try? await container.register(CardNumberRule.self)
            .asTransient()
            .with { _ in CardNumberRule() }

        _ = try? await container.register(CardholderNameRule.self)
            .asTransient()
            .with { _ in CardholderNameRule() }

        _ = try? await container.register(CVVRule.self)
            .asTransient()
            .with { _ in CVVRule(cardNetwork: .unknown) }

        let registrationBuilder = try? await container.register(ExpiryDateRule.self)
            .asTransient()
            .with { _ in
                ExpiryDateRule()
            }

        // Main validation service
        _ = try? await container.register(ValidationService.self)
            .asTransient()
            .with { _ in
                DefaultValidationService()
            }

        // Form validator
        _ = try? await container.register(FormValidator.self)
            .asTransient()
            .with { resolver in
                CardFormValidator(
                    validationService: try await resolver.resolve(ValidationService.self)
                )
            }
    }

    private static func registerViewModels(in container: Container) async {
        // Checkout view model
        _ = try? await container.register(PrimerCheckoutViewModel.self)
            .asTransient()
            .with { _ in
                await MainActor.run {
                    PrimerCheckoutViewModel()
                }
            }

        // Card view model
        _ = try? await container.register(CardViewModel.self)
            .asTransient()
            .with { resolver in
                await CardViewModel(validationService: try await resolver.resolve(ValidationService.self))
            }
    }

    private static func registerPaymentMethods(in container: Container) async {
        // Individual payment methods
        _ = try? await container.register(CardPaymentMethod.self)
            .asTransient()
            .with { resolver in
                await CardPaymentMethod(validationService: try await resolver.resolve(ValidationService.self))
            }
    }
}
