//
//  NativeUIManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class NativeUIManagerTests: XCTestCase {

    func testNativeUIManagerWithUninitializedSDK() throws {
        do {
            _ = try PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: "PAYMENT_CARD")
        } catch PrimerError.uninitializedSDKSession(_) {
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error type. Should be `uninitializedSDKSession`")
        }
    }

    func testNativeUIManagerWithNonNativeMethod() throws {
        SDKSessionHelper.setUp()
        do {
            _ = try PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: "PAYMENT_CARD")
        } catch let PrimerError.unsupportedPaymentMethodForManager(type, category, _) {
            XCTAssertEqual(type, "PAYMENT_CARD")
            XCTAssertEqual(category, "NATIVE_UI")
        } catch {
            XCTFail("Unexpected error type. Should be `uninitializedSDKSession`")
        }
        SDKSessionHelper.tearDown()
    }
}
