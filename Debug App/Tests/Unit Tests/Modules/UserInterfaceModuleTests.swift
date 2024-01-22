//
//  UserInterfaceModuleTests.swift
//  ExampleAppTests
//
//  Created by Evangelos on 23/9/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class UserInterfaceModuleTests: XCTestCase {

    func test_user_interface_module() throws {
        let paymentMethodButton = PrimerPaymentMethod.DisplayMetadata.Button(
            iconUrl: PrimerTheme.BaseColoredURLs(
                coloredUrlStr: nil,
                lightUrlStr: nil,
                darkUrlStr: nil),
            backgroundColor: PrimerTheme.BaseColors(
                coloredHex: "#000000",
                lightHex: "#000000",
                darkHex: "#FFFFFF"),
            cornerRadius: 4,
            borderWidth: PrimerTheme.BaseBorderWidth(
                colored: 1,
                light: 1,
                dark: 1),
            borderColor: PrimerTheme.BaseColors(
                coloredHex: "#FFFFFF",
                lightHex: "#FFFFFF",
                darkHex: "#000000"),
            text: "Mock Payment Method",
            textColor: PrimerTheme.BaseColors(
                coloredHex: "#FFFFFF",
                lightHex: "#FFFFFF",
                darkHex: "#000000"))

        let paymentMethodDisplayMetadata = PrimerPaymentMethod.DisplayMetadata(button: paymentMethodButton)

        let paymentMethod = PrimerPaymentMethod(
            id: "mock_payment_method",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Mock Payment Method",
            processorConfigId: "mock_processor_config_id",
            surcharge: 99,
            options: nil,
            displayMetadata: paymentMethodDisplayMetadata)

        let mockPaymentMethodTokenizationViewModel = MockPaymentMethodTokenizationViewModel(
            config: paymentMethod,
            intent: .checkout,
            validationError: nil,
            tokenizationResult: (PrimerPaymentMethodTokenData(
                analyticsId: "mock_analytics_id",
                id: "mock_id",
                isVaulted: false,
                isAlreadyVaulted: false,
                paymentInstrumentType: .unknown,
                paymentMethodType: "MOCK_PAYMENT_METHOD",
                paymentInstrumentData: nil,
                threeDSecureAuthentication: nil,
                token: "mock_payment_method_token",
                tokenType: .singleUse,
                vaultData: nil), nil),
            paymentCreationDecision: .continuePaymentCreation(),
            paymentResult: (
                PrimerCheckoutData(
                    payment: PrimerCheckoutDataPayment(
                        id: "mock_payment_id",
                        orderId: "mock_order_id",
                        paymentFailureReason: nil),
                    additionalInfo: nil),
                nil)
        )

        let userInterfaceModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockPaymentMethodTokenizationViewModel)
        XCTAssert(userInterfaceModule.submitButton != nil, "Should have created the submit button")
    }

}
