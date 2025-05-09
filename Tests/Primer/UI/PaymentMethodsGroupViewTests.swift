//
//  PaymentMethodsGroupViewTests.swift
//
//
//  Created by Jack Newcombe on 11/06/2024.
//

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

    func performPreTokenizationSteps() -> Promise<Void> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func performPreTokenizationSteps() async throws {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func performTokenizationStep() -> Promise<Void> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func performTokenizationStep() async throws {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func performPostTokenizationSteps() -> Promise<Void> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func performPostTokenizationSteps() async throws {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func tokenize() -> PrimerSDK.Promise<PrimerPaymentMethodTokenData> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> PrimerCheckoutData? {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func presentPaymentMethodUserInterface() -> Promise<Void> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func presentPaymentMethodUserInterface() async throws {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func awaitUserInput() -> Promise<Void> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func awaitUserInput() async throws {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }


    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                          paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                             paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> PrimerSDK.Promise<PrimerSDK.PrimerCheckoutData?> {
        Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerSDK.PrimerCheckoutData? {
        throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
    }

    func handleSuccessfulFlow() {
    }

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
