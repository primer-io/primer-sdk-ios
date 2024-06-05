//
//  ApplePayValidationComponentTests.swift
//  
//
//  Created by Jack Newcombe on 20/05/2024.
//

import XCTest
@testable import PrimerSDK

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
