//
//  ProcessingSheetDismissalTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

/// The inline flow's sheet keeps the shopper from swiping away a payment that cannot be stopped.
/// A modifier inside the flow's navigation stack never reaches the sheet, so this hosts the real one.
@available(iOS 15.0, *)
@MainActor
final class ProcessingSheetDismissalTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() async throws {
        window?.rootViewController?.dismiss(animated: false)
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        try await super.tearDown()
    }

    func test_inlineSheet_whileProcessing_cannotBeSwipedAway() async throws {
        let scope = try await makeScope()
        let host = show(InlineFlowHost(scope: scope))
        scope.updateNavigationState(.processing)

        let isModal = try await presentedSheetIsModal(from: host)

        XCTAssertTrue(isModal)
    }

    // The lock during the merchant gate reads the scope from a `.task` in the sheet, and the test host
    // never starts tasks inside a sheet, so the scope side is covered in `DefaultCheckoutScope` tests.

    func test_inlineSheet_onAMethodScreenBeforePay_canBeSwipedAway() async throws {
        let scope = try await makeScope()
        let host = show(InlineFlowHost(scope: scope))
        scope.updateNavigationState(.paymentMethod(PrimerPaymentMethodType.paymentCard.rawValue))

        let isModal = try await presentedSheetIsModal(from: host)

        XCTAssertFalse(isModal)
    }

    func test_inlineSheet_onTheErrorScreen_canBeSwipedAway() async throws {
        let scope = try await makeScope()
        let host = show(InlineFlowHost(scope: scope))
        scope.updateNavigationState(.failure(PrimerError.invalidValue(key: "test", value: nil, reason: nil)))

        let isModal = try await presentedSheetIsModal(from: host)

        XCTAssertFalse(isModal)
    }

    /// The scope's own setup ends in `.failure` without a container, so it settles before a test sets its state.
    private func makeScope() async throws -> DefaultCheckoutScope {
        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        let settled = Date().addingTimeInterval(2)
        while scope.navigationState == .loading, Date() < settled {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        return scope
    }

    private func show(_ view: some View) -> UIViewController {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        self.window = window
        return host
    }

    private func presentedSheetIsModal(from host: UIViewController) async throws -> Bool {
        let presented = Date().addingTimeInterval(2)
        while host.presentedViewController == nil, Date() < presented {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let sheet = try XCTUnwrap(host.presentedViewController)
        let settled = Date().addingTimeInterval(1.5)
        while !sheet.isModalInPresentation, Date() < settled {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        // A value that flips back would let the shopper swipe after all.
        try await Task.sleep(nanoseconds: 500_000_000)
        return sheet.isModalInPresentation
    }
}
