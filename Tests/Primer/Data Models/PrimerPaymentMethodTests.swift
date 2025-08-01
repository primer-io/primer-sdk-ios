//
//  PrimerPaymentMethodTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerPaymentMethodTests: XCTestCase {

    var paymentMethod: PrimerPaymentMethod!

    override func setUpWithError() throws {
        paymentMethod = PrimerPaymentMethod(id: "id",
                                            implementationType: .nativeSdk,
                                            type: "type",
                                            name: "name",
                                            processorConfigId: "processor_config_id",
                                            surcharge: 123,
                                            options: nil,
                                            displayMetadata: nil)
    }

    func testLogo_NoImage() {
        XCTAssertNil(paymentMethod.logo)
    }

    func testLogo_NilImages() {
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: nil, light: nil, dark: nil)
        XCTAssertNil(paymentMethod.logo)
    }

    func testLogo_coloredImage() {
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(systemName: "paintbrush"),
                                                            light: UIImage(systemName: "sun.max"),
                                                            dark: UIImage(systemName: "sun.min"))

        XCTAssertEqual(paymentMethod.logo!, UIImage(systemName: "paintbrush"))
    }

    func testLogo_LightImage() {
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: nil,
                                                            light: UIImage(systemName: "sun.max"),
                                                            dark: UIImage(systemName: "sun.min"))

        XCTAssertEqual(paymentMethod.logo!, UIImage(systemName: "sun.max"))
    }

    func testLogo_DarkImage() {
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: nil,
                                                            light: nil,
                                                            dark: UIImage(systemName: "sun.min"))

        XCTAssertEqual(paymentMethod.logo!, UIImage(systemName: "sun.min"))
    }

    func testInvertedLogo_NoImage() {
        XCTAssertNil(paymentMethod.invertedLogo)
    }

    func testInvertedLogo_NilImages() {
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: nil, light: nil, dark: nil)
        XCTAssertNil(paymentMethod.invertedLogo)
    }

    func testInvertedLogo_ReturnsCorrectImage() {
        // Given
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(
            colored: UIImage(systemName: "colored"),
            light: UIImage(systemName: "light"),
            dark: UIImage(systemName: "dark")
        )
        let isDarkModeEnabled = UIScreen.isDarkModeEnabled

        // When
        let invertedLogo = paymentMethod.invertedLogo

        // Then
        if isDarkModeEnabled {
            // When dark mode is enabled, invertedLogo should return the light image if available
            if let lightImage = paymentMethod.baseLogoImage?.light {
                XCTAssertEqual(invertedLogo, lightImage)
            } else if let coloredImage = paymentMethod.baseLogoImage?.colored {
                XCTAssertEqual(invertedLogo, coloredImage)
            } else {
                XCTAssertNil(invertedLogo)
            }
        } else {
            // When dark mode is disabled, invertedLogo should return the dark image if available
            if let darkImage = paymentMethod.baseLogoImage?.dark {
                XCTAssertEqual(invertedLogo, darkImage)
            } else if let coloredImage = paymentMethod.baseLogoImage?.colored {
                XCTAssertEqual(invertedLogo, coloredImage)
            } else {
                XCTAssertNil(invertedLogo)
            }
        }
    }

    func testViewModels() {
        let nativeSDKPaymentMethod = createPaymentMethod(withImplementationType: .webRedirect)
        XCTAssertTrue(nativeSDKPaymentMethod.tokenizationViewModel is WebRedirectPaymentMethodTokenizationViewModel)

        let iPay88PaymentMethod = createPaymentMethod(withImplementationType: .iPay88Sdk)
        XCTAssertTrue(iPay88PaymentMethod.tokenizationViewModel is IPay88TokenizationViewModel)

        let formPaymentMethods: [PrimerPaymentMethodType] = [
            .adyenBlik,
            .rapydFast,
            .adyenMBWay,
            .adyenMultibanco
        ]
        formPaymentMethods.forEach { type in
            let paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk,
                                                    paymentType: type)
            XCTAssertTrue(paymentMethod.tokenizationViewModel is FormPaymentMethodTokenizationViewModel)
        }

        let banksPaymentMethods: [PrimerPaymentMethodType] = [
            .adyenIDeal,
            .adyenDotPay
        ]
        banksPaymentMethods.forEach { type in
            let paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk,
                                                    paymentType: type)
            XCTAssertTrue(paymentMethod.tokenizationViewModel is BankSelectorTokenizationViewModel)
        }

        let cardPaymentMethods: [PrimerPaymentMethodType] = [
            .paymentCard,
            .adyenBancontactCard
        ]
        cardPaymentMethods.forEach { type in
            let paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk,
                                                    paymentType: type)
            XCTAssertTrue(paymentMethod.tokenizationViewModel is CardFormPaymentMethodTokenizationViewModel)
        }

        let qrCodePaymentMethods: [PrimerPaymentMethodType] = [
            .xfersPayNow,
            .rapydPromptPay,
            .omisePromptPay
        ]
        qrCodePaymentMethods.forEach { type in
            let paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk,
                                                    paymentType: type)
            XCTAssertTrue(paymentMethod.tokenizationViewModel is QRCodeTokenizationViewModel)
        }

        let testPaymentMethods: [PrimerPaymentMethodType] = [
            .primerTestKlarna,
            .primerTestSofort,
            .primerTestPayPal
        ]
        testPaymentMethods.forEach { type in
            let paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk,
                                                    paymentType: type)
            XCTAssertTrue(paymentMethod.tokenizationViewModel is PrimerTestPaymentMethodTokenizationViewModel)
        }

        let applePayPaymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: .applePay)
        XCTAssertTrue(applePayPaymentMethod.tokenizationViewModel is ApplePayTokenizationViewModel)

        let klarnaPaymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: .klarna)
        XCTAssertTrue(klarnaPaymentMethod.tokenizationViewModel is KlarnaTokenizationViewModel)

        let payPalPaymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: .payPal)
        XCTAssertTrue(payPalPaymentMethod.tokenizationViewModel is PayPalTokenizationViewModel)

        let nolPayPaymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: .nolPay)
        XCTAssertTrue(nolPayPaymentMethod.tokenizationViewModel is NolPayTokenizationViewModel)

        let unknownPaymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: .buckarooEps)
        XCTAssertNil(unknownPaymentMethod.tokenizationViewModel)
    }

    func testTokenizationModels() {
        let adyenIdealPaymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: .adyenIDeal)
        XCTAssertTrue(adyenIdealPaymentMethod.tokenizationModel is BanksTokenizationComponent)

        PrimerPaymentMethodType.allCases.filter { $0 != .adyenIDeal }.forEach { type in
            let paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: type)
            XCTAssertNil(paymentMethod.tokenizationModel)
        }
    }

    func testIsCheckoutEnabled() {
        XCTAssertFalse(paymentMethod.isCheckoutEnabled)

        paymentMethod.baseLogoImage = .init(colored: UIImage(), light: nil, dark: nil)
        XCTAssertTrue(paymentMethod.isCheckoutEnabled)

        let excludedPaymentTypes: [PrimerPaymentMethodType] = [.googlePay, .goCardless]
        excludedPaymentTypes.forEach { type in
            paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: type)
            paymentMethod.baseLogoImage = .init(colored: UIImage(), light: nil, dark: nil)
            XCTAssertFalse(paymentMethod.isCheckoutEnabled)
        }

        PrimerPaymentMethodType.allCases.filter { !excludedPaymentTypes.contains($0) }.forEach { type in
            paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: type)
            paymentMethod.baseLogoImage = .init(colored: UIImage(), light: nil, dark: nil)
            XCTAssertTrue(paymentMethod.isCheckoutEnabled)
        }
    }

    func testIsVaultingEnabled() {
        XCTAssertFalse(paymentMethod.isVaultingEnabled)

        paymentMethod.baseLogoImage = .init(colored: UIImage(), light: nil, dark: nil)
        XCTAssertTrue(paymentMethod.isVaultingEnabled)

        let excludedPaymentTypes: [PrimerPaymentMethodType] = [.googlePay, .goCardless, .applePay, .iPay88Card, .nolPay]
        excludedPaymentTypes.forEach { type in
            paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: type)
            paymentMethod.baseLogoImage = .init(colored: UIImage(), light: nil, dark: nil)
            XCTAssertFalse(paymentMethod.isVaultingEnabled)
        }

        PrimerPaymentMethodType.allCases.filter { !excludedPaymentTypes.contains($0) }.forEach { type in
            paymentMethod = createPaymentMethod(withImplementationType: .nativeSdk, paymentType: type)
            paymentMethod.baseLogoImage = .init(colored: UIImage(), light: nil, dark: nil)
            XCTAssertTrue(paymentMethod.isVaultingEnabled)
        }
    }

    func test_initializeHeadlessPaymentMethod_withProvider() throws {
        let primerPaymentMethod = createPaymentMethod(withImplementationType: .nativeSdk)
        let paymentMethodProvider = TestPaymentMethodProvider(paymentMethod: primerPaymentMethod)
        let pm = PrimerHeadlessUniversalCheckout.PaymentMethod(paymentMethodType: primerPaymentMethod.type, paymentMethodProvider: paymentMethodProvider)

        let headlessPaymentMethod = PrimerHeadlessUniversalCheckout.PaymentMethod(paymentMethodType: "PAYMENT_CARD")

        XCTAssertNotNil(pm)
    }

    func test_initializeHeadlessPaymentMethod_raw() throws {
        let headlessPaymentMethod = PrimerHeadlessUniversalCheckout.PaymentMethod(type: "PAYMENT_CARD")
        XCTAssertEqual(headlessPaymentMethod.paymentMethodType, "PAYMENT_CARD")
    }

    // MARK: Helpers

    private func createPaymentMethod(withImplementationType implementationType: PrimerPaymentMethod.ImplementationType,
                                     paymentType: PrimerPaymentMethodType = .paymentCard) -> PrimerPaymentMethod {
        return PrimerPaymentMethod(
            id: "id",
            implementationType: implementationType,
            type: paymentType.rawValue,
            name: "name",
            processorConfigId: "processor_config_id",
            surcharge: 123,
            options: nil,
            displayMetadata: nil
        )
    }

    private struct TestPaymentMethodProvider: PrimerPaymentMethodProviding {
        var paymentMethod: PrimerPaymentMethod
        func paymentMethod(for paymentMethodType: String) -> PrimerPaymentMethod? {
            if paymentMethod.type == paymentMethodType {
                return paymentMethod
            } else {
                return nil
            }
        }
    }
}
