//
//  KlarnaPaymentViewHandlingComponentTests.swift
//  Debug App SPM Tests
//
//  Created by Illia Khrypunov on 20.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
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
