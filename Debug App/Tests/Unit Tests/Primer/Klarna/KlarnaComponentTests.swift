//
//  KlarnaPaymentSessionAuthorizationComponentTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 28.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaComponentTests: XCTestCase {
    
    var sut: KlarnaComponent!
    var tokenizationComponent: KlarnaTokenizationComponent!
    
    override func setUp() {
        super.setUp()
        let paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod
        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
        sut = KlarnaComponent(tokenizationComponent: tokenizationComponent)
        sut.setProvider(provider: KlarnaTestsMocks.klarnaProvider)
    }
    
    override func tearDown() {
        sut = nil
        tokenizationComponent = nil
        super.tearDown()
    }
    
    func testInitialization_Succeeds() {
        XCTAssertNotNil(sut)
    }
    
    // View Handling
    func testKlarnaProvider_NotNil() {
        XCTAssertNotNil(sut.klarnaProvider)
    }
    
    func test_CreatePaymentView() {
        XCTAssertNotNil(sut.createPaymentView())
    }
}
#endif
