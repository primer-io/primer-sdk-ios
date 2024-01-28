//
//  PrimerHeadlessKlarnaManagerTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 28.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaHeadlessManagerTests: XCTestCase {
    
    var manager: PrimerHeadlessUniversalCheckout.KlarnaHeadlessManager!
    var viewHandlingComponent: KlarnaPaymentViewHandlingComponent!
    
    override func setUp() {
        super.setUp()
        manager = PrimerHeadlessUniversalCheckout.KlarnaHeadlessManager()
        viewHandlingComponent = manager.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
    }
    
    override func tearDown() {
        manager = nil
        viewHandlingComponent = nil
        super.tearDown()
    }
    
    func testInitialization_Succeeds() {
        XCTAssertNotNil(manager)
    }
    
    func testPaymentSessionCreationComponent_Initialized() {
        XCTAssertNotNil(manager.provideKlarnaPaymentSessionCreationComponent())
    }
    
    func testKlarnaPaymentViewHandlingComponent_Initialized() {
        XCTAssertNotNil(viewHandlingComponent)
        XCTAssertNotNil(viewHandlingComponent.klarnaProvider)
    }
    
    func testPaymentSessionAuthorizationComponent_Initialized() {
        let _ = manager
        let component = manager.provideKlarnaPaymentSessionAuthorizationComponent()
        XCTAssertNotNil(component)
        XCTAssertNotNil(component.klarnaProvider)
    }
    
    func testPaymentSessionFinalizationComponent_Initialized() {
        let component = manager.provideKlarnaPaymentSessionFinalizationComponent()
        component.setProvider(provider: KlarnaTestsMocks.klarnaProvider)
        XCTAssertNotNil(component)
        XCTAssertNotNil(component.klarnaProvider)
    }
    
    func testPaymentSessionCreationComponent_ReturnsStoredInstance() {
        let providedComponent = manager.provideKlarnaPaymentSessionCreationComponent()
        XCTAssertTrue(providedComponent === manager.sessionCreationComponent)
    }
    
    func testPaymentViewHandlingComponent_ReturnsStoredInstance() {
        let providedComponent = manager.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        XCTAssertTrue(providedComponent === manager.viewHandlingComponent)
    }
    
    func testPaymentSessionAuthorizationComponent_ReturnsStoredInstance() {
        let providedComponent = manager.provideKlarnaPaymentSessionAuthorizationComponent()
        XCTAssertTrue(providedComponent === manager.sessionAuthorizationComponent)
    }
    
    func testPaymentSessionFinalizationComponent_ReturnsStoredInstance() {
        let providedComponent = manager.provideKlarnaPaymentSessionFinalizationComponent()
        XCTAssertTrue(providedComponent === manager.sessionFinalizationComponent)
    }
    
    func testPaymentSessionCreationComponent_SingletonBehavior() {
        let component1 = manager.provideKlarnaPaymentSessionCreationComponent()
        let component2 = manager.provideKlarnaPaymentSessionCreationComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testPaymentViewHandlingComponent_SingletonBehavior() {
        let component1 = manager.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        let component2 = manager.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        XCTAssertTrue(component1 === component2)
    }
    
    func testPaymentSessionAuthorizationComponent_SingletonBehavior() {
        let component1 = manager.provideKlarnaPaymentSessionAuthorizationComponent()
        let component2 = manager.provideKlarnaPaymentSessionAuthorizationComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testPaymentSessionFinalizationComponent_SingletonBehavior() {
        let component1 = manager.provideKlarnaPaymentSessionFinalizationComponent()
        let component2 = manager.provideKlarnaPaymentSessionFinalizationComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testInitialization_OrderedCorrectly() {
        let component1 = manager.provideKlarnaPaymentSessionCreationComponent()
        let component2 = manager.provideKlarnaPaymentViewHandlingComponent(
            clientToken: KlarnaTestsMocks.clientToken,
            paymentCategory: KlarnaTestsMocks.paymentMethod
        )
        let component3 = manager.provideKlarnaPaymentSessionAuthorizationComponent()
        let component4 = manager.provideKlarnaPaymentSessionFinalizationComponent()

        XCTAssertTrue(component1 !== component2)
        XCTAssertTrue(component1 !== component3)
        XCTAssertTrue(component1 !== component4)
        XCTAssertTrue(component2 !== component3)
        XCTAssertTrue(component2 !== component4)
        XCTAssertTrue(component3 !== component4)
    }
    
    func testInitialization_AllDifferentComponents() {
        let componentsSet: Set = [
            ObjectIdentifier(manager.provideKlarnaPaymentSessionCreationComponent()),
            ObjectIdentifier(manager.provideKlarnaPaymentViewHandlingComponent(
                clientToken: KlarnaTestsMocks.clientToken,
                paymentCategory: KlarnaTestsMocks.paymentMethod
            )),
            ObjectIdentifier(manager.provideKlarnaPaymentSessionAuthorizationComponent()),
            ObjectIdentifier(manager.provideKlarnaPaymentSessionFinalizationComponent())
        ]
        XCTAssertEqual(componentsSet.count, 4)
    }
}
#endif
