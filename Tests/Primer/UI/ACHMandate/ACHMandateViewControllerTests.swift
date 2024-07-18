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
    
    func test_mandateViewModel_fullText() {
        XCTAssertEqual(sut.mandateViewModel.mandateText, "test-mandate-text")
    }
    
    func test_mandateViewModel_templateText() {
        tearDown()
        
        let merchantName = "Primer Inc"
        let templateMandateText = """
                    By clicking [accept], you authorise [\(merchantName)] to debit the bank account specified above for any amount owed for charges arising from your use of [\(merchantName)]'s services and/or purchase of products from [\(merchantName)], pursuant to [\(merchantName)]'s website and terms, until this authorisation is revoked. You may amend or cancel this authorisation at any time by providing notice to [\(merchantName)] with 30 (thirty) days notice.

                    If you use [\(merchantName)]'s services or purchase additional products periodically pursuant to [\(merchantName)]'s terms, you authorise [\(merchantName)] to debit your bank account periodically. Payments that fall outside the regular debits authorised above will only be debited after your authorisation is obtained.
                    """
        
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
    var didAcceptMandate: (() -> Void)?
    var didDeclineMandate: (() -> Void)?
    
    func mandateAccepted() {
        didAcceptMandate?()
    }
    
    func mandateDeclined() {
        didDeclineMandate?()
    }
}
