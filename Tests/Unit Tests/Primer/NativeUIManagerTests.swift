//
//  NativeUIManagerTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 08/01/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class NativeUIManagerTests: XCTestCase {

    func testNativeUIManagerWithUninitializedSDK() throws {
        do {
            _ = try PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: "PAYMENT_CARD")
        } catch PrimerError.uninitializedSDKSession(_, _) {
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error type. Should be `uninitializedSDKSession`")
        }
    }

    func testNativeUIManagerWithNonNativeMethod() throws {
        SDKSessionHelper.setUp()
        do {
            _ = try PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: "PAYMENT_CARD")
        } catch PrimerError.unsupportedPaymentMethodForManager(let type, let category, _, _) {
            XCTAssertEqual(type, "PAYMENT_CARD")
            XCTAssertEqual(category, "NATIVE_UI")
        } catch {
            XCTFail("Unexpected error type. Should be `uninitializedSDKSession`")
        }
        SDKSessionHelper.tearDown()
    }

    func testNativeUIManagerWithNativeMethod() throws {
        let paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod

        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        do {
            let manager = try PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: paymentMethod.type)
            XCTAssertEqual(manager.paymentMethodType, paymentMethod.type)
        } catch {
            XCTFail("Unexpected error type. Should be `uninitializedSDKSession`")
        }
        SDKSessionHelper.tearDown()
    }
}
