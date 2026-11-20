//
//  ApplePayButtonViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@testable import PrimerSDK
import SwiftUI
import XCTest

/// The list's Apple Pay button is PassKit's own, pinned to the scheme the SwiftUI row renders in.
@available(iOS 15.0, *)
@MainActor
final class ApplePayButtonViewTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    }

    override func tearDown() {
        window.isHidden = true
        window.rootViewController = nil
        window = nil
        super.tearDown()
    }

    func test_paymentMethodButton_applePay_isPassKitButtonInTheRowsScheme() throws {
        // Given
        window.overrideUserInterfaceStyle = .light

        // When
        let button = try XCTUnwrap(hostApplePayButton(colorScheme: .dark, onSelect: {}))

        // Then
        XCTAssertEqual(button.accessibilityIdentifier, "primer_checkout_components_payment_selection_APPLE_PAY_item")
        XCTAssertEqual(button.cornerRadius, 8)
        XCTAssertEqual(button.overrideUserInterfaceStyle, .dark)
        XCTAssertEqual(button.bounds.height, 44)
    }

    func test_paymentMethodButton_applePay_inLightRowOnDarkWindow_isLight() throws {
        // Given
        window.overrideUserInterfaceStyle = .dark

        // When
        let button = try XCTUnwrap(hostApplePayButton(colorScheme: .light, onSelect: {}))

        // Then
        XCTAssertEqual(button.overrideUserInterfaceStyle, .light)
    }

    func test_paymentMethodButton_applePayTap_callsOnSelect() throws {
        // Given
        var selectCount = 0
        let button = try XCTUnwrap(hostApplePayButton(colorScheme: .light) { selectCount += 1 })

        // When
        button.simulateEvent(.touchUpInside)

        // Then
        XCTAssertEqual(selectCount, 1)
    }

    // MARK: - Helpers

    private func hostApplePayButton(colorScheme: ColorScheme, onSelect: @escaping () -> Void) -> PKPaymentButton? {
        let method = CheckoutPaymentMethod(id: "APPLE_PAY", type: "APPLE_PAY", name: "Apple Pay")
        let controller = UIHostingController(
            rootView: PaymentMethodButton(method: method, onSelect: onSelect).environment(\.colorScheme, colorScheme))
        window.rootViewController = controller
        // Visible but not key, as in SwiftUIRenderProbe, so later presentation tests keep the key window.
        window.isHidden = false
        controller.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        controller.view.layoutIfNeeded()
        return findPaymentButton(in: controller.view)
    }

    private func findPaymentButton(in view: UIView) -> PKPaymentButton? {
        (view as? PKPaymentButton) ?? view.subviews.lazy.compactMap(findPaymentButton(in:)).first
    }
}
