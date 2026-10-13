//
//  DefaultCheckoutScopeSingleMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The modal checkout opens its only payment method directly, so it must start it as a row tap would.
@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopeSingleMethodTests: XCTestCase {

    private let interactor = MockProcessWebRedirectPaymentInteractor()
    private let ideal = Mocks.PaymentMethods.adyenIDealPaymentMethod
    private var sut: DefaultCheckoutScope!

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
    }

    override func tearDown() async throws {
        sut = nil
        SDKSessionHelper.tearDown()
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_launch_withOnlyAWebRedirectMethod_startsTheRedirect() async throws {
        sut = try await makeSettledScope(paymentMethods: [ideal])

        await waitUntil { if case .failure = self.sut.navigationState { true } else { false } }

        XCTAssertEqual(interactor.executeCallCount, 1)
        XCTAssertEqual(interactor.lastPaymentMethodType, ideal.type)
        XCTAssertNotEqual(sut.navigationState, .paymentMethod(ideal.type))
    }

    func test_launch_withOnlyCard_opensTheCardForm() async throws {
        sut = try await ContainerTestHelpers.createReadyCheckoutScope()

        XCTAssertEqual(sut.navigationState, .paymentMethod(TestData.PaymentMethodTypes.card))
    }

    func test_launch_withTwoMethods_showsTheListWithoutStartingEither() async throws {
        sut = try await makeSettledScope(paymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod, ideal])

        XCTAssertEqual(sut.navigationState, .paymentMethodSelection)
        XCTAssertEqual(interactor.executeCallCount, 0)
    }

    func test_inlineLaunch_withOnlyAWebRedirectMethod_staysOnTheListWithoutStartingIt() async throws {
        sut = try await makeSettledScope(paymentMethods: [ideal], isInlineFlow: true)

        XCTAssertEqual(sut.navigationState, .paymentMethodSelection)
        XCTAssertEqual(interactor.executeCallCount, 0)
    }

    private func makeSettledScope(
        paymentMethods: [PrimerPaymentMethod],
        isInlineFlow: Bool = false
    ) async throws -> DefaultCheckoutScope {
        // The scope registers web-redirect types from the global configuration in its init.
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration
        )
        _ = try await container.register(ProcessWebRedirectPaymentInteractor.self)
            .asSingleton()
            .with { [interactor] _ in interactor }
        _ = try await container.register(WebRedirectRepository.self)
            .asSingleton()
            .with { _ in MockWebRedirectRepository() }
        await DIContainer.setContainer(container)

        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator()),
            isInlineFlow: isInlineFlow
        )
        await waitUntil { if case .initializing = scope.currentState { false } else { true } }
        return scope
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
