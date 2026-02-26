//
//  FormRedirectPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Shared scope creation and view logic for form-based redirect payments (BLIK, MBWay).
@available(iOS 15.0, *)
enum FormRedirectPaymentMethodHelper {

    @MainActor
    static func createScopeForPaymentMethodType(
        _ paymentMethodType: String,
        checkoutScope: DefaultCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultFormRedirectScope {
        let logger = PrimerLogging.shared.logger

        let availableMethodsCount = checkoutScope.availablePaymentMethods.count

        let paymentMethodContext: PresentationContext = if availableMethodsCount > 1 {
            .fromPaymentSelection
        } else {
            .direct
        }

        do {
            let processPaymentInteractor: ProcessFormRedirectPaymentInteractor = try diContainer.resolveSync(
                ProcessFormRedirectPaymentInteractor.self
            )
            let validationService: ValidationService = try diContainer.resolveSync(
                ValidationService.self
            )
            let analyticsInteractor = try? diContainer.resolveSync(
                CheckoutComponentsAnalyticsInteractorProtocol.self
            )

            return DefaultFormRedirectScope(
                paymentMethodType: paymentMethodType,
                checkoutScope: checkoutScope,
                presentationContext: paymentMethodContext,
                processPaymentInteractor: processPaymentInteractor,
                validationService: validationService,
                analyticsInteractor: analyticsInteractor
            )
        } catch let primerError as PrimerError {
            throw primerError
        } catch {
            logger.error(
                message: "[FormRedirectPaymentMethod] Failed to resolve dependencies for \(paymentMethodType): \(error)"
            )
            throw PrimerError.invalidArchitecture(
                description: "Required form redirect payment dependencies could not be resolved",
                recoverSuggestion: "Ensure CheckoutComponents DI registration runs before presenting form redirect."
            )
        }
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        guard let formRedirectScope = checkoutScope.getPaymentMethodScope(DefaultFormRedirectScope.self) else {
            return nil
        }

        if let customScreen = formRedirectScope.screen {
            return AnyView(customScreen(formRedirectScope))
        } else {
            return AnyView(FormRedirectContainerView(scope: formRedirectScope))
        }
    }
}

// MARK: - Container View

@available(iOS 15.0, *)
private struct FormRedirectContainerView: View {

    @ObservedObject var scope: DefaultFormRedirectScope
    @State private var currentState: FormRedirectState = FormRedirectState()

    var body: some View {
        Group {
            switch currentState.status {
            case .awaitingExternalCompletion:
                FormRedirectPendingScreen(scope: scope, state: currentState)
            default:
                FormRedirectScreen(scope: scope, state: currentState)
            }
        }
        .task {
            for await state in scope.state {
                currentState = state
            }
        }
    }
}

// MARK: - BLIK Payment Method

@available(iOS 15.0, *)
struct BlikPaymentMethod: PaymentMethodProtocol {
    typealias ScopeType = DefaultFormRedirectScope

    static let paymentMethodType: String = PrimerPaymentMethodType.adyenBlik.rawValue

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultFormRedirectScope {
        guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
            throw PrimerError.invalidArchitecture(
                description: "BlikPaymentMethod requires DefaultCheckoutScope",
                recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
            )
        }

        return try FormRedirectPaymentMethodHelper.createScopeForPaymentMethodType(
            paymentMethodType,
            checkoutScope: defaultCheckoutScope,
            diContainer: diContainer
        )
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        FormRedirectPaymentMethodHelper.createView(checkoutScope: checkoutScope)
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultFormRedirectScope) -> V) -> AnyView {
        fatalError("Custom content method should be implemented by the CheckoutComponents framework")
    }

    @MainActor
    func defaultContent() -> AnyView {
        fatalError("Default content method should be implemented by the CheckoutComponents framework")
    }
}

// MARK: - MBWay Payment Method

@available(iOS 15.0, *)
struct MBWayPaymentMethod: PaymentMethodProtocol {
    typealias ScopeType = DefaultFormRedirectScope

    static let paymentMethodType: String = PrimerPaymentMethodType.adyenMBWay.rawValue

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultFormRedirectScope {
        guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
            throw PrimerError.invalidArchitecture(
                description: "MBWayPaymentMethod requires DefaultCheckoutScope",
                recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
            )
        }

        return try FormRedirectPaymentMethodHelper.createScopeForPaymentMethodType(
            paymentMethodType,
            checkoutScope: defaultCheckoutScope,
            diContainer: diContainer
        )
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        FormRedirectPaymentMethodHelper.createView(checkoutScope: checkoutScope)
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultFormRedirectScope) -> V) -> AnyView {
        fatalError("Custom content method should be implemented by the CheckoutComponents framework")
    }

    @MainActor
    func defaultContent() -> AnyView {
        fatalError("Default content method should be implemented by the CheckoutComponents framework")
    }
}

// MARK: - Registration Helper

@available(iOS 15.0, *)
enum FormRedirectPaymentMethod {

    @MainActor
    static func registerBlik() {
        PaymentMethodRegistry.shared.register(BlikPaymentMethod.self)
    }

    @MainActor
    static func registerMBWay() {
        PaymentMethodRegistry.shared.register(MBWayPaymentMethod.self)
    }

    @MainActor
    static func register() {
        registerBlik()
        registerMBWay()
    }
}
