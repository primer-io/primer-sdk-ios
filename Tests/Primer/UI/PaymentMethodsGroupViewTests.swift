//
//  PaymentMethodsGroupViewTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PaymentMethodsGroupViewTests: XCTestCase {

    var sut: PaymentMethodsGroupView!

    func testViewInit() throws {
        let viewModel = MockTokenizationViewModel()
        sut = PaymentMethodsGroupView(title: "title", paymentMethodTokenizationViewModels: [viewModel])

        let stackView = sut.subviews.first as? UIStackView
        XCTAssertNotNil(stackView)

        let paymentMethodButton = stackView?.arrangedSubviews.last as? PrimerButton
        XCTAssertNotNil(paymentMethodButton)
        XCTAssertEqual(paymentMethodButton?.title(for: .normal), "Pay with card")

        let expectStart = self.expectation(description: "Tokenization is started")
        viewModel.onStart = {
            expectStart.fulfill()
        }

        paymentMethodButton?.simulateEvent(.touchUpInside)

        waitForExpectations(timeout: 2.0)
    }
}

private class MockTokenizationViewModel: NSObject, PaymentMethodTokenizationViewModelProtocol {

    func submitButtonTapped() {
    }

    static var apiClient: (any PrimerAPIClientProtocol)?

    var checkoutEventsNotifierModule: CheckoutEventsNotifierModule = .init()

    var didStartPayment: (() -> Void)?

    var didFinishPayment: (((any Error)?) -> Void)?

    var paymentMethodTokenData: PrimerPaymentMethodTokenData?

    var paymentCheckoutData: PrimerCheckoutData?

    var successMessage: String?

    func validate() throws {
    }

    var onStart: (() -> Void)?

    func start() {
        onStart?()
    }

    func performPreTokenizationSteps() async throws {
        throw PrimerError.unknown()
    }

    func performTokenizationStep() async throws {
        throw PrimerError.unknown()
    }

    func performPostTokenizationSteps() async throws {
        throw PrimerError.unknown()
    }

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        throw PrimerError.unknown()
    }

    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData {
        throw PrimerError.unknown()
    }

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> PrimerCheckoutData? {
        throw PrimerError.unknown()
    }

    func presentPaymentMethodUserInterface() async throws {
        throw PrimerError.unknown()
    }

    func awaitUserInput() async throws {
        throw PrimerError.unknown()
    }

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                             paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
        throw PrimerError.unknown()
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerSDK.PrimerCheckoutData? {
        throw PrimerError.unknown()
    }

    @MainActor
    func handleSuccessfulFlow() {
    }

    @MainActor
    func handleFailureFlow(errorMessage: String?) {
    }

    func cancel() {
    }

    var willPresentPaymentMethodUI: (() -> Void)?

    var didPresentPaymentMethodUI: (() -> Void)?

    var willDismissPaymentMethodUI: (() -> Void)?

    var didDismissPaymentMethodUI: (() -> Void)?

    var config: PrimerSDK.PrimerPaymentMethod = Mocks.PaymentMethods.paymentCardPaymentMethod

    lazy var uiModule: PrimerSDK.UserInterfaceModule! = {
        UserInterfaceModule(paymentMethodTokenizationViewModel: self)
    }()

    var position: Int = 0
}

extension UIControl {

    func simulateEvent(_ event: UIControl.Event) {
        for target in allTargets {
            let target = target as NSObjectProtocol
            for actionName in actions(forTarget: target, forControlEvent: event) ?? [] {
                let selector = Selector(actionName)
                target.perform(selector, with: self)
            }
        }
    }
}
