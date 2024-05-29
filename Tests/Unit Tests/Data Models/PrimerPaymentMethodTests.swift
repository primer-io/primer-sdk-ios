//
//  PrimerPaymentMethodTests.swift
//  
//
//  Created by Jack Newcombe on 19/05/2024.
//

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
}
