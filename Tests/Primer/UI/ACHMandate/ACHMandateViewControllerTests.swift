//
//  ACHMandateViewControllerTests.swift
//
//
//  Created by Stefan Vrancianu on 11.07.2024.
//

import XCTest
@testable import PrimerSDK

final class ACHMandateViewControllerTests: XCTestCase {

    var sut: ACHMandateViewController!
    var mockDelegate: MockACHMandateViewController!
    var mandateData: PrimerStripeOptions.MandateData!

    override func setUp() {
        super.setUp()

        mockDelegate = MockACHMandateViewController()
        mandateData = PrimerStripeOptions.MandateData.fullMandate(text: "test-mandate-text")
        sut = ACHMandateViewController(delegate: mockDelegate, mandateData: mandateData)
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        sut = nil
        mandateData = nil
        mockDelegate = nil
        super.tearDown()
    }

    func test_mandateView_not_nil() {
        XCTAssertNotNil(sut.mandateView)
    }

    func test_mandateViewModel_not_nil() {
        XCTAssertNotNil(sut.mandateViewModel)
    }

    func test_achUserDetails_viewWillAppear() {
        sut.viewWillAppear(false)

        if let parentVC = sut.parent as? PrimerContainerViewController {
            XCTAssertTrue(parentVC.mockedNavigationBar.hidesBackButton)
        }

        if let tapGesture = PrimerUIManager.primerRootViewController?.tapGesture,
           let swipeGesture = PrimerUIManager.primerRootViewController?.swipeGesture {
            XCTAssertFalse(tapGesture.isEnabled)
            XCTAssertFalse(swipeGesture.isEnabled)
        }
    }

    func test_achUserDetails_viewWillDisappear() {
        sut.viewWillDisappear(false)

        if let parentVC = sut.parent as? PrimerContainerViewController {
            XCTAssertFalse(parentVC.mockedNavigationBar.hidesBackButton)
        }

        if let tapGesture = PrimerUIManager.primerRootViewController?.tapGesture,
           let swipeGesture = PrimerUIManager.primerRootViewController?.swipeGesture {
            XCTAssertTrue(tapGesture.isEnabled)
            XCTAssertTrue(swipeGesture.isEnabled)
        }
    }

    func test_mandateViewModel_fullText() {
        XCTAssertEqual(sut.mandateViewModel.mandateText, "test-mandate-text")
    }

    func test_mandateViewModel_templateText() {
        tearDown()

        let merchantName = "Primer Inc"
        let templateMandateText = "By clicking Accept, you authorize Primer Inc to debit the selected bank account for any amount owed for charges arising from your use of Primer Inc's services and/or purchase of products from Primer Inc, pursuant to Primer Inc's website and terms, until this authorization is revoked. You may amend or cancel this authorization at any time by providing notice to Primer Inc with 30 (thirty) days notice.\n\nIf you use Primer Inc's services or purchase additional products periodically pursuant to Primer Inc's terms, you authorize Primer Inc to debit your bank account periodically. Payments that fall outside the regular debits authorized above will only be debited after your authorization is obtained."

        mockDelegate = MockACHMandateViewController()
        mandateData = PrimerStripeOptions.MandateData.templateMandate(merchantName: merchantName)
        sut = ACHMandateViewController(delegate: mockDelegate, mandateData: mandateData)
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.mandateViewModel.mandateText, templateMandateText)
    }

    func test_mandateAccept_action() {
        let expectDidAcceptMandate = self.expectation(description: "expectDidAcceptMandate called")
        mockDelegate.didAcceptMandate = {
            expectDidAcceptMandate.fulfill()
        }

        sut.mandateView?.onAcceptPressed()
        waitForExpectations(timeout: 2)
    }

    func test_mandateDecline_action() {
        let expectDidDeclineMandate = self.expectation(description: "expectDidDeclineMandate called")
        mockDelegate.didDeclineMandate = {
            expectDidDeclineMandate.fulfill()
        }

        sut.mandateView?.onCancelPressed()
        waitForExpectations(timeout: 2)
    }
}

class MockACHMandateViewController: ACHMandateDelegate {
    func acceptMandate() {
        didAcceptMandate?()
    }

    func declineMandate() {
        didDeclineMandate?()
    }

    var didAcceptMandate: (() -> Void)?
    var didDeclineMandate: (() -> Void)?
}
