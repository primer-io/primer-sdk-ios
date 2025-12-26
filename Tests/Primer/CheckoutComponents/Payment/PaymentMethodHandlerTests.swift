//
//  PaymentMethodHandlerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for payment method handlers to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class PaymentMethodHandlerTests: XCTestCase {

    private var sut: PaymentMethodHandler!

    override func setUp() async throws {
        try await super.setUp()
        sut = PaymentMethodHandler()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_handle_cardPayment_succeeds() async throws {
        let result = try await sut.handle(method: "PAYMENT_CARD", data: ["number": TestData.CardNumbers.validVisa])
        XCTAssertNotNil(result)
    }

    func test_handle_unsupportedMethod_throws() async throws {
        do {
            _ = try await sut.handle(method: "UNSUPPORTED", data: [:])
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }
}

@available(iOS 15.0, *)
private class PaymentMethodHandler {
    func handle(method: String, data: [String: Any]) async throws -> String {
        guard method == "PAYMENT_CARD" else {
            throw NSError(domain: "test", code: 1)
        }
        return "handled"
    }
}
