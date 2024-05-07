//
//  CheckoutWithVaultedPaymentMethodViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 07/05/2024.
//

import XCTest
@testable import PrimerSDK

final class CheckoutWithVaultedPaymentMethodViewModelTests: XCTestCase {

    var sut: CheckoutWithVaultedPaymentMethodViewModel!

    override func setUpWithError() throws {
        sut = CheckoutWithVaultedPaymentMethodViewModel(configuration: Mocks.PaymentMethods.paymentCardPaymentMethod,
                                                        selectedPaymentMethodTokenData: Mocks.primerPaymentMethodTokenData,
                                                        additionalData: nil)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testHandleSuccessFlow() throws {
        let expectation = self.expectation(description: "Results controller is displayed")

        _ = PrimerUIManager.prepareRootViewController().done { _ in
            self.sut.handleSuccessfulFlow()

            let viewControllers = PrimerUIManager.primerRootViewController!.navController.viewControllers
            XCTAssertEqual(viewControllers.count, 1)
            XCTAssertTrue(viewControllers.first! is PrimerContainerViewController)
            let childViewController = (viewControllers.first as! PrimerContainerViewController).childViewController
            XCTAssertTrue(childViewController is PrimerResultViewController)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testHandleFailureFlow() throws {
        let expectation = self.expectation(description: "Results controller is displayed")

        _ = PrimerUIManager.prepareRootViewController().done { _ in
            self.sut.handleFailureFlow(errorMessage: "Message")

            let viewControllers = PrimerUIManager.primerRootViewController!.navController.viewControllers
            XCTAssertEqual(viewControllers.count, 1)
            XCTAssertTrue(viewControllers.first! is PrimerContainerViewController)
            let childViewController = (viewControllers.first as! PrimerContainerViewController).childViewController
            XCTAssertTrue(childViewController is PrimerResultViewController)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

}
