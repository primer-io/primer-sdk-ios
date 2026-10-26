//
//  ApplePayUtilsTest.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class ApplePayUtilsTest: XCTestCase {

    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
    }

    func testApplePaySupportedPaymentNetworks() {
        // w/ CB
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [.cartesBancaires])), Set([.cartesBancaires]))

        // w/ mixed
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [.visa, .masterCard, .amex, .cartesBancaires])), Set([.visa, .masterCard, .amex, .cartesBancaires]))

        // w/ none
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [])), Set())
    }

    func testApplePaySupportedPaymentNetworksKeepTheSessionOrder() {
        XCTAssertEqual(
            ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [.eftpos, .diners, .visa, .hipercard, .masterCard, .amex]),
            [.eftpos, .visa, .masterCard, .amex]
        )
    }

    func testWarnsAboutAllowedCardNetworksApplePayDoesNotSupport() {
        SDKSessionHelper.setUp(withPaymentMethods: [applePayPaymentMethod])
        registerApplePayOptions()
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.eftpos, .diners, .visa, .hipercard])

        let warnings = captureWarnings { ApplePayUtils.warnAboutUnsupportedCardNetworks() }

        XCTAssertEqual(warnings, ["Apple Pay doesn't support these allowed card networks, so they are left out: DINERS_CLUB, HIPERCARD"])
    }

    func testDoesNotWarnWhenApplePaySupportsEveryAllowedCardNetwork() {
        SDKSessionHelper.setUp(withPaymentMethods: [applePayPaymentMethod])
        registerApplePayOptions()
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.eftpos, .visa])

        let warnings = captureWarnings { ApplePayUtils.warnAboutUnsupportedCardNetworks() }

        XCTAssertEqual(warnings, [])
    }

    func testDoesNotWarnWithoutApplePay() {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.eftpos, .diners])

        let warnings = captureWarnings { ApplePayUtils.warnAboutUnsupportedCardNetworks() }

        XCTAssertEqual(warnings, [])
    }

    func testCanMakeApplePayPaymentsWithAnEftposOnlyWallet() {
        registerApplePayOptions()

        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.eftpos, .visa])
        XCTAssertTrue(ApplePayUtils.canMakeApplePayPayments { $0.contains(.eftpos) })

        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.visa])
        XCTAssertFalse(ApplePayUtils.canMakeApplePayPayments { $0.contains(.eftpos) })
    }

    func testApplePaySupportedPaymentNetworksViaPrimerSettings() {

        // w/ CB
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set([.cartesBancaires]))

        // w/ mixed
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.visa, .masterCard, .amex, .cartesBancaires])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set([.visa, .masterCard, .amex, .cartesBancaires]))

        // w/ none
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set())
    }

    private var applePayPaymentMethod: PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "apple-pay-id",
            implementationType: .nativeSdk,
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: "processor-config-id",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
    }

    private func registerApplePayOptions() {
        let settings = PrimerSettings(
            paymentMethodOptions: .init(
                applePayOptions: .init(
                    merchantIdentifier: "merchant_id",
                    merchantName: nil,
                    checkProvidedNetworks: true
                )
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    private func captureWarnings(_ body: () -> Void) -> [String] {
        let logger = CapturingLogger()
        let previousLogger = PrimerLogging.shared.logger
        PrimerLogging.shared.logger = logger
        defer { PrimerLogging.shared.logger = previousLogger }
        body()
        return logger.warnings
    }
}

private final class CapturingLogger: PrimerLogger {
    var logLevel: LogLevel = .debug
    private(set) var warnings: [String] = []

    func log(level: LogLevel, message: String, userInfo: Encodable?, metadata: PrimerLogMetadata) {
        if level == .warning { warnings.append(message) }
    }
}
