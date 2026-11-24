//
//  ShippingHandlerParameterOrderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// Compiles the pre-shipping trailing-closure call sites. A shipping handler placed before the
/// existing closure would capture the trailing closure and break these at build time.
@available(iOS 15.0, *)
@MainActor
final class ShippingHandlerParameterOrderTests: XCTestCase {

    func test_trailingClosure_stillBindsToTheExistingClosure() {
        let callSites: [() -> Void] = [
            { _ = PrimerCheckout(clientToken: "token") { _ in } },
            { _ = PrimerCheckoutSession(clientToken: "token") { "key" } },
            { PrimerCheckoutPresenter.presentCheckout(clientToken: "token", primerSettings: PrimerSettings()) {} },
            {
                PrimerCheckoutPresenter.presentCheckout(
                    clientToken: "token", from: UIViewController(), primerSettings: PrimerSettings()
                ) {}
            },
            {
                PrimerCheckoutPresenter.presentCheckout(
                    clientToken: "token",
                    from: UIViewController(),
                    primerSettings: PrimerSettings(),
                    primerTheme: PrimerCheckoutTheme()
                ) {}
            }
        ]

        XCTAssertEqual(callSites.count, 5)
    }
}
