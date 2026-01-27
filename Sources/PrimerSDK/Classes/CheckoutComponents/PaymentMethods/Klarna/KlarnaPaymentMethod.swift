//
//  KlarnaPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct KlarnaPaymentMethod: PaymentMethodProtocol {

    typealias ScopeType = DefaultKlarnaScope

    static let paymentMethodType: String = PrimerPaymentMethodType.klarna.rawValue

    /// Creates a Klarna scope for this payment method
    /// - Parameters:
    ///   - checkoutScope: The parent checkout scope for navigation coordination
    ///   - diContainer: The dependency injection container used to resolve Klarna dependencies
    /// - Returns: A configured DefaultKlarnaScope instance
    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultKlarnaScope {

        guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
            throw PrimerError.invalidArchitecture(
                description: "KlarnaPaymentMethod requires DefaultCheckoutScope",
                recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
            )
        }

        let logger = PrimerLogging.shared.logger
        let availableMethodsCount = defaultCheckoutScope.availablePaymentMethods.count

        let paymentMethodContext: PresentationContext
        if availableMethodsCount > 1 {
            paymentMethodContext = .fromPaymentSelection
        } else {
            paymentMethodContext = .direct
        }

        do {
            let processKlarnaInteractor: ProcessKlarnaPaymentInteractor = try diContainer.resolveSync(ProcessKlarnaPaymentInteractor.self)
            let analyticsInteractor = try? diContainer.resolveSync(CheckoutComponentsAnalyticsInteractorProtocol.self)

            return DefaultKlarnaScope(
                checkoutScope: defaultCheckoutScope,
                presentationContext: paymentMethodContext,
                processKlarnaInteractor: processKlarnaInteractor,
                analyticsInteractor: analyticsInteractor
            )
        } catch let primerError as PrimerError {
            throw primerError
        } catch {
            logger.error(message: "Failed to resolve Klarna payment dependencies: \(error)")
            throw PrimerError.invalidArchitecture(
                description: "Required Klarna payment dependencies could not be resolved",
                recoverSuggestion: "Ensure CheckoutComponents DI registration runs before presenting Klarna."
            )
        }
    }

    /// Creates the view for Klarna payments by retrieving the Klarna scope and rendering the appropriate UI.
    /// Priority order:
    /// 1. klarnaScope.screen (scope-based customization)
    /// 2. Default KlarnaView
    /// - Parameter checkoutScope: The parent checkout scope that manages this payment method
    /// - Returns: The Klarna view, or nil if the scope cannot be retrieved
    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        guard let klarnaScope = checkoutScope.getPaymentMethodScope(DefaultKlarnaScope.self) else {
            return nil
        }

        if let customScreen = klarnaScope.screen {
            return AnyView(customScreen(klarnaScope))
        } else {
            return AnyView(KlarnaView(scope: klarnaScope))
        }
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultKlarnaScope) -> V) -> AnyView {
        fatalError("Custom content method should be implemented by the CheckoutComponents framework")
    }

    @MainActor
    func defaultContent() -> AnyView {
        fatalError("Default content method should be implemented by the CheckoutComponents framework")
    }
}

// MARK: - Registration Helper

@available(iOS 15.0, *)
extension KlarnaPaymentMethod {

    @MainActor
    static func register() {
        PaymentMethodRegistry.shared.register(KlarnaPaymentMethod.self)

        #if DEBUG
        TestKlarnaPaymentMethod.register()
        #endif
    }
}

// MARK: - Test Klarna Payment Method (DEBUG only)

#if DEBUG
@available(iOS 15.0, *)
struct TestKlarnaPaymentMethod: PaymentMethodProtocol {

    typealias ScopeType = DefaultKlarnaScope

    static let paymentMethodType: String = "PRIMER_TEST_KLARNA"

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultKlarnaScope {
        // Reuse the same scope creation as real Klarna
        try KlarnaPaymentMethod.createScope(checkoutScope: checkoutScope, diContainer: diContainer)
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        KlarnaPaymentMethod.createView(checkoutScope: checkoutScope)
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultKlarnaScope) -> V) -> AnyView {
        fatalError("Custom content method should be implemented by the CheckoutComponents framework")
    }

    @MainActor
    func defaultContent() -> AnyView {
        fatalError("Default content method should be implemented by the CheckoutComponents framework")
    }

    @MainActor
    static func register() {
        PaymentMethodRegistry.shared.register(TestKlarnaPaymentMethod.self)
    }
}
#endif
