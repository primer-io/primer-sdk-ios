//
//  KlarnaPaymentViewHandlingComponentTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 28.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaPaymentViewHandlingComponentTests: XCTestCase {
    
    var sut: KlarnaPaymentViewHandlingComponent!
    
    override func setUp() {
        super.setUp()
        sut = KlarnaPaymentViewHandlingComponent()
        sut.setProvider(provider: KlarnaTestsMocks.klarnaProvider)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialization_Succeeds() {
        XCTAssertNotNil(sut)
    }
    
    func testKlarnaProvider_NotNil() {
        XCTAssertNotNil(sut.klarnaProvider)
    }
    
    func test_CreatePaymentView() {
        XCTAssertNotNil(sut.createPaymentView())
    }
}
#endif
