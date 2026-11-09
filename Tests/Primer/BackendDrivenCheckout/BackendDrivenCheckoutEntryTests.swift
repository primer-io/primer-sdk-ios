//
//  BackendDrivenCheckoutEntryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerNetworking
@testable import PrimerSDK
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
        XCTAssertEqual(PrimerPaymentMethod.Entry.pay.rawValue, "PAY")
        XCTAssertEqual(PrimerPaymentMethod.Entry.onSelect.rawValue, "ON_SELECT")
        XCTAssertEqual(PrimerPaymentMethod.Entry.eager.rawValue, "EAGER")
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

    func testSetupPostsToThePaymentMethodSetupsCollection() throws {
        let paymentMethod = try decodePaymentMethod(entry: "\"ON_SELECT\"")
        let setup = BackendDrivenCheckoutEndpoint.setup(paymentMethod: paymentMethod)

        XCTAssertTrue(
            setup.path.hasSuffix("/payment-method-setups"),
            "Expected the payment-method-setups collection, got \(setup.path)"
        )
        XCTAssertEqual(setup.method, .post)
        XCTAssertNil(setup.queryParameters)
    }

    func testSetupIsNotScopedToTheClientSessionUnlikePay() throws {
        let paymentMethod = try decodePaymentMethod(entry: "\"ON_SELECT\"")
        let setup = BackendDrivenCheckoutEndpoint.setup(paymentMethod: paymentMethod)
        let pay = BackendDrivenCheckoutEndpoint.pay(paymentMethod: paymentMethod)

        XCTAssertFalse(setup.path.contains("client-session"), "Setups are a top-level collection, got \(setup.path)")
        XCTAssertTrue(pay.path.contains("client-session"), "Pay stays on the client session, got \(pay.path)")
        XCTAssertEqual(setup.baseURL, pay.baseURL)
    }

    func testPayWithATokenPostsTheTokenToPay() throws {
        let paymentMethod = try decodePaymentMethod(entry: "\"ON_SELECT\"")
        let pay = BackendDrivenCheckoutEndpoint.pay(paymentMethod: paymentMethod)
        let payWithToken = BackendDrivenCheckoutEndpoint.payWithToken(paymentInstrumentTokenId: "token-1")

        XCTAssertEqual(payWithToken.path, pay.path)
        XCTAssertEqual(payWithToken.method, .post)
        let body = try XCTUnwrap(payWithToken.body.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        XCTAssertEqual(body["paymentInstrumentTokenId"] as? String, "token-1")
        XCTAssertNotNil(body["clientInfo"])
        XCTAssertNil(body["paymentMethodType"])
    }

    func testSetupPostsTheConfigToStart() throws {
        let json = """
        { "id": "config-1", "implementationType": "BACKEND_DRIVEN", "type": "KLARNA", "name": "Klarna", "setupStart": "ON_SELECT" }
        """
        let paymentMethod = try JSONDecoder().decode(PrimerPaymentMethod.self, from: Data(json.utf8))
        let setup = BackendDrivenCheckoutEndpoint.setup(paymentMethod: paymentMethod)

        let body = try XCTUnwrap(setup.body.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        XCTAssertNil(body["flow"])
        XCTAssertEqual(body["paymentMethodConfigId"] as? String, "config-1")
        XCTAssertNotNil(body["clientInfo"])
        XCTAssertNil(body["paymentMethodType"])
    }

    func testPollTargetsTheSetupCreatedByTheCollection() throws {
        let paymentMethod = try decodePaymentMethod(entry: "\"ON_SELECT\"")
        let setup = BackendDrivenCheckoutEndpoint.setup(paymentMethod: paymentMethod)
        let poll = BackendDrivenCheckoutEndpoint.pollSetup(setupId: "setup-1")

        XCTAssertEqual(poll.path, setup.path + "/setup-1")
        XCTAssertEqual(poll.method, .get)
    }
}

private extension XCTestCase {
    func decodePaymentMethod(entry: String?) throws -> PrimerPaymentMethod {
        let entryField = entry.map { ", \"setupStart\": \($0)" } ?? ""
        let json = """
        { "implementationType": "BACKEND_DRIVEN", "type": "KLARNA", "name": "Klarna"\(entryField) }
        """
        return try JSONDecoder().decode(PrimerPaymentMethod.self, from: Data(json.utf8))
    }
}
