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
        return PrimerComposablePaymentMethod(
            id: internalMethod.id,
            type: internalMethod.type,
            name: internalMethod.name,
            icon: internalMethod.icon,
            metadata: internalMethod.metadata
        )
    }

    func mapToPublic(_ internalMethods: [InternalPaymentMethod]) -> [PrimerComposablePaymentMethod] {
        return internalMethods.map { mapToPublic($0) }
    }
}
