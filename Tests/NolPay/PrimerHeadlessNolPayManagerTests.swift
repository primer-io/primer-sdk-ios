//
//  PrimerHeadlessNolPayManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerNolPaySDK)
import XCTest
@testable import PrimerSDK
import PrimerNolPaySDK

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
        XCTAssertTrue(sut.provideNolPayStartPaymentComponent() === sut.paymentComponent)
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
#endif
