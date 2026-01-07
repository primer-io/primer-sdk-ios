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

    // MARK: - Protocol Type Tests

    func test_requiredInjected_withProtocolType_returnsFallback() {
        // Arrange
        var requiredInjected = RequiredInjected(
            MockProtocol.self,
            fallback: MockProtocolImpl(value: TestData.DI.protocolFallbackValue)
        )

        // Act
        let value = requiredInjected.wrappedValue

        // Assert
        XCTAssertEqual(value.getValue(), TestData.DI.protocolFallbackValue)
    }

}

// MARK: - Test Protocol

@available(iOS 15.0, *)
private protocol MockProtocol {
    func getValue() -> String
}

@available(iOS 15.0, *)
private final class MockProtocolImpl: MockProtocol {
    private let value: String

    init(value: String) {
        self.value = value
    }

    func getValue() -> String {
        value
    }
}
