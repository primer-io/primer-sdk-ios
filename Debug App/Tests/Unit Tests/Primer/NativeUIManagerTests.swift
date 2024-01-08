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

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

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
        } catch PrimerError.unsupportedPaymentMethod(let type, _, _) {
            XCTAssertEqual(type, "PAYMENT_CARD")
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
