//
//  KlarnaRepositoryImplDelegateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import KlarnaMobileSDK
import PrimerKlarnaSDK
@testable import PrimerSDK
import XCTest

/// Klarna's authorize and finalize show Klarna's own UI, so the answer arrives whenever the shopper finishes.
@available(iOS 15.0, *)
@MainActor
final class KlarnaRepositoryImplDelegateTests: XCTestCase {

    private let authToken = "klarna-auth-token"
    // Stands in for the shopper, who can take much longer.
    private let shopperDelay: UInt64 = 200_000_000
    private var provider: MockKlarnaProvider!
    private var sut: KlarnaRepositoryImpl!

    override func setUp() {
        super.setUp()
        provider = MockKlarnaProvider()
        sut = KlarnaRepositoryImpl(
            apiClient: MockPrimerAPIClient(),
            tokenizationService: MockTokenizationService(),
            createResumePaymentService: MockCreateResumePaymentService()
        )
        sut.klarnaProvider = provider
    }

    override func tearDown() {
        sut = nil
        provider = nil
        super.tearDown()
    }

    func test_authorize_approvalAfterTheShopperTakesTheirTime_completes() async throws {
        // Given
        let authorization = Task { try await sut.authorize() }
        await waitUntil { self.provider.authorizeCallCount == 1 }
        try await Task.sleep(nanoseconds: shopperDelay)

        // When
        sut.primerKlarnaWrapperAuthorized(approved: true, authToken: authToken, finalizeRequired: false)

        // Then
        let result = try await authorization.value
        XCTAssertEqual(result, .approved(authToken: authToken))
    }

    func test_finalize_approvalAfterTheShopperTakesTheirTime_completes() async throws {
        // Given
        let finalization = Task { try await sut.finalize() }
        await waitUntil { self.provider.finaliseCallCount == 1 }
        try await Task.sleep(nanoseconds: shopperDelay)

        // When
        sut.primerKlarnaWrapperFinalized(approved: true, authToken: authToken)

        // Then
        let result = try await finalization.value
        XCTAssertEqual(result, .approved(authToken: authToken))
    }

    private func waitUntil(file: StaticString = #filePath, line: UInt = #line, _ condition: () -> Bool) async {
        for _ in 0 ..< 200 {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for the condition", file: file, line: line)
    }
}

private final class MockKlarnaProvider: PrimerKlarnaProviding {
    var paymentView: KlarnaPaymentView?
    weak var paymentViewDelegate: PrimerKlarnaProviderPaymentViewDelegate?
    weak var authorizationDelegate: PrimerKlarnaProviderAuthorizationDelegate?
    weak var finalizationDelegate: PrimerKlarnaProviderFinalizationDelegate?
    weak var errorDelegate: PrimerKlarnaProviderErrorDelegate?
    private(set) var authorizeCallCount = 0
    private(set) var finaliseCallCount = 0

    func createPaymentView() {}
    func initializePaymentView() {}
    func loadPaymentReview() {}
    func loadPaymentView(jsonData: String?) {}
    func removePaymentView() {}
    func authorize(autoFinalize: Bool, jsonData: String?) { authorizeCallCount += 1 }
    func reauthorize(jsonData: String?) {}
    func finalise(jsonData: String?) { finaliseCallCount += 1 }
}
#endif
