//
//  PayPalValidationComponentTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class PayPalValidationComponentTests: XCTestCase {

    let component = PayPalValidationComponent()

    func testWithNoScheme() throws {
        let invalidSettings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions())
        DependencyContainer.register(invalidSettings as PrimerSettingsProtocol)
        XCTAssertThrowsError(try component.validatePaymentMethod())
    }

    func testWithValidScheme() {
        let validSettings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(validSettings as PrimerSettingsProtocol)
        XCTAssertNoThrow(try component.validatePaymentMethod())
    }

}
