//
//  BackendDrivenCheckoutEntryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) import PrimerNetworking
import XCTest

final class PrimerPaymentMethodEntryDecodingTests: XCTestCase {

    func testEntryDefaultsToPayWhenAbsent() throws {
        XCTAssertEqual(try decodePaymentMethod(entry: nil).entry, .pay)
    }

    func testEntryDefaultsToPayWhenUnrecognised() throws {
        XCTAssertEqual(try decodePaymentMethod(entry: "\"someFutureValue\"").entry, .pay)
    }

    func testEntryDefaultsToPayWhenNotAString() throws {
        XCTAssertEqual(try decodePaymentMethod(entry: "42").entry, .pay)
    }

    func testEntryDefaultsToPayWhenNull() throws {
        XCTAssertEqual(try decodePaymentMethod(entry: "null").entry, .pay)
    }

    func testDecodesEveryKnownEntry() throws {
        for entry in PrimerPaymentMethod.Entry.allCases {
            XCTAssertEqual(try decodePaymentMethod(entry: "\"\(entry.rawValue)\"").entry, entry)
        }
    }

    func testEntryRawValuesMatchTheServedContract() {
        XCTAssertEqual(PrimerPaymentMethod.Entry.pay.rawValue, "pay")
        XCTAssertEqual(PrimerPaymentMethod.Entry.onSelect.rawValue, "onSelect")
        XCTAssertEqual(PrimerPaymentMethod.Entry.eager.rawValue, "eager")
    }
}

final class PrimerPaymentMethodEntryRoutingTests: XCTestCase {

    func testPayDoesNotRequireSetup() {
        XCTAssertFalse(PrimerPaymentMethod.Entry.pay.requiresSetup)
    }

    func testOnSelectRequiresSetup() {
        XCTAssertTrue(PrimerPaymentMethod.Entry.onSelect.requiresSetup)
    }

    func testEagerRequiresSetup() {
        XCTAssertTrue(PrimerPaymentMethod.Entry.eager.requiresSetup)
    }

    func testMethodWithNoEntryDoesNotRequireSetup() throws {
        XCTAssertFalse(try decodePaymentMethod(entry: nil).entry.requiresSetup)
    }
}

final class BackendDrivenCheckoutSetupEndpointTests: XCTestCase {

    func testSetupPostsToTheClientSessionVerb() throws {
        let paymentMethod = try decodePaymentMethod(entry: "\"onSelect\"")
        let setup = BackendDrivenCheckoutEndpoint.setup(paymentMethod: paymentMethod)

        XCTAssertTrue(setup.path.hasSuffix(":setup"), "Expected a :setup verb, got \(setup.path)")
        XCTAssertEqual(setup.method, .post)
        XCTAssertNil(setup.queryParameters)
    }

    func testSetupTargetsTheSameClientSessionAsPay() throws {
        let paymentMethod = try decodePaymentMethod(entry: "\"onSelect\"")
        let setup = BackendDrivenCheckoutEndpoint.setup(paymentMethod: paymentMethod)
        let pay = BackendDrivenCheckoutEndpoint.pay(paymentMethod: paymentMethod)

        XCTAssertEqual(
            setup.path.replacingOccurrences(of: ":setup", with: ""),
            pay.path.replacingOccurrences(of: ":pay", with: "")
        )
    }
}

private extension XCTestCase {
    func decodePaymentMethod(entry: String?) throws -> PrimerPaymentMethod {
        let entryField = entry.map { ", \"entry\": \($0)" } ?? ""
        let json = """
        { "implementationType": "BACKEND_DRIVEN", "type": "KLARNA", "name": "Klarna"\(entryField) }
        """
        return try JSONDecoder().decode(PrimerPaymentMethod.self, from: Data(json.utf8))
    }
}
