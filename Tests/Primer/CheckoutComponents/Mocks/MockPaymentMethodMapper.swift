//
//  MockPaymentMethodMapper.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of PaymentMethodMapper for testing.
/// Provides configurable return values and call tracking.
@available(iOS 15.0, *)
final class MockPaymentMethodMapper: PaymentMethodMapper {
    var mapToPublicSingleCallCount = 0
    var mapToPublicArrayCallCount = 0
    var lastInternalMethod: InternalPaymentMethod?
    var lastInternalMethods: [InternalPaymentMethod]?
    var singleResultToReturn: CheckoutPaymentMethod?
    var arrayResultToReturn: [CheckoutPaymentMethod] = []

    func mapToPublic(_ internalMethod: InternalPaymentMethod) -> CheckoutPaymentMethod {
        mapToPublicSingleCallCount += 1
        lastInternalMethod = internalMethod

        if let result = singleResultToReturn {
            return result
        }

        // Return a default test payment method
        return CheckoutPaymentMethod(
            id: internalMethod.type,
            type: internalMethod.type,
            name: internalMethod.name
        )
    }

    func mapToPublic(_ internalMethods: [InternalPaymentMethod]) -> [CheckoutPaymentMethod] {
        mapToPublicArrayCallCount += 1
        lastInternalMethods = internalMethods

        if !arrayResultToReturn.isEmpty {
            return arrayResultToReturn
        }

        // Map each method using the single mapper
        return internalMethods.map { mapToPublic($0) }
    }

    func reset() {
        mapToPublicSingleCallCount = 0
        mapToPublicArrayCallCount = 0
        lastInternalMethod = nil
        lastInternalMethods = nil
        singleResultToReturn = nil
        arrayResultToReturn = []
    }
}
