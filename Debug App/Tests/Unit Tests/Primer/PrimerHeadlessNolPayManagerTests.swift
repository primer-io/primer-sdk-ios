//
//  PrimerHeadlessNolPayManagerTests.swift
//  Debug App Tests
//
//  Created by Boris on 19.9.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK // Replace with your actual app target name

class PrimerHeadlessNolPayManagerTests: XCTestCase {
    
    var sut: PrimerHeadlessUniversalCheckout.PrimerHeadlessNolPayManager!
    
    override func setUp() {
        super.setUp()
        sut = PrimerHeadlessUniversalCheckout.PrimerHeadlessNolPayManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialization_Succeeds() {
        XCTAssertNotNil(sut)
    }
    
    func testLinkCardComponent_Initialized() {
        XCTAssertNotNil(sut.provideNolPayLinkCardComponent())
    }
    
    func testUnlinkCardComponent_Initialized() {
        XCTAssertNotNil(sut.provideNolPayUnlinkCardComponent())
    }
    
    func testListLinkedCardsComponent_Initialized() {
        XCTAssertNotNil(sut.provideNolPayGetLinkedCardsComponent())
    }
    
    func testStartPaymentComponent_Initialized() {
        XCTAssertNotNil(sut.provideNolPayStartPaymentComponent())
    }
    
    func testProvideNolPayLinkCardComponent_ReturnsStoredInstance() {
        XCTAssertTrue(sut.provideNolPayLinkCardComponent() === sut.linkCardComponent)
    }
        
    func testProvideNolPayUnlinkCardComponent_ReturnsStoredInstance() {
        XCTAssertTrue(sut.provideNolPayUnlinkCardComponent() === sut.unlinkCardComponent)
    }
        
    func testProvideNolPayGetLinkedCardsComponent_ReturnsStoredInstance() {
        XCTAssertTrue(sut.provideNolPayGetLinkedCardsComponent() === sut.listLinkedCardsComponent)
    }
        
    func testProvideNolPayStartPaymentComponent_ReturnsStoredInstance() {
        XCTAssertTrue(sut.provideNolPayStartPaymentComponent() === sut.startPaymentComponent)
    }
    
    func testLinkCardComponent_SingletonBehavior() {
        let component1 = sut.provideNolPayLinkCardComponent()
        let component2 = sut.provideNolPayLinkCardComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testUnlinkCardComponent_SingletonBehavior() {
        let component1 = sut.provideNolPayUnlinkCardComponent()
        let component2 = sut.provideNolPayUnlinkCardComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testListLinkedCardsComponent_SingletonBehavior() {
        let component1 = sut.provideNolPayGetLinkedCardsComponent()
        let component2 = sut.provideNolPayGetLinkedCardsComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testStartPaymentComponent_SingletonBehavior() {
        let component1 = sut.provideNolPayStartPaymentComponent()
        let component2 = sut.provideNolPayStartPaymentComponent()
        XCTAssertTrue(component1 === component2)
    }
    
    func testInitialization_OrderedCorrectly() {
        let component1 = sut.provideNolPayLinkCardComponent()
        let component2 = sut.provideNolPayUnlinkCardComponent()
        let component3 = sut.provideNolPayGetLinkedCardsComponent()
        let component4 = sut.provideNolPayStartPaymentComponent()

        XCTAssertTrue(component1 !== component2)
        XCTAssertTrue(component1 !== component3)
        XCTAssertTrue(component1 !== component4)
        XCTAssertTrue(component2 !== component3)
        XCTAssertTrue(component2 !== component4)
        XCTAssertTrue(component3 !== component4)
    }
    
    func testInitialization_AllDifferentComponents() {
        let componentsSet: Set = [
            ObjectIdentifier(sut.provideNolPayLinkCardComponent()),
            ObjectIdentifier(sut.provideNolPayUnlinkCardComponent()),
            ObjectIdentifier(sut.provideNolPayGetLinkedCardsComponent()),
            ObjectIdentifier(sut.provideNolPayStartPaymentComponent())
        ]
        XCTAssertEqual(componentsSet.count, 4)
    }
}
