//
//  SDKContextTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class SDKContextTests: XCTestCase {
    func testLeavesOutPaymentAndRedirectWhenAbsent() throws {
        let json = try context(payment: nil, redirect: nil).asDictionary()

        XCTAssertNil(json["payment"])
        XCTAssertNil(json["redirect"])
    }

    func testCarriesThePlatformPaymentAndReturnUrl() throws {
        let json = try context(
            payment: SDKPayment(paymentMethodType: "KLARNA"),
            redirect: SDKRedirect(returnUrl: "merchantapp://")
        ).asDictionary()

        XCTAssertEqual((json["device"] as? [String: Any])?["platform"] as? String, "IOS")
        XCTAssertEqual((json["payment"] as? [String: Any])?["paymentMethodType"] as? String, "KLARNA")
        XCTAssertEqual((json["redirect"] as? [String: Any])?["returnUrl"] as? String, "merchantapp://")
    }

    func testReturnsToTheMerchantsUrlScheme() {
        XCTAssertEqual(SDKRedirect(urlScheme: "merchantapp://"), SDKRedirect(returnUrl: "merchantapp://"))
    }

    func testHasNowhereToReturnWithoutAUrlScheme() {
        XCTAssertNil(SDKRedirect(urlScheme: nil))
        XCTAssertNil(SDKRedirect(urlScheme: ""))
        XCTAssertNil(SDKRedirect(urlScheme: "no scheme"))
    }

    private func context(payment: SDKPayment?, redirect: SDKRedirect?) -> SDKContext {
        SDKContext(
            sdk: SDK(type: "IOS_NATIVE", version: "1.0.0", integrationType: "DROP_IN", paymentHandling: "AUTO"),
            device: SDKDevice(
                platform: "IOS",
                type: "phone",
                make: "Apple",
                model: "iPhone",
                modelIdentifier: nil,
                platformVersion: "18.0",
                uniqueDeviceIdentifier: "device",
                locale: "en-GB"
            ),
            app: SDKApp(identifier: "com.example.app"),
            session: SDKSession(checkoutSessionId: "cks", clientSessionId: "cs", customerId: nil),
            payment: payment,
            merchant: SDKMerchant(primerAccountId: "acc"),
            redirect: redirect,
            analytics: SDKAnalytics(url: nil)
        )
    }
}
