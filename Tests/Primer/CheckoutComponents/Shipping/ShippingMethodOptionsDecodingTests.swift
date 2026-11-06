//
//  ShippingMethodOptionsDecodingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerNetworking
import XCTest

/// A callback-mode SHIPPING module carries no option list. Decoding it as "not a shipping module" is
/// what makes the SDK fall back to the legacy path and silently ignore the merchant's callbacks.
final class ShippingMethodOptionsDecodingTests: XCTestCase {

    private typealias CheckoutModule = Response.Body.Configuration.CheckoutModule
    private typealias ShippingMethodOptions = CheckoutModule.ShippingMethodOptions

    func test_decode_legacyModule_keepsTheBakedInList() throws {
        let module = try decode("""
        {
          "type": "SHIPPING",
          "options": {
            "shippingMethods": [
              { "id": "standard", "name": "Standard", "description": "3-5 days", "amount": 500 }
            ],
            "selectedShippingMethod": "standard"
          }
        }
        """)

        let options = try XCTUnwrap(module.options as? ShippingMethodOptions)
        XCTAssertEqual(options.shippingMethods.map(\.id), ["standard"])
        XCTAssertEqual(options.selectedShippingMethod, "standard")
        XCTAssertFalse(options.callbackMode)
    }

    func test_decode_callbackModeModule_decodesWithoutAList() throws {
        let module = try decode("""
        { "type": "SHIPPING", "options": { "callbackMode": true } }
        """)

        let options = try XCTUnwrap(module.options as? ShippingMethodOptions)
        XCTAssertTrue(options.callbackMode)
        XCTAssertTrue(options.shippingMethods.isEmpty)
        XCTAssertNil(options.selectedShippingMethod)
    }

    func test_decode_emptyOptions_isNotAShippingModule() throws {
        let module = try decode("""
        { "type": "SHIPPING", "options": {} }
        """)

        XCTAssertNil(module.options as? ShippingMethodOptions)
    }

    func test_decode_cardInformationModule_isUnaffected() throws {
        let module = try decode("""
        { "type": "CARD_INFORMATION", "options": { "cardHolderName": true } }
        """)

        XCTAssertNotNil(module.options as? CheckoutModule.CardInformationOptions)
        XCTAssertNil(module.options as? ShippingMethodOptions)
    }

    func test_encode_roundTripsCallbackMode() throws {
        let module = CheckoutModule(
            type: "SHIPPING",
            requestUrlStr: nil,
            options: ShippingMethodOptions(callbackMode: true)
        )

        let data = try JSONEncoder().encode(module)
        let decoded = try JSONDecoder().decode(CheckoutModule.self, from: data)

        XCTAssertEqual((decoded.options as? ShippingMethodOptions)?.callbackMode, true)
    }

    private func decode(_ json: String) throws -> CheckoutModule {
        try JSONDecoder().decode(CheckoutModule.self, from: Data(json.utf8))
    }
}
