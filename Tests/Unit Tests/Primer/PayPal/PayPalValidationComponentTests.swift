//
//  PayPalValidationComponentTests.swift
//  
//
//  Created by Jack Newcombe on 20/05/2024.
//

import XCTest
@testable import PrimerSDK

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
