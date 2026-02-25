//
//  ApplePayValidationComponentTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class ApplePayValidationComponentTests: XCTestCase {

    let component = ApplePayValidationComponent()

    func testWithNoOptions() throws {
        let invalidSettings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions())
        DependencyContainer.register(invalidSettings as PrimerSettingsProtocol)
        XCTAssertThrowsError(try component.validatePaymentMethod())
    }

    func testWithValidOptions() {
        let applePayOptions = PrimerApplePayOptions(merchantIdentifier: "id", merchantName: "name")
        let validSettings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(applePayOptions: applePayOptions))
        DependencyContainer.register(validSettings as PrimerSettingsProtocol)
        XCTAssertNoThrow(try component.validatePaymentMethod())
    }

}
