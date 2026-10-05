//
//  DefaultBackendDrivenSetupScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class DefaultBackendDrivenSetupScopeTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
    }

    override func tearDown() async throws {
        SDKSessionHelper.tearDown()
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_start_savesTheMethodAndEndsInVaulted() async throws {
        let repository = MockBackendDrivenSetupRepository(result: .success("multi_use_token"))
        let checkoutScope = try await makeVaultCheckoutScope()
        let sut = makeSut(checkoutScope: checkoutScope, repository: repository)

        sut.start()
        await repository.waitForCall()
        await settle()

        XCTAssertEqual(repository.calls.map(\.paymentMethodType), ["KLARNA"])
        XCTAssertEqual(repository.calls.map(\.intent), [.vault])
        let saved = PrimerPaymentMethodToken(token: "multi_use_token", paymentMethodType: "KLARNA")
        XCTAssertEqual(checkoutScope.currentState, .vaulted(saved))
    }

    func test_start_whenTheShopperCancels_returnsToTheList() async throws {
        let repository = MockBackendDrivenSetupRepository(result: .failure(BackendDrivenCheckoutCancellation()))
        let checkoutScope = try await makeVaultCheckoutScope()
        let sut = makeSut(checkoutScope: checkoutScope, repository: repository)

        sut.start()
        await repository.waitForCall()
        await settle()

        XCTAssertEqual(checkoutScope.navigationState, .paymentMethodSelection)
        guard case .ready = checkoutScope.currentState else {
            return XCTFail("Expected the checkout to stay ready, got \(checkoutScope.currentState)")
        }
    }

    func test_start_whenTheSetupFails_reportsAFailure() async throws {
        let repository = MockBackendDrivenSetupRepository(result: .failure(BackendDrivenSetupError.suspended))
        let checkoutScope = try await makeVaultCheckoutScope()
        let sut = makeSut(checkoutScope: checkoutScope, repository: repository)

        sut.start()
        await repository.waitForCall()
        await settle()

        guard case .failure = checkoutScope.currentState else {
            return XCTFail("Expected .failure, got \(checkoutScope.currentState)")
        }
    }

    func test_start_twice_setsUpOnce() async throws {
        let repository = MockBackendDrivenSetupRepository(result: .success("multi_use_token"))
        let sut = makeSut(checkoutScope: try await makeVaultCheckoutScope(), repository: repository)

        sut.start()
        sut.start()
        await repository.waitForCall()
        await settle()

        XCTAssertEqual(repository.calls.count, 1)
    }

    // MARK: - Helpers

    private func makeSut(
        checkoutScope: DefaultCheckoutScope,
        repository: BackendDrivenSetupRepository
    ) -> DefaultBackendDrivenSetupScope {
        DefaultBackendDrivenSetupScope(
            paymentMethodType: "KLARNA",
            checkoutScope: checkoutScope,
            presentationContext: .fromPaymentSelection,
            repository: repository
        )
    }

    /// A vault checkout settled at `.ready`, so its own load cannot land after the setup.
    private func makeVaultCheckoutScope() async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(customer: ClientSession.Customer(id: "customer_id"))
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration
        )
        await DIContainer.setContainer(container)
        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            intent: .vault,
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator()),
            isInlineFlow: true,
            runnableSetupTypes: { _ in [] }
        )
        for await state in scope.state where state != .initializing { break }
        return scope
    }

    private func settle() async {
        for _ in 0 ..< 10 { await Task.yield() }
    }
}

@available(iOS 15.0, *)
final class MockBackendDrivenSetupRepository: BackendDrivenSetupRepository {
    private let result: Result<String, Error>
    private(set) var calls: [(paymentMethodType: String, intent: PrimerSessionIntent)] = []
    private var continuation: CheckedContinuation<Void, Never>?

    init(result: Result<String, Error>) {
        self.result = result
    }

    func setUp(paymentMethodType: String, intent: PrimerSessionIntent) async throws -> String {
        calls.append((paymentMethodType, intent))
        continuation?.resume()
        continuation = nil
        return try result.get()
    }

    /// Suspends until `setUp` ran, so a test can assert on what followed it.
    func waitForCall() async {
        guard calls.isEmpty else { return }
        await withCheckedContinuation { continuation = $0 }
    }
}
