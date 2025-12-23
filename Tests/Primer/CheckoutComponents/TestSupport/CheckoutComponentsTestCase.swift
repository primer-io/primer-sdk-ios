//
//  CheckoutComponentsTestCase.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Base test case for CheckoutComponents tests.
/// Provides common setup and teardown for DI container configuration.
@available(iOS 15.0, *)
class CheckoutComponentsTestCase: XCTestCase {

    /// The composable container instance for dependency injection
    var composableContainer: ComposableContainer!

    override func setUp() async throws {
        try await super.setUp()

        // Create settings for the container
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )

        // Create and configure the ComposableContainer
        composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()
    }

    override func tearDown() async throws {
        composableContainer = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    /// Resolves a dependency from the current DI container
    /// - Parameter type: The type to resolve
    /// - Returns: The resolved instance
    /// - Throws: ContainerError if resolution fails
    func resolve<T>(_ type: T.Type) async throws -> T {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        return try await container.resolve(type)
    }

    /// Asserts that resolving a type succeeds and returns the expected implementation type
    /// - Parameters:
    ///   - protocolType: The protocol type to resolve
    ///   - implementationType: The expected implementation type
    func assertResolvesTo<P, I>(
        _ protocolType: P.Type,
        implementationType: I.Type,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let resolved = try await resolve(protocolType)
        XCTAssertTrue(
            resolved is I,
            "Expected \(protocolType) to resolve to \(implementationType), but got \(type(of: resolved))",
            file: file,
            line: line
        )
    }
}
