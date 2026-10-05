//
//  PaymentMethodSetupEndpointTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerNetworking

/// The wire shape follows the Partners ADR "Payment method setups on backend-driven checkout".
@available(iOS 15.0, *)
final class PaymentMethodSetupEndpointTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    func test_start_postsToTheClientSessionSetups() {
        let sut = PaymentMethodSetupEndpoint.start(paymentMethodConfigId: "config-1", intent: .vault, idempotencyKey: "key-1")

        XCTAssertEqual(sut.baseURL, "pci_url")
        XCTAssertEqual(sut.path, "client-session/client_session_id/payment-method-setups")
        XCTAssertEqual(sut.method, .post)
        XCTAssertEqual(sut.headers?["X-Idempotency-Key"], "key-1")
        XCTAssertNil(sut.queryParameters)
    }

    func test_start_sendsTheIntentAsFlow() throws {
        let body = try XCTUnwrap(
            PaymentMethodSetupEndpoint.start(paymentMethodConfigId: "config-1", intent: .vault, idempotencyKey: "key-1").body
        )
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["flow"] as? String, "VAULT")
        XCTAssertEqual(json["paymentMethodConfigId"] as? String, "config-1")
        XCTAssertEqual((json["clientInfo"] as? [String: Any])?["platform"] as? String, "IOS")
    }

    func test_start_underCheckout_sendsCheckoutFlow() throws {
        let body = try XCTUnwrap(
            PaymentMethodSetupEndpoint.start(paymentMethodConfigId: nil, intent: .checkout, idempotencyKey: "key-1").body
        )
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["flow"] as? String, "CHECKOUT")
    }

    func test_poll_getsTheSetupBySetupId() {
        let sut = PaymentMethodSetupEndpoint.poll(setupId: "pms_1")

        XCTAssertEqual(sut.path, "client-session/client_session_id/payment-method-setups/pms_1")
        XCTAssertEqual(sut.method, .get)
        XCTAssertNil(sut.body)
        XCTAssertNil(sut.headers?["X-Idempotency-Key"])
    }
}

@available(iOS 15.0, *)
final class PaymentMethodSetupResponseTests: XCTestCase {

    func test_decodesExecute() throws {
        let response = try decode("""
        {"paymentMethodSetupId": "pms_1", "instruction": {"type": "EXECUTE", "pollDelayMilliseconds": 1000,
         "nextPoll": "suspend", "payload": {"schema": {"id": "@primer/klarna"}, "parameters": {}}}}
        """)

        XCTAssertEqual(response.paymentMethodSetupId, "pms_1")
        XCTAssertEqual(response.instruction.type, .execute)
        XCTAssertEqual(response.instruction.nextPoll, .suspend)
        XCTAssertEqual(response.instruction.payload?.schema, .object(["id": .string("@primer/klarna")]))
    }

    func test_decodesWait() throws {
        let response = try decode("""
        {"paymentMethodSetupId": "pms_1", "instruction": {"type": "WAIT", "pollDelayMilliseconds": 1000, "nextPoll": "interval"}}
        """)

        XCTAssertEqual(response.instruction.type, .wait)
        XCTAssertEqual(response.instruction.nextPoll, .interval)
        XCTAssertEqual(response.instruction.pollDelayMilliseconds, 1000)
    }

    func test_decodesSetupComplete() throws {
        let response = try decode("""
        {"paymentMethodSetupId": "pms_1", "instruction": {"type": "SETUP_COMPLETE",
         "paymentInstrumentToken": {"token": "multi_use_token", "tokenType": "MULTI_USE"}}}
        """)

        XCTAssertEqual(response.instruction.type, .setupComplete)
        XCTAssertEqual(response.instruction.paymentInstrumentToken?.token, "multi_use_token")
    }

    private func decode(_ json: String) throws -> PaymentMethodSetupResponse {
        try JSONDecoder().decode(PaymentMethodSetupResponse.self, from: Data(json.utf8))
    }
}
