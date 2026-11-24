//
//  SurchargeGroupTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class SurchargeGroupTests: XCTestCase {

    func test_groups_withoutAnyFee_returnsOneGroupWithoutTitle() {
        let methods = [method("APPLE_PAY"), method("PAYPAL", surcharge: 0), method("PAYMENT_CARD")]

        XCTAssertEqual(SurchargeGroup.groups(of: methods), [SurchargeGroup(title: nil, methods: methods)])
    }

    func test_groups_withSameFeeOnEveryMethod_returnsOneFeeGroup() {
        let methods = [method("APPLE_PAY", surcharge: 500), method("PAYPAL", surcharge: 500), method("PAYMENT_CARD", surcharge: 500)]

        XCTAssertEqual(SurchargeGroup.groups(of: methods), [SurchargeGroup(title: .fee(500), methods: methods)])
    }

    func test_groups_withMixedFees_ordersFeeGroupsByFirstMethodThenNoFeeThenMayApply() {
        let card = method("PAYMENT_CARD", hasUnknownSurcharge: true)
        let payPal = method("PAYPAL")
        let applePay = method("APPLE_PAY", surcharge: 500)
        let klarna = method("KLARNA", surcharge: 200)
        let googlePay = method("GOOGLE_PAY", surcharge: 500)

        XCTAssertEqual(
            SurchargeGroup.groups(of: [card, payPal, applePay, klarna, googlePay]),
            [
                SurchargeGroup(title: .fee(500), methods: [applePay, googlePay]),
                SurchargeGroup(title: .fee(200), methods: [klarna]),
                SurchargeGroup(title: .noFee, methods: [payPal]),
                SurchargeGroup(title: .mayApply, methods: [card])
            ]
        )
    }

    func test_groups_withMayApplyCardAndNoOtherFee_returnsTitledGroups() {
        let payPal = method("PAYPAL")
        let card = method("PAYMENT_CARD", hasUnknownSurcharge: true)

        XCTAssertEqual(
            SurchargeGroup.groups(of: [card, payPal]),
            [
                SurchargeGroup(title: .noFee, methods: [payPal]),
                SurchargeGroup(title: .mayApply, methods: [card])
            ]
        )
    }

    private func method(_ type: String, surcharge: Int? = nil, hasUnknownSurcharge: Bool = false) -> CheckoutPaymentMethod {
        CheckoutPaymentMethod(id: type, type: type, name: type, surcharge: surcharge, hasUnknownSurcharge: hasUnknownSurcharge)
    }
}
