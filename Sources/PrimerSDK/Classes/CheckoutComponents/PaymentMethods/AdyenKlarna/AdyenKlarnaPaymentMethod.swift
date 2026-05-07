//
//  AdyenKlarnaPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AdyenKlarnaPaymentMethod: PaymentMethodProtocol {

    static let paymentMethodType: String = PrimerPaymentMethodType.adyenKlarna.rawValue

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) async throws -> any PrimerPaymentMethodScope {

        let (defaultCheckoutScope, paymentMethodContext) = try DefaultCheckoutScope.validated(from: checkoutScope)

        do {
            let interactor = try await diContainer.resolve(ProcessAdyenKlarnaPaymentInteractor.self)
            let accessibilityService = try? await diContainer.resolve(AccessibilityAnnouncementService.self)
            let analyticsInteractor = try? await diContainer.resolve(CheckoutComponentsAnalyticsInteractorProtocol.self)
            let repository = try? await diContainer.resolve(AdyenKlarnaRepository.self)

            let mapper = try? await diContainer.resolve(PaymentMethodMapper.self)
            let paymentMethod: CheckoutPaymentMethod? = defaultCheckoutScope.availablePaymentMethods
                .first { $0.type == paymentMethodType }
                .flatMap { mapper?.mapToPublic($0) }

            return DefaultAdyenKlarnaScope(
                checkoutScope: defaultCheckoutScope,
                presentationContext: paymentMethodContext,
                interactor: interactor,
                accessibilityService: accessibilityService,
                analyticsInteractor: analyticsInteractor,
                repository: repository,
                paymentMethod: paymentMethod,
                surchargeAmount: paymentMethod?.formattedSurcharge
            )
        } catch let primerError as PrimerError {
            throw primerError
        } catch {
            PrimerLogging.shared.logger.error(
                message: "Failed to resolve Adyen Klarna payment dependencies: \(error)")
            throw PrimerError.invalidArchitecture(
                description: "Required Adyen Klarna payment dependencies could not be resolved",
                recoverSuggestion:
                    "Ensure CheckoutComponents DI registration runs before presenting Adyen Klarna."
            )
        }
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        guard let adyenKlarnaScope = checkoutScope.getPaymentMethodScope(PrimerAdyenKlarnaScope.self) else {
            PrimerLogging.shared.logger.error(message: "Failed to retrieve Adyen Klarna scope from checkout scope")
            return nil
        }

        return adyenKlarnaScope.screen.map { AnyView($0(adyenKlarnaScope)) }
            ?? AnyView(AdyenKlarnaScreen(scope: adyenKlarnaScope))
    }
}

@available(iOS 15.0, *)
extension AdyenKlarnaPaymentMethod {

    @MainActor
    static func register() {
        PaymentMethodRegistry.shared.register(
            forKey: paymentMethodType,
            scopeCreator: { try await createScope(checkoutScope: $0, diContainer: $1) },
            viewCreator: { createView(checkoutScope: $0) }
        )
    }
}
