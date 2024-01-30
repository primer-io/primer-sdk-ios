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
    var tokenizationComponent: KlarnaTokenizationComponentProtocol?
    
    var sessionCreationComponent: KlarnaPaymentSessionCreationComponent!
    var sessionAuthorizationComponent: KlarnaPaymentSessionAuthorizationComponent!
    var sessionFinalizationComponent: KlarnaPaymentSessionFinalizationComponent!
    var viewHandlingComponent: KlarnaPaymentViewHandlingComponent!
    
    override func setUp() {
        super.setUp()
        manager = PrimerHeadlessUniversalCheckout.KlarnaHeadlessManager()
        manager.setProvider(with: KlarnaTestsMocks.clientToken, paymentCategory: KlarnaTestsMocks.paymentMethod)
    }
    
    override func tearDown() {
        manager = nil
        viewHandlingComponent = nil
        super.tearDown()
    }
    
    func testInitialization_succeeds() {
        XCTAssertNotNil(manager)
    }
    
    func testPaymentSessionCreationComponent_initialized() {
        XCTAssertNotNil(manager.sessionCreationComponent)
    }
    
    func testKlarnaPaymentViewHandlingComponent_initialized() {
        XCTAssertNotNil(viewHandlingComponent)
        XCTAssertNotNil(viewHandlingComponent.klarnaProvider)
    }
    
    func testPaymentSessionAuthorizationComponent_initialized() {
        let component = manager.sessionAuthorizationComponent
        component.setProvider(provider: KlarnaTestsMocks.klarnaProvider)
        XCTAssertNotNil(component)
        XCTAssertNotNil(component.klarnaProvider)
    }
    
    func testPaymentSessionFinalizationComponent_initialized() {
        let component = manager.sessionFinalizationComponent
        component.setProvider(provider: KlarnaTestsMocks.klarnaProvider)
        XCTAssertNotNil(component)
        XCTAssertNotNil(component.klarnaProvider)
    }
    
    func testInitialization_allDifferentComponents() {
        let componentsSet: Set = [
            ObjectIdentifier(manager.sessionCreationComponent),
            ObjectIdentifier(manager.viewHandlingComponent),
            ObjectIdentifier(manager.sessionAuthorizationComponent),
            ObjectIdentifier(manager.sessionFinalizationComponent)
        ]
        XCTAssertEqual(componentsSet.count, 4)
    }
    
    func testSessionCreation_updateCollectedData() {
        let accountInfo = KlarnaTestsMocks.klarnaAccountInfo
        
        let collectedData: KlarnaPaymentSessionCollectableData = .customerAccountInfo(
            accountUniqueId: accountInfo!.accountUniqueId,
            accountRegistrationDate: accountInfo!.accountRegistrationDate.toString(),
            accountLastModified: accountInfo!.accountLastModified.toString())
        
        manager.updateSessionCollectedData(collectableData: collectedData)
        
        XCTAssertEqual(manager.sessionCreationComponent.customerAccountInfo, accountInfo)
    }
    
}
#endif
