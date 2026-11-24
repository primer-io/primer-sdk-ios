//
//  PaymentMethodButtonTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

/// Renders every branch of the list button. The look itself is checked on a device.
@available(iOS 15.0, *)
@MainActor
final class PaymentMethodButtonTests: XCTestCase {

    func test_render_partnerWithBackendVersions_inLightAndDark() {
        // Given
        let method = makePartnerMethod(hasLogo: true)

        // When / Then
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .light)))
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .dark)))
    }

    func test_render_partnerWithoutLogo_showsText() {
        // Given
        let method = makePartnerMethod(hasLogo: false)

        // When / Then
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .light)))
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .dark)))
    }

    func test_render_merchantBuiltPartner_usesPublicFields() {
        // Given
        let method = CheckoutPaymentMethod(
            id: "PAYPAL", type: "PAYPAL", name: "PayPal",
            backgroundColor: .yellow, buttonText: "PayPal", textColor: .black)

        // When / Then
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .light)))
    }

    func test_render_card() {
        let method = CheckoutPaymentMethod(id: "PAYMENT_CARD", type: "PAYMENT_CARD", name: "Card")
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .light)))
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .dark)))
    }

    func test_render_klarna() {
        let method = CheckoutPaymentMethod(id: "KLARNA", type: "KLARNA", name: "Klarna")
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .light)))
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .dark)))
    }

    func test_render_applePay() {
        let method = CheckoutPaymentMethod(id: "APPLE_PAY", type: "APPLE_PAY", name: "Apple Pay")
        XCTAssertTrue(SwiftUIRenderProbe.render(makeButton(method, colorScheme: .dark)))
    }

    // MARK: - Helpers

    private func makeButton(_ method: CheckoutPaymentMethod, colorScheme: ColorScheme) -> some View {
        PaymentMethodButton(method: method, onSelect: {})
            .environment(\.colorScheme, colorScheme)
    }

    private func makePartnerMethod(hasLogo: Bool) -> CheckoutPaymentMethod {
        var method = CheckoutPaymentMethod(id: "PAYPAL", type: "PAYPAL", name: "PayPal", buttonText: "PayPal")
        method.backgroundColorVariants = PrimerTheme.BaseColors(coloredHex: "#FFC439", lightHex: "#FFFFFF", darkHex: "#000000")
        method.textColorVariants = PrimerTheme.BaseColors(coloredHex: nil, lightHex: "#000000", darkHex: "#FFFFFF")
        if hasLogo {
            method.logoVariants = PrimerTheme.BaseImage(colored: makeImage(), light: nil, dark: makeImage())
        }
        return method
    }

    private func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 75, height: 26)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 75, height: 26))
        }
    }
}
