//
//  PrimerTests.swift
//  PrimerSDK_Tests
//
//  Created by Evangelos Pittas on 24/9/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PrimerTests: XCTestCase {
    
    func test_primer() throws {
        Primer.shared.showPaymentMethod(.apaya, withIntent: .vault, on: UIViewController())
        XCTAssert(Primer.shared.flow == .addApayaToVault)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.apaya, withIntent: .checkout, on: UIViewController())
        XCTAssert(Primer.shared.flow == nil)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.applePay, withIntent: .vault, on: UIViewController())
        XCTAssert(Primer.shared.flow == nil)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.applePay, withIntent: .checkout, on: UIViewController())
        XCTAssert(Primer.shared.flow == .checkoutWithApplePay)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.goCardlessMandate, withIntent: .vault, on: UIViewController())
        XCTAssert(Primer.shared.flow == .addDirectDebitToVault)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.goCardlessMandate, withIntent: .checkout, on: UIViewController())
        XCTAssert(Primer.shared.flow == nil)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.klarna, withIntent: .vault, on: UIViewController())
        XCTAssert(Primer.shared.flow == .addKlarnaToVault)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.klarna, withIntent: .checkout, on: UIViewController())
        XCTAssert(Primer.shared.flow == .checkoutWithKlarna)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.paymentCard, withIntent: .vault, on: UIViewController())
        XCTAssert(Primer.shared.flow == .addCardToVault)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.paymentCard, withIntent: .checkout, on: UIViewController())
        XCTAssert(Primer.shared.flow == .completeDirectCheckout)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.payPal, withIntent: .vault, on: UIViewController())
        XCTAssert(Primer.shared.flow == .addPayPalToVault)
        Primer.shared.dismiss()
        
        Primer.shared.showPaymentMethod(.payPal, withIntent: .checkout, on: UIViewController())
        XCTAssert(Primer.shared.flow == .checkoutWithPayPal)
        Primer.shared.dismiss()
    }
    
}


#endif
