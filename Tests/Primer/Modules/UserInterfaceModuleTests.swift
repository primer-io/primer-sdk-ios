//
//  UserInterfaceModuleTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

class UserInterfaceModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Register default PrimerSettingsProtocol for each test
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        PrimerInternal.shared.intent = .checkout
    }

    override func tearDown() {
        PrimerInternal.shared.intent = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createMockViewModel(
        paymentMethodType: String,
        intent: PrimerSessionIntent = .checkout,
        displayMetadata: PrimerPaymentMethod.DisplayMetadata? = nil
    ) -> MockPaymentMethodTokenizationViewModel {
        let paymentMethod = PrimerPaymentMethod(
            id: "mock_id",
            implementationType: .nativeSdk,
            type: paymentMethodType,
            name: "Mock Payment Method",
            processorConfigId: "mock_processor",
            surcharge: 0,
            options: nil,
            displayMetadata: displayMetadata
        )

        return MockPaymentMethodTokenizationViewModel(
            config: paymentMethod,
            intent: intent,
            validationError: nil,
            tokenizationResult: (PrimerPaymentMethodTokenData(
                analyticsId: "",
                id: "",
                isVaulted: false,
                isAlreadyVaulted: false,
                paymentInstrumentType: .unknown,
                paymentMethodType: paymentMethodType,
                paymentInstrumentData: nil,
                threeDSecureAuthentication: nil,
                token: "",
                tokenType: .singleUse,
                vaultData: nil), nil),
            paymentCreationDecision: .continuePaymentCreation(),
            paymentResult: (PrimerCheckoutData(
                payment: .init(id: "", orderId: "", paymentFailureReason: nil),
                additionalInfo: nil), nil)
        )
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
            "When intent is vault, should show 'Add card'"
        )
    }

    // MARK: - Local Display Metadata Tests

    func test_localDisplayMetadata_paymentCard_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#FFFFFF")
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.cornerRadius, 4)
    }

    func test_localDisplayMetadata_applePay_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#FFFFFF")
    }

    func test_localDisplayMetadata_payPal_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.payPal.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#009CDE")
    }

    func test_localDisplayMetadata_klarna_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.klarna.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#FFB3C7")
    }

    func test_localDisplayMetadata_adyenIdeal_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#CC0066")
    }

    func test_localDisplayMetadata_adyenBlik_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenBlik.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#000000")
    }

    func test_localDisplayMetadata_coinbase_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.coinbase.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#0052FF")
    }

    func test_localDisplayMetadata_goCardless_returnsNil() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.goCardless.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNil(uiModule.localDisplayMetadata)
    }

    func test_localDisplayMetadata_googlePay_returnsNil() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.googlePay.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNil(uiModule.localDisplayMetadata)
    }

    func test_localDisplayMetadata_unknownPaymentMethod_returnsNil() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: "UNKNOWN_TYPE")

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNil(uiModule.localDisplayMetadata)
    }

    // MARK: - Button Title Tests

    func test_buttonTitle_paymentCard_checkout_showsPayWithCard() {
        // Given
        PrimerInternal.shared.intent = .checkout
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonTitle, Strings.PaymentButton.payWithCard)
    }

    func test_buttonTitle_paymentCard_vault_showsAddCard() {
        // Given
        PrimerInternal.shared.intent = .vault
        let mockVM = createMockViewModel(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            intent: .vault
        )

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonTitle, Strings.VaultPaymentMethodViewContent.addCard)
    }

    func test_buttonTitle_adyenBancontactCard_showsPayWithCard() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenBancontactCard.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonTitle, Strings.PaymentButton.payWithCard)
    }

    func test_buttonTitle_iPay88Card_showsPayWithCard() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.iPay88Card.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonTitle, Strings.PaymentButton.payWithCard)
    }

    func test_buttonTitle_twoCtwoP_showsPayInInstallments() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.twoCtwoP.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonTitle, Strings.PaymentButton.payInInstallments)
    }

    func test_buttonTitle_fintechtureSmartTransfer_showsPayBySmartTransfer() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.fintechtureSmartTransfer.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonTitle, Strings.PaymentButton.payBySmartTransfer)
    }

    func test_buttonTitle_fintechtureImmediateTransfer_showsPayByImmediateTransfer() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.fintechtureImmediateTransfer.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonTitle, Strings.PaymentButton.payByImmediateTransfer)
    }

    // MARK: - Button Corner Radius Tests

    func test_buttonCornerRadius_fromLocalMetadata_returnsValue() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonCornerRadius, 4.0)
    }

    func test_buttonCornerRadius_noMetadata_returnsDefault() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: "UNKNOWN_TYPE")

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonCornerRadius, 4.0)
    }

    // MARK: - Button Border Width Tests

    func test_buttonBorderWidth_paymentCard_returnsCorrectValue() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then - paymentCard has borderWidth colored: 1
        XCTAssertEqual(uiModule.buttonBorderWidth, 1.0)
    }

    func test_buttonBorderWidth_noMetadata_returnsZero() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: "UNKNOWN_TYPE")

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.buttonBorderWidth, 0.0)
    }

    // MARK: - Button Tint Color Tests

    func test_buttonTintColor_alwaysNil() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNil(uiModule.buttonTintColor)
    }

    // MARK: - Submit Button Tests

    func test_submitButton_adyenBlik_showsConfirm() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenBlik.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.submitButton)
        XCTAssertEqual(uiModule.submitButton?.currentTitle, Strings.PaymentButton.confirm)
    }

    func test_submitButton_xfersPayNow_showsConfirm() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.xfersPayNow.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.submitButton)
        XCTAssertEqual(uiModule.submitButton?.currentTitle, Strings.PaymentButton.confirm)
    }

    func test_submitButton_adyenMultibanco_showsConfirmToPay() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenMultibanco.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.submitButton)
        XCTAssertEqual(uiModule.submitButton?.currentTitle, Strings.PaymentButton.confirmToPay)
    }

    func test_submitButton_adyenBancontactCard_showsPay() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenBancontactCard.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.submitButton)
        XCTAssertEqual(uiModule.submitButton?.currentTitle, Strings.PaymentButton.pay)
    }

    func test_submitButton_primerTestKlarna_showsPay() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.primerTestKlarna.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.submitButton)
        XCTAssertEqual(uiModule.submitButton?.currentTitle, Strings.PaymentButton.pay)
    }

    func test_submitButton_unknownPaymentMethod_returnsNil() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: "UNKNOWN_TYPE")

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNil(uiModule.submitButton)
    }

    func test_submitButton_adyenMBWay_checkout_showsPay() {
        // Given
        PrimerInternal.shared.intent = .checkout
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenMBWay.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.submitButton)
        XCTAssertTrue(uiModule.submitButton?.currentTitle?.starts(with: Strings.PaymentButton.pay) ?? false)
    }

    // MARK: - Payment Method Button Tests

    func test_paymentMethodButton_hasCorrectAccessibilityIdentifier() {
        // Given
        let paymentMethodType = PrimerPaymentMethodType.paymentCard.rawValue
        let mockVM = createMockViewModel(paymentMethodType: paymentMethodType)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertEqual(uiModule.paymentMethodButton.accessibilityIdentifier, paymentMethodType)
    }

    func test_paymentMethodButton_hasCorrectHeight() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)
        let button = uiModule.paymentMethodButton

        // Then - check that a height constraint of 45 exists
        let heightConstraint = button.constraints.first { $0.firstAttribute == .height }
        XCTAssertNotNil(heightConstraint)
        XCTAssertEqual(heightConstraint?.constant, 45)
    }

    // MARK: - Is Submit Button Animating Tests

    func test_isSubmitButtonAnimating_whenNoSubmitButton_returnsFalse() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: "UNKNOWN_TYPE")

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertFalse(uiModule.isSubmitButtonAnimating)
    }

    // MARK: - Additional Display Metadata Tests

    func test_localDisplayMetadata_adyenSofort_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenSofort.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#EF809F")
    }

    func test_localDisplayMetadata_adyenTrustly_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenTrustly.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#0EE06E")
    }

    func test_localDisplayMetadata_adyenVipps_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenVipps.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#FF5B24")
    }

    func test_localDisplayMetadata_adyenMobilePay_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenMobilePay.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#5A78FF")
    }

    func test_localDisplayMetadata_adyenGiropay_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.adyenGiropay.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#000268")
    }

    func test_localDisplayMetadata_atome_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.atome.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#F0FF5F")
    }

    func test_localDisplayMetadata_hoolah_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.hoolah.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#D63727")
    }

    func test_localDisplayMetadata_xenditOvo_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.xenditOvo.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#4B2489")
    }

    func test_localDisplayMetadata_xfersPayNow_hasCorrectBackgroundColor() {
        // Given
        let mockVM = createMockViewModel(paymentMethodType: PrimerPaymentMethodType.xfersPayNow.rawValue)

        // When
        let uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: mockVM)

        // Then
        XCTAssertNotNil(uiModule.localDisplayMetadata)
        XCTAssertEqual(uiModule.localDisplayMetadata?.button.backgroundColor?.coloredHex, "#028BF4")
    }
}
