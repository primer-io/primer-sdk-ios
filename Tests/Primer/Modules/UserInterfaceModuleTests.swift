//
//  UserInterfaceModuleTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
@testable import PrimerSDK
import XCTest

class UserInterfaceModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Register default PrimerSettingsProtocol for each test
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
    }

    func test_user_interface_module() throws {
        // Arrange
        PrimerInternal.shared.intent = .checkout

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
                darkHex: "#000000")
        )

        let paymentMethodDisplayMetadata = PrimerPaymentMethod.DisplayMetadata(button: paymentMethodButton)

        let paymentMethod = PrimerPaymentMethod(
            id: "mock_payment_method",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Mock Payment Method",
            processorConfigId: "mock_processor_config_id",
            surcharge: 99,
            options: nil,
            displayMetadata: paymentMethodDisplayMetadata
        )

        let mockVM = MockPaymentMethodTokenizationViewModel(
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
                nil
            )
        )

        // Act
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Assert
        XCTAssertNotNil(uiModule.submitButton, "Should have created the submit button")
    }

    func test_submitButton_showsAddNewCard_whenCheckoutAndFlagTrue() {
        // Arrange: checkout intent + custom UIOptions
        PrimerInternal.shared.intent = .checkout
        let uiOptions = PrimerUIOptions(
            cardFormUIOptions: PrimerCardFormUIOptions(payButtonAddNewCard: true)
        )
        DependencyContainer.register(PrimerSettings(uiOptions: uiOptions) as PrimerSettingsProtocol)

        let paymentMethod = PrimerPaymentMethod(
            id: "mock",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Mock",
            processorConfigId: "mock",
            surcharge: 0,
            options: nil,
            displayMetadata: PrimerPaymentMethod.DisplayMetadata(button:
                PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: .init(coloredUrlStr: nil, lightUrlStr: nil, darkUrlStr: nil),
                    backgroundColor: .init(coloredHex: "#000", lightHex: "#000", darkHex: "#FFF"),
                    cornerRadius: 4,
                    borderWidth: .init(colored: 1, light: 1, dark: 1),
                    borderColor: .init(coloredHex: "#FFF", lightHex: "#FFF", darkHex: "#000"),
                    text: "Mock", textColor: .init(coloredHex: "#FFF", lightHex: "#FFF", darkHex: "#000")
                )
            )
        )
        let mockVM = MockPaymentMethodTokenizationViewModel(
            config: paymentMethod,
            intent: .checkout,
            validationError: nil,
            tokenizationResult: (PrimerPaymentMethodTokenData(
                analyticsId: "", id: "", isVaulted: false, isAlreadyVaulted: false,
                paymentInstrumentType: .unknown, paymentMethodType: "", paymentInstrumentData: nil,
                threeDSecureAuthentication: nil, token: "", tokenType: .singleUse, vaultData: nil), nil),
            paymentCreationDecision: .continuePaymentCreation(),
            paymentResult: (PrimerCheckoutData(payment: .init(id: "", orderId: "", paymentFailureReason: nil), additionalInfo: nil), nil)
        )

        // Act
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Assert
        XCTAssertEqual(
            uiModule.submitButton?.currentTitle,
            Strings.VaultPaymentMethodViewContent.addCard,
            "When in checkout and payButtonAddNewCard=true, should show ‘Add new card’"
        )
    }

    func test_submitButton_showsAddCard_whenVaultIntent() {
        // Arrange: vault intent (default settings)
        PrimerInternal.shared.intent = .vault
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)

        let paymentMethod = PrimerPaymentMethod(
            id: "mock",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Mock",
            processorConfigId: "mock",
            surcharge: 0,
            options: nil,
            displayMetadata: PrimerPaymentMethod.DisplayMetadata(button:
                PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: .init(coloredUrlStr: nil, lightUrlStr: nil, darkUrlStr: nil),
                    backgroundColor: .init(coloredHex: "#000", lightHex: "#000", darkHex: "#FFF"),
                    cornerRadius: 4,
                    borderWidth: .init(colored: 1, light: 1, dark: 1),
                    borderColor: .init(coloredHex: "#FFF", lightHex: "#FFF", darkHex: "#000"),
                    text: "Mock", textColor: .init(coloredHex: "#FFF", lightHex: "#FFF", darkHex: "#000")
                )
            )
        )
        let mockVM = MockPaymentMethodTokenizationViewModel(
            config: paymentMethod,
            intent: .vault,
            validationError: nil,
            tokenizationResult: (PrimerPaymentMethodTokenData(
                analyticsId: "", id: "", isVaulted: false, isAlreadyVaulted: false,
                paymentInstrumentType: .unknown, paymentMethodType: "", paymentInstrumentData: nil,
                threeDSecureAuthentication: nil, token: "", tokenType: .singleUse, vaultData: nil), nil),
            paymentCreationDecision: .continuePaymentCreation(),
            paymentResult: (PrimerCheckoutData(payment: .init(id: "", orderId: "", paymentFailureReason: nil), additionalInfo: nil), nil)
        )

        // Act
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Assert
        XCTAssertEqual(
            uiModule.submitButton?.currentTitle,
            Strings.PrimerCardFormView.addCardButtonTitle,
            "When intent is vault, should show ‘Add card’"
        )
    }
}
