//
//  DefaultCheckoutScopeReentryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// Scopes are cached with a one-shot `start()`, so leaving the error screen for the list must re-arm it.
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
