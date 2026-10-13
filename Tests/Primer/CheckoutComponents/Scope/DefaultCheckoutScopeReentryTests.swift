//
//  DefaultCheckoutScopeReentryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import UIKit
import XCTest

/// Scopes are cached with a one-shot `start()`, so leaving the error screen, for the list or through a retry, must re-arm it.
@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopeReentryTests: XCTestCase {

    private var sut: DefaultCheckoutScope!

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        sut = try await ContainerTestHelpers.createSettledCheckoutScope()
        sut.updateNavigationState(.paymentMethodSelection)
    }

    override func tearDown() async throws {
        sut = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_reselectingAWebRedirect_afterChoosingAnotherMethodOnTheErrorScreen_launchesTheRedirectAgain() async {
        let interactor = MockProcessWebRedirectPaymentInteractor()
        interactor.errorToThrow = TestError.unknown
        let ideal = InternalPaymentMethod(id: "ideal", type: PrimerPaymentMethodType.adyenIDeal.rawValue, name: "iDEAL")
        let card = InternalPaymentMethod(id: "card", type: PrimerPaymentMethodType.paymentCard.rawValue, name: "Card")
        sut.availablePaymentMethods = [ideal, card]
        sut.paymentMethodScopeCache[ideal.type] = DefaultWebRedirectScope(
            paymentMethodType: ideal.type,
            checkoutScope: sut,
            processWebRedirectInteractor: interactor
        )
        sut.handlePaymentMethodSelection(ideal)
        await waitUntil { if case .failure = self.sut.navigationState { true } else { false } }

        let screens = FlowScreenFactory(
            scope: sut,
            theme: PrimerCheckoutTheme(),
            onCompletion: nil,
            isInlineFlow: false
        )
        guard let chooseOtherMethod = screens.showOtherMethodsAction else {
            return XCTFail("The modal error screen offers no other payment method")
        }
        chooseOtherMethod()
        await waitUntil { self.sut.navigationState == .paymentMethodSelection }
        sut.handlePaymentMethodSelection(ideal)
        await waitUntil { interactor.executeCallCount == 2 }

        XCTAssertEqual(interactor.executeCallCount, 2)
    }

    func test_retry_afterCancellingIDealThenFailingWithQR_startsQRAgainNotIDeal() async {
        let webInteractor = MockProcessWebRedirectPaymentInteractor()
        let qrInteractor = MockProcessQRCodePaymentInteractor()
        let ideal = InternalPaymentMethod(id: "ideal", type: PrimerPaymentMethodType.adyenIDeal.rawValue, name: "iDEAL")
        let ovo = InternalPaymentMethod(id: "ovo", type: PrimerPaymentMethodType.xenditOvo.rawValue, name: "OVO")
        webInteractor.errorToThrow = PrimerError.cancelled(paymentMethodType: ideal.type, diagnosticsId: "cancelled")
        sut.availablePaymentMethods = [ideal, ovo]
        sut.paymentMethodScopeCache[ideal.type] = DefaultWebRedirectScope(
            paymentMethodType: ideal.type,
            checkoutScope: sut,
            processWebRedirectInteractor: webInteractor
        )
        sut.paymentMethodScopeCache[ovo.type] = DefaultQRCodeScope(
            checkoutScope: sut,
            interactor: qrInteractor,
            paymentMethodType: ovo.type
        )
        sut.handlePaymentMethodSelection(ideal)
        await waitUntil { webInteractor.executeCallCount == 1 && self.sut.navigationState == .paymentMethodSelection }
        sut.handlePaymentMethodSelection(ovo)
        await waitForErrorScreen()

        sut.retryPayment()
        await waitUntil { qrInteractor.startPaymentCallCount == 2 }

        XCTAssertEqual(qrInteractor.startPaymentCallCount, 2)
        XCTAssertEqual(webInteractor.executeCallCount, 1)
    }

    // The mock fails every attempt, so the call count is the proof; the state is `.failure` again.
    func test_retry_afterAQRFailure_startsANewQRPayment() async {
        let interactor = MockProcessQRCodePaymentInteractor()
        let ovo = InternalPaymentMethod(id: "ovo", type: PrimerPaymentMethodType.xenditOvo.rawValue, name: "OVO")
        sut.availablePaymentMethods = [ovo]
        sut.paymentMethodScopeCache[ovo.type] = DefaultQRCodeScope(
            checkoutScope: sut,
            interactor: interactor,
            paymentMethodType: ovo.type
        )
        sut.handlePaymentMethodSelection(ovo)
        await waitForErrorScreen()

        sut.retryPayment()
        await waitUntil { interactor.startPaymentCallCount == 2 }

        XCTAssertEqual(interactor.startPaymentCallCount, 2)
    }

    func test_retry_afterAnAchFailure_reopensTheAchFlow() async {
        let interactor = MockProcessAchPaymentInteractor()
        interactor.loadUserDetailsError = TestError.unknown
        let ach = InternalPaymentMethod(id: "ach", type: PrimerPaymentMethodType.stripeAch.rawValue, name: "ACH")
        sut.availablePaymentMethods = [ach]
        sut.paymentMethodScopeCache[ach.type] = DefaultAchScope(checkoutScope: sut, processAchInteractor: interactor)
        sut.handlePaymentMethodSelection(ach)
        await waitForErrorScreen()

        sut.retryPayment()
        await waitUntil { interactor.loadUserDetailsCallCount == 2 }

        XCTAssertEqual(interactor.loadUserDetailsCallCount, 2)
    }

    // The sheet itself opens from the Apple Pay screen's `.task`, which a unit test has no view for.
    func test_retry_afterAnApplePayFailure_reopensTheApplePayScreen() async {
        let applePay = InternalPaymentMethod(id: "apple-pay", type: PrimerPaymentMethodType.applePay.rawValue, name: "Apple Pay")
        let scope = DefaultApplePayScope(checkoutScope: sut, applePayPresentationManager: MockApplePayPresentationManager())
        sut.availablePaymentMethods = [applePay]
        sut.paymentMethodScopeCache[applePay.type] = scope
        sut.onBeforePaymentCreate = { _, decide in decide(.abortPaymentCreation()) }
        sut.handlePaymentMethodSelection(applePay)
        scope.submit()
        await waitForErrorScreen()

        sut.retryPayment()

        XCTAssertEqual(sut.navigationState, .paymentMethod(applePay.type))
    }

    func test_retry_afterAKlarnaAuthorizationFailure_startsANewSession() async throws {
        let interactor = MockProcessKlarnaPaymentInteractor()
        interactor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        interactor.paymentViewToReturn = UIView()
        interactor.authorizeError = TestError.unknown
        let klarna = InternalPaymentMethod(id: "klarna", type: PrimerPaymentMethodType.klarna.rawValue, name: "Klarna")
        let scope = DefaultKlarnaScope(checkoutScope: sut, processKlarnaInteractor: interactor)
        sut.availablePaymentMethods = [klarna]
        sut.paymentMethodScopeCache[klarna.type] = scope
        sut.handlePaymentMethodSelection(klarna)
        _ = try await awaitValue(scope.state) { $0.step == .categorySelection }
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state) { $0.step == .viewReady }
        scope.submit()
        await waitForErrorScreen()

        sut.retryPayment()
        await waitUntil { interactor.createSessionCallCount == 2 }

        XCTAssertEqual(interactor.createSessionCallCount, 2)
    }

    func test_reselectingKlarna_afterACancelInKlarnasFlow_startsANewSession() async throws {
        let interactor = MockProcessKlarnaPaymentInteractor()
        interactor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        interactor.paymentViewToReturn = UIView()
        interactor.authorizationResultToReturn = .declined
        let klarna = InternalPaymentMethod(id: "klarna", type: PrimerPaymentMethodType.klarna.rawValue, name: "Klarna")
        let card = InternalPaymentMethod(id: "card", type: PrimerPaymentMethodType.paymentCard.rawValue, name: "Card")
        let scope = DefaultKlarnaScope(checkoutScope: sut, processKlarnaInteractor: interactor)
        sut.availablePaymentMethods = [klarna, card]
        sut.paymentMethodScopeCache[klarna.type] = scope
        sut.handlePaymentMethodSelection(klarna)
        _ = try await awaitValue(scope.state) { $0.step == .categorySelection }
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state) { $0.step == .viewReady }
        scope.submit()
        await waitUntil { interactor.authorizeCallCount == 1 && self.sut.navigationState == .paymentMethodSelection }

        sut.handlePaymentMethodSelection(klarna)
        await waitUntil { interactor.createSessionCallCount == 2 }

        XCTAssertEqual(interactor.createSessionCallCount, 2)
    }

    private func waitForErrorScreen(file: StaticString = #filePath, line: UInt = #line) async {
        await waitUntil(file: file, line: line) { if case .failure = self.sut.navigationState { true } else { false } }
    }

    private func waitUntil(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async {
        for _ in 0 ..< 200 {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for the condition", file: file, line: line)
    }
}
