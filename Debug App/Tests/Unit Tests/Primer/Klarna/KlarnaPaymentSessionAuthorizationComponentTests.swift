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

final class KlarnaPaymentSessionAuthorizationComponentTests: XCTestCase {
    
    var sut: KlarnaPaymentSessionAuthorizationComponent!
    var tokenizationComponent: KlarnaTokenizationComponent!
    
    override func setUp() {
        super.setUp()
        let paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod
        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
        sut = KlarnaPaymentSessionAuthorizationComponent(tokenizationManager: tokenizationComponent)
    }
    
    override func tearDown() {
        sut = nil
        tokenizationComponent = nil
        super.tearDown()
    }
    
    func testInitialization_Succeeds() {
        XCTAssertNotNil(sut)
    }
    
    func testKlarnaProvider_NotNil() {
        sut.setProvider(provider: KlarnaTestsMocks.klarnaProvider)
        XCTAssertNotNil(sut.klarnaProvider)
    }
}
#endif
