//
//  WebRedirectPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct WebRedirectPaymentMethod: PaymentMethodProtocol {

    typealias ScopeType = DefaultWebRedirectScope

    static var paymentMethodType: String { "WEB_REDIRECT" }

    @MainActor
    static func register(types: [String]) {
        for type in types {
            PaymentMethodRegistry.shared.register(
                paymentMethodType: type,
                scopeCreator: createScope(for:checkoutScope:container:),
                viewCreator: createView(for:checkoutScope:)
            )
        }
    }

    @MainActor
    private static func createScope(
        for paymentMethodType: String,
        checkoutScope: any PrimerCheckoutScope,
        container: any ContainerProtocol
    ) throws -> DefaultWebRedirectScope {
        guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
            throw PrimerError.invalidArchitecture(
                description: "WebRedirectPaymentMethod requires DefaultCheckoutScope",
                recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
            )
        }

        // Determine presentation context
        let availableMethodsCount = defaultCheckoutScope.availablePaymentMethods.count
        let paymentMethodContext: PresentationContext = availableMethodsCount > 1
            ? .fromPaymentSelection
            : .direct

        // Get payment method info from checkout scope and map to public type
        let internalPaymentMethod = defaultCheckoutScope.availablePaymentMethods
            .first { $0.type == paymentMethodType }

        // Map internal payment method to public CheckoutPaymentMethod
        var paymentMethod: CheckoutPaymentMethod?
        if let internalMethod = internalPaymentMethod {
            let mapper = try? container.resolveSync(PaymentMethodMapper.self)
            paymentMethod = mapper?.mapToPublic(internalMethod)
        }

        let surchargeAmount = paymentMethod?.formattedSurcharge

        let processWebRedirectInteractor = try container.resolveSync(ProcessWebRedirectPaymentInteractor.self)
        let accessibilityService = try? container.resolveSync(AccessibilityAnnouncementService.self)
        let repository = try? container.resolveSync(WebRedirectRepository.self)

        return DefaultWebRedirectScope(
            paymentMethodType: paymentMethodType,
            checkoutScope: defaultCheckoutScope,
            presentationContext: paymentMethodContext,
            processWebRedirectInteractor: processWebRedirectInteractor,
            accessibilityService: accessibilityService,
            repository: repository,
            paymentMethod: paymentMethod,
            surchargeAmount: surchargeAmount
        )
    }

    @MainActor
    private static func createView(
        for paymentMethodType: String,
        checkoutScope: any PrimerCheckoutScope
    ) -> AnyView? {
        guard let webRedirectScope: DefaultWebRedirectScope = checkoutScope.getPaymentMethodScope(for: paymentMethodType) else {
            return nil
        }

        if let customScreen = webRedirectScope.screen {
            return AnyView(customScreen(webRedirectScope))
        } else {
            return AnyView(WebRedirectScreen(scope: webRedirectScope))
        }
    }

    // MARK: - PaymentMethodProtocol Conformance

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultWebRedirectScope {
        throw PrimerError.invalidArchitecture(
            description: "WebRedirectPaymentMethod.createScope requires a payment method type parameter",
            recoverSuggestion: "Use register(types:) for dynamic registration instead"
        )
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        nil
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultWebRedirectScope) -> V) -> AnyView {
        fatalError("Use register(types:) for dynamic registration instead")
    }

    @MainActor
    func defaultContent() -> AnyView {
        fatalError("Use register(types:) for dynamic registration instead")
    }

}

// MARK: - PaymentMethodRegistry Extension for Parameterized Registration

@available(iOS 15.0, *)
extension PaymentMethodRegistry {

    @MainActor
    func register(
        paymentMethodType: String,
        scopeCreator: @escaping @MainActor (String, any PrimerCheckoutScope, any ContainerProtocol) throws -> any PrimerPaymentMethodScope,
        viewCreator: @escaping @MainActor (String, any PrimerCheckoutScope) -> AnyView?
    ) {
        // Wrap the parameterized creators to match the standard signature
        let wrappedScopeCreator: @MainActor (PrimerCheckoutScope, any ContainerProtocol) throws -> any PrimerPaymentMethodScope = { checkoutScope, container in
            try scopeCreator(paymentMethodType, checkoutScope, container)
        }

        let wrappedViewCreator: @MainActor (any PrimerCheckoutScope) -> AnyView? = { checkoutScope in
            viewCreator(paymentMethodType, checkoutScope)
        }

        // Store the payment method type in the internal registrations
        registerWithType(
            paymentMethodType: paymentMethodType,
            scopeCreator: wrappedScopeCreator,
            viewCreator: wrappedViewCreator
        )
    }

    @MainActor
    private func registerWithType(
        paymentMethodType: String,
        scopeCreator: @escaping @MainActor (PrimerCheckoutScope, any ContainerProtocol) throws -> any PrimerPaymentMethodScope,
        viewCreator: @escaping @MainActor (any PrimerCheckoutScope) -> AnyView?
    ) {
        // Create a temporary type to satisfy the register method
        // This is a workaround since PaymentMethodProtocol requires a type, not an instance
        registerInternal(
            typeKey: paymentMethodType,
            scopeCreator: scopeCreator,
            viewCreator: viewCreator
        )
    }
}
