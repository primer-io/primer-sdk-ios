//
//  PrimerCustomResultViewControllerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

final class PrimerCustomResultViewControllerTests: XCTestCase {

    var sut: PrimerCustomResultViewController!
    var uiManager: MockPrimerUIManager!

    override func setUp() {
        super.setUp()

        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: nil)
        uiManager = MockPrimerUIManager()
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_paymentStatusView_not_nil() {
        XCTAssertNotNil(sut.paymentStatusView)
    }

    func test_paymentStatusViewModel_not_nil() {
        XCTAssertNotNil(sut.paymentStatusViewModel)
    }

    func test_achUserDetails_viewWillAppear() {
        sut.viewWillAppear(false)

        if let parentVC = sut.parent as? PrimerContainerViewController {
            XCTAssertTrue(parentVC.mockedNavigationBar.hidesBackButton)
        }
    }

    func test_achUserDetails_viewWillDisappear() {
        sut.viewWillDisappear(false)

        if let parentVC = sut.parent as? PrimerContainerViewController {
            XCTAssertFalse(parentVC.mockedNavigationBar.hidesBackButton)
        }
    }

    func test_paymentStatusViewModel_title() {
        let title = "Pay with"
        XCTAssertTrue(sut.paymentStatusViewModel.title.contains(title))
    }

    func test_paymentStatusViewModel_subtitle() {
        let authorizedSubtitle = "Payment authorized"
        let failedSubtitle = "Payment failed"
        let canceledSubtitle = "Payment cancelled"

        // Authorized
        XCTAssertEqual(sut.paymentStatusViewModel.subtitle, authorizedSubtitle)

        // Failed
        tearDown()
        let failedError = ACHHelpers.getInvalidSettingError(name: "test")
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: failedError)
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.paymentStatusViewModel.subtitle, failedSubtitle)

        // Canceled
        tearDown()
        let canceledError = ACHHelpers.getCancelledError(paymentMethodType: "STRIPE_ACH")
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: canceledError)
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.paymentStatusViewModel.subtitle, canceledSubtitle)
    }

    func test_paymentStatusViewModel_paymentMessage_success() {
        let successMessage = "You have now authorized your bank account to be debited. You will be notified via email once the payment has been collected successfully."

        XCTAssertEqual(sut.paymentStatusViewModel.paymentMessage, successMessage)
    }

    func test_paymentStatusViewModel_paymentMessage_failed() {
        tearDown()
        let canceledError = ACHHelpers.getCancelledError(paymentMethodType: "STRIPE_ACH")
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: canceledError)
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.paymentStatusViewModel.paymentMessage, "Please try again or select another bank")
    }

    func test_paymentStatusViewModel_ui_buttons_canceled() {
        tearDown()
        let canceledError = ACHHelpers.getCancelledError(paymentMethodType: "STRIPE_ACH")
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: canceledError)
        sut.loadViewIfNeeded()

        XCTAssertFalse(sut.paymentStatusViewModel.showOnRetry)
        XCTAssertTrue(sut.paymentStatusViewModel.showChooseOtherPaymentMethod)
    }

    func test_paymentStatusViewModel_ui_buttons_failed() {
        tearDown()
        let failedError = ACHHelpers.getInvalidSettingError(name: "test")
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: failedError)
        sut.loadViewIfNeeded()

        XCTAssertTrue(sut.paymentStatusViewModel.showOnRetry)
        XCTAssertTrue(sut.paymentStatusViewModel.showChooseOtherPaymentMethod)
    }

    func test_paymentStatusViewModel_ui_buttons_success() {
        XCTAssertFalse(sut.paymentStatusViewModel.showOnRetry)
        XCTAssertFalse(sut.paymentStatusViewModel.showChooseOtherPaymentMethod)
    }

    func test_paymentStatusViewModel_statusIcon_success() {
        let successIcon = "checkmark.circle"
        let successIconIdentifier = AccessibilityIdentifier.ResultScreen.successImage.rawValue
        let iconColor = Color.blue.opacity(0.8)

        XCTAssertEqual(sut.paymentStatusViewModel.statusIconString, successIcon)
        XCTAssertEqual(sut.paymentStatusViewModel.statusIconAccessibilityIdentifier, successIconIdentifier)
        XCTAssertEqual(sut.paymentStatusViewModel.statusIconColor, iconColor)
    }

    func test_paymentStatusViewModel_statusIcon_failure() {
        tearDown()
        let failedError = ACHHelpers.getInvalidSettingError(name: "test")
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: failedError)
        sut.loadViewIfNeeded()

        let failedIcon = "xmark.circle"
        let failedIconIdentifier = AccessibilityIdentifier.ResultScreen.failureImage.rawValue
        let iconColor = Color.red.opacity(0.8)

        XCTAssertEqual(sut.paymentStatusViewModel.statusIconString, failedIcon)
        XCTAssertEqual(sut.paymentStatusViewModel.statusIconAccessibilityIdentifier, failedIconIdentifier)
        XCTAssertEqual(sut.paymentStatusViewModel.statusIconColor, iconColor)
    }

    func test_paymentStatusViewModel_bottomSpacings_success() {
        let titleBottomSpacing: CGFloat = 20
        let paymentMessageBottomSpacing: CGFloat = 60

        XCTAssertEqual(sut.paymentStatusViewModel.titleBottomSpacing, titleBottomSpacing)
        XCTAssertEqual(sut.paymentStatusViewModel.paymentMessageBottomSpacing, paymentMessageBottomSpacing)
    }

    func test_paymentStatusViewModel_bottomSpacings_failure() {
        tearDown()
        let failedError = ACHHelpers.getInvalidSettingError(name: "test")
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: failedError)
        sut.loadViewIfNeeded()

        let titleBottomSpacing: CGFloat = 40
        let paymentMessageBottomSpacing: CGFloat = 40

        XCTAssertEqual(sut.paymentStatusViewModel.titleBottomSpacing, titleBottomSpacing)
        XCTAssertEqual(sut.paymentStatusViewModel.paymentMessageBottomSpacing, paymentMessageBottomSpacing)
    }
}
