//
//  PrimerHeadlessKlarnaManagerTests.swift
//  Debug App SPM Tests
//
//  Created by Illia Khrypunov on 20.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class PrimerHeadlessKlarnaManagerTests: XCTestCase {
    
    var sut: PrimerHeadlessUniversalCheckout.PrimerHeadlessKlarnaManager!
    
    override func setUp() {
        super.setUp()
        sut = PrimerHeadlessUniversalCheckout.PrimerHeadlessKlarnaManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialization_Succeeds() {
        XCTAssertNotNil(sut)
    }
    
    func testPaymentSessionCreationComponent_Initialized() {
        XCTAssertNotNil(sut.provideKlarnaPaymentSessionCreationComponent(type: KlarnaTestsMocks.sessionType))
    }
    
    func testKlarnaPaymentViewHandlingComponent_Initialized() {
        let component = sut.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        XCTAssertNotNil(component)
        XCTAssertNotNil(component.klarnaProvider)
    }
    
    func testPaymentSessionAuthorizationComponent_Initialized() {
        let component = sut.provideKlarnaPaymentSessionAuthorizationComponent()
        XCTAssertNotNil(component)
        XCTAssertNotNil(component.klarnaProvider)
    }
    
    func testPaymentSessionFinalizationComponent_Initialized() {
        let component = sut.provideKlarnaPaymentSessionFinalizationComponent()
        XCTAssertNotNil(component)
        XCTAssertNotNil(component.klarnaProvider)
    }
    
    func testPaymentSessionCreationComponent_ReturnsStoredInstance() {
        let providedComponent = sut.provideKlarnaPaymentSessionCreationComponent(type: KlarnaTestsMocks.sessionType)
        XCTAssertTrue(providedComponent === sut.sessionCreationComponent)
    }
    
    func testPaymentViewHandlingComponent_ReturnsStoredInstance() {
        let providedComponent = sut.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        XCTAssertTrue(providedComponent === sut.viewHandlingComponent)
    }
    
    func testPaymentSessionAuthorizationComponent_ReturnsStoredInstance() {
        let providedComponent = sut.provideKlarnaPaymentSessionAuthorizationComponent()
        XCTAssertTrue(providedComponent === sut.sessionAuthorizationComponent)
    }
    
    func testPaymentSessionFinalizationComponent_ReturnsStoredInstance() {
        let providedComponent = sut.provideKlarnaPaymentSessionFinalizationComponent()
        XCTAssertTrue(providedComponent === sut.sessionFinalizationComponent)
    }
    
    func testPaymentSessionCreationComponent_SingletonBehavior() {
        let component1 = sut.provideKlarnaPaymentSessionCreationComponent(type: KlarnaTestsMocks.sessionType)
        let component2 = sut.provideKlarnaPaymentSessionCreationComponent(type: KlarnaTestsMocks.sessionType)
        XCTAssertTrue(component1 === component2)
    }
    
    func testPaymentViewHandlingComponent_SingletonBehavior() {
        let component1 = sut.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        let component2 = sut.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        XCTAssertTrue(component1 === component2)
    }
    
    func testPaymentSessionAuthorizationComponent_SingletonBehavior() {
        let component1 = sut.provideKlarnaPaymentSessionAuthorizationComponent()
        let component2 = sut.provideKlarnaPaymentSessionAuthorizationComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testPaymentSessionFinalizationComponent_SingletonBehavior() {
        let component1 = sut.provideKlarnaPaymentSessionFinalizationComponent()
        let component2 = sut.provideKlarnaPaymentSessionFinalizationComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testInitialization_OrderedCorrectly() {
        let component1 = sut.provideKlarnaPaymentSessionCreationComponent(type: KlarnaTestsMocks.sessionType)
        let component2 = sut.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        let component3 = sut.provideKlarnaPaymentSessionAuthorizationComponent()
        let component4 = sut.provideKlarnaPaymentSessionFinalizationComponent()

        XCTAssertTrue(component1 !== component2)
        XCTAssertTrue(component1 !== component3)
        XCTAssertTrue(component1 !== component4)
        XCTAssertTrue(component2 !== component3)
        XCTAssertTrue(component2 !== component4)
        XCTAssertTrue(component3 !== component4)
    }
    
    func testInitialization_AllDifferentComponents() {
        let componentsSet: Set = [
            ObjectIdentifier(sut.provideKlarnaPaymentSessionCreationComponent(type: KlarnaTestsMocks.sessionType)),
            ObjectIdentifier(sut.provideKlarnaPaymentViewHandlingComponent(
                clientToken: KlarnaTestsMocks.clientToken,
                paymentCategory: KlarnaTestsMocks.paymentMethod
            )),
            ObjectIdentifier(sut.provideKlarnaPaymentSessionAuthorizationComponent()),
            ObjectIdentifier(sut.provideKlarnaPaymentSessionFinalizationComponent())
        ]
        XCTAssertEqual(componentsSet.count, 4)
    }
}
#endif
