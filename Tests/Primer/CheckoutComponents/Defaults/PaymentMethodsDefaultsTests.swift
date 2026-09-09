//
//  PaymentMethodsDefaultsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class PaymentMethodsDefaultsTests: XCTestCase {

  // MARK: - PaymentMethodsDefaults section helpers

  func test_method_buildsRowForwardingSelection() {
    var selected = false
    let method = CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Card")
    let row = PaymentMethodsDefaults.method(method) { selected = true }
    XCTAssertEqual(row.method, method)
    row.onSelect()
    XCTAssertTrue(selected)
  }
}
