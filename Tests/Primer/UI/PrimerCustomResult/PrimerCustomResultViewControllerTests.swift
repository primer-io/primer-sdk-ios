//
//  PrimerCustomResultViewControllerTests.swift
//  
//
//  Created by Stefan Vrancianu on 11.07.2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerCustomResultViewControllerTests: XCTestCase {
    
    var sut: PrimerCustomResultViewController!

    override func setUp() {
        super.setUp()
        
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: nil)
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
        let successMessage = "You have now authorised your bank account to be debited. You will be notified via email once the payment has been collected successfully."
        
        XCTAssertEqual(sut.paymentStatusViewModel.paymentMessage, successMessage)
    }
    
    func test_paymentStatusViewModel_paymentMessage_failed() {
        tearDown()
        let canceledError = ACHHelpers.getCancelledError(paymentMethodType: "STRIPE_ACH")
        sut = PrimerCustomResultViewController(paymentMethodType: .stripeAch, error: canceledError)
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.paymentStatusViewModel.paymentMessage, canceledError.localizedDescription)
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
}
