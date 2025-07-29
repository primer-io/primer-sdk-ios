//
//  PaymentMethodMapper.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation
import UIKit

/// Protocol for mapping between internal and public payment method representations.
internal protocol PaymentMethodMapper {
    /// Maps an internal payment method to the public representation.
    func mapToPublic(_ internalMethod: InternalPaymentMethod) -> PrimerComposablePaymentMethod

    /// Maps multiple internal payment methods to public representations.
    func mapToPublic(_ internalMethods: [InternalPaymentMethod]) -> [PrimerComposablePaymentMethod]
}

/// Default implementation of PaymentMethodMapper.
internal final class PaymentMethodMapperImpl: PaymentMethodMapper {

    func mapToPublic(_ internalMethod: InternalPaymentMethod) -> PrimerComposablePaymentMethod {
        let formattedSurcharge = formatSurcharge(internalMethod.surcharge, hasUnknownSurcharge: internalMethod.hasUnknownSurcharge)

        // Debug logging for surcharge mapping

        return PrimerComposablePaymentMethod(
            id: internalMethod.id,
            type: internalMethod.type,
            name: internalMethod.name,
            icon: internalMethod.icon,
            metadata: internalMethod.metadata,
            surcharge: internalMethod.surcharge,
            hasUnknownSurcharge: internalMethod.hasUnknownSurcharge,
            formattedSurcharge: formattedSurcharge,
            backgroundColor: internalMethod.backgroundColor
        )
    }

    func mapToPublic(_ internalMethods: [InternalPaymentMethod]) -> [PrimerComposablePaymentMethod] {
        return internalMethods.map { mapToPublic($0) }
    }

    /// Format surcharge for display
    private func formatSurcharge(_ surcharge: Int?, hasUnknownSurcharge: Bool) -> String? {

        // Priority: unknown surcharge > actual surcharge > no fee
        if hasUnknownSurcharge {
            return "Fee may apply"
        }

        guard let surcharge = surcharge,
              surcharge > 0,
              let currency = AppState.current.currency else {
            return "No additional fee"
        }

        // Use existing currency formatting extension to match Drop-in/Headless behavior
        let formatted = surcharge.toCurrencyString(currency: currency)
        let result = "+\(formatted)" // "+" prefix for surcharges
        return result
    }
}
