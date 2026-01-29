//
//  MockPaymentMethodMapper.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockPaymentMethodMapper: PaymentMethodMapper {

    // MARK: - Configurable Return Values

    var singleResultToReturn: CheckoutPaymentMethod?
    var arrayResultToReturn: [CheckoutPaymentMethod] = []

    // MARK: - Call Tracking

    private(set) var mapToPublicSingleCallCount = 0
    private(set) var mapToPublicArrayCallCount = 0
    private(set) var lastInternalMethod: InternalPaymentMethod?
    private(set) var lastInternalMethods: [InternalPaymentMethod]?

    // MARK: - Protocol Implementation

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

    // MARK: - Test Helpers

    func reset() {
        mapToPublicSingleCallCount = 0
        mapToPublicArrayCallCount = 0
        lastInternalMethod = nil
        lastInternalMethods = nil
        singleResultToReturn = nil
        arrayResultToReturn = []
    }
}
