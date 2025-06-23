//
//  PaymentMethodMapper.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Protocol for mapping between internal and public payment method representations.
internal protocol PaymentMethodMapper {
    /// Maps an internal payment method to the public representation.
    func mapToPublic(_ internal: InternalPaymentMethod) -> PrimerComposablePaymentMethod

    /// Maps multiple internal payment methods to public representations.
    func mapToPublic(_ internal: [InternalPaymentMethod]) -> [PrimerComposablePaymentMethod]
}

/// Default implementation of PaymentMethodMapper.
internal final class PaymentMethodMapperImpl: PaymentMethodMapper {

    func mapToPublic(_ internal: InternalPaymentMethod) -> PrimerComposablePaymentMethod {
        PrimerComposablePaymentMethod(
            id: internal.id,
            type: internal.type,
            name: internal.name,
            icon: internal.icon,
            metadata: internal.metadata
        )
    }

    func mapToPublic(_ internal: [InternalPaymentMethod]) -> [PrimerComposablePaymentMethod] {
        internal.map { mapToPublic($0) }
    }
}
