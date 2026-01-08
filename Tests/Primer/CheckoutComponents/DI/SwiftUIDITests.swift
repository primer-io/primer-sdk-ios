//
//  SwiftUIDITests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

// MARK: - SwiftUI+DI Tests

@available(iOS 15.0, *)
@MainActor
final class SwiftUIDITests: XCTestCase {

    // MARK: - Test Doubles

    private final class MockService {
        var identifier: String

        init(identifier: String = TestData.DI.defaultIdentifier) {
            self.identifier = identifier
        }
    }

    private final class MockObservableService: ObservableObject {
        @Published var value: String = TestData.DI.observableDefaultValue
    }

    // MARK: - Setup / Teardown

    private var savedContainer: ContainerProtocol?

    override func setUp() async throws {
        try await super.setUp()
        savedContainer = await DIContainer.current
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        if let savedContainer {
            await DIContainer.setContainer(savedContainer)
        } else {
            await DIContainer.clearContainer()
        }
        try await super.tearDown()
    }

    // MARK: - Tests

    func test_requiredInjected_returnsFallback() {
        // Arrange
        var requiredInjected = RequiredInjected(
            MockService.self,
            fallback: MockService(identifier: TestData.DI.protocolFallbackValue)
        )

        // Act
        let value = requiredInjected.wrappedValue

        // Assert
        XCTAssertEqual(value.identifier, TestData.DI.protocolFallbackValue)
    }

}
