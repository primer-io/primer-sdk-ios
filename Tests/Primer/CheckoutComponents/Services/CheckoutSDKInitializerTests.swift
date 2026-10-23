//
//  CheckoutSDKInitializerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class CheckoutSDKInitializerTests: XCTestCase {

    override func tearDown() async throws {
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_cleanup_releasesTheCardNetworkAndClearsTheContainer() async throws {
        let container = try await ContainerTestHelpers.createTestContainer()
        let repository = MockHeadlessRepository()
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in repository }
        await DIContainer.setContainer(container)
        let sut = CheckoutSDKInitializer(
            clientToken: TestData.Tokens.valid,
            primerSettings: PrimerSettings(),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator()),
            presentationContext: .direct
        )

        sut.cleanup()
        try await withTimeout(2.0) {
            while repository.releaseCardNetworkCallCount == 0 { await Task.yield() }
        }

        XCTAssertEqual(repository.releaseCardNetworkCallCount, 1)
        let current = await DIContainer.current
        XCTAssertNil(current)
    }
}
