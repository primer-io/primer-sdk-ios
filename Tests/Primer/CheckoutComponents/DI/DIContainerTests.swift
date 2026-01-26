//
//  DIContainerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class DIContainerTests: XCTestCase {

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

    // MARK: - createContainer Tests

    func test_createContainer_returnsDifferentInstancesEachTime() {
        // When
        let container1 = DIContainer.createContainer()
        let container2 = DIContainer.createContainer()

        // Then - they should be different Container instances
        XCTAssertFalse(isSameObject(container1, container2))
    }

    // MARK: - setContainer / current Tests

    func test_setContainer_setsCurrentContainer() async throws {
        // Given
        let container = Container()

        // When
        await DIContainer.setContainer(container)

        // Then
        let current = await DIContainer.current
        XCTAssertNotNil(current)
        XCTAssertTrue(isSameObject(current, container))
    }

    func test_currentSync_returnsCachedContainer() async throws {
        // Given
        let container = Container()
        await DIContainer.setContainer(container)

        // When
        let currentSync = DIContainer.currentSync

        // Then
        XCTAssertNotNil(currentSync)
        XCTAssertTrue(isSameObject(currentSync, container))
    }

    func test_clearContainer_clearsCurrentContainer() async throws {
        // Given
        let container = Container()
        await DIContainer.setContainer(container)

        // When
        await DIContainer.clearContainer()

        // Then
        let current = await DIContainer.current
        XCTAssertNil(current)
    }

    func test_clearContainer_clearsCachedContainer() async throws {
        // Given
        let container = Container()
        await DIContainer.setContainer(container)

        // When
        await DIContainer.clearContainer()

        // Then
        let currentSync = DIContainer.currentSync
        XCTAssertNil(currentSync)
    }

    // MARK: - withContainer Tests

    func test_withContainer_executesActionWithTemporaryContainer() async throws {
        // Given
        let originalContainer = Container()
        let temporaryContainer = Container()
        await DIContainer.setContainer(originalContainer)

        // When
        let result = await DIContainer.withContainer(temporaryContainer) {
            let current = await DIContainer.current
            return isSameObject(current, temporaryContainer)
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_withContainer_restoresPreviousContainerAfterAction() async throws {
        // Given
        let originalContainer = Container()
        let temporaryContainer = Container()
        await DIContainer.setContainer(originalContainer)

        // When
        await DIContainer.withContainer(temporaryContainer) {
            // Action executes with temporary container
        }

        // Then
        let current = await DIContainer.current
        XCTAssertTrue(isSameObject(current, originalContainer))
    }

    func test_withContainer_restoresContainerAfterException() async throws {
        // Given
        let originalContainer = Container()
        let temporaryContainer = Container()
        await DIContainer.setContainer(originalContainer)

        // When
        do {
            _ = try await DIContainer.withContainer(temporaryContainer) {
                throw DIContainerTestError.testError
            }
            XCTFail("Expected error to be thrown")
        } catch {
            // Error is expected
        }

        // Then - original container should be restored
        let current = await DIContainer.current
        XCTAssertTrue(isSameObject(current, originalContainer))
    }

    func test_withContainer_returnsActionResult() async throws {
        // Given
        let container = Container()
        let expectedValue = TestData.DIContainer.Values.expectedValue

        // When
        let result = await DIContainer.withContainer(container) {
            expectedValue
        }

        // Then
        XCTAssertEqual(result, expectedValue)
    }

    // MARK: - Scoped Container Tests

    func test_setScopedContainer_storesContainerForScope() async throws {
        // Given
        let scopeId = "test-scope"
        let container = Container()

        // When
        await DIContainer.setScopedContainer(container, for: scopeId)

        // Then
        let retrieved = await DIContainer.scopedContainer(for: scopeId)
        XCTAssertNotNil(retrieved)
        XCTAssertTrue(isSameObject(retrieved, container))
    }

    func test_scopedContainer_returnsNilForUnknownScope() async throws {
        // When
        let container = await DIContainer.scopedContainer(for: "unknown-scope")

        // Then
        XCTAssertNil(container)
    }

    func test_removeScopedContainer_removesContainer() async throws {
        // Given
        let scopeId = "removal-test-scope"
        let container = Container()
        await DIContainer.setScopedContainer(container, for: scopeId)

        // When
        await DIContainer.removeScopedContainer(for: scopeId)

        // Then
        let retrieved = await DIContainer.scopedContainer(for: scopeId)
        XCTAssertNil(retrieved)
    }

    func test_multipleScopedContainers_areIsolated() async throws {
        // Given
        let scope1 = "scope-1"
        let scope2 = "scope-2"
        let container1 = Container()
        let container2 = Container()

        // When
        await DIContainer.setScopedContainer(container1, for: scope1)
        await DIContainer.setScopedContainer(container2, for: scope2)

        // Then
        let retrieved1 = await DIContainer.scopedContainer(for: scope1)
        let retrieved2 = await DIContainer.scopedContainer(for: scope2)

        XCTAssertNotNil(retrieved1)
        XCTAssertNotNil(retrieved2)
        XCTAssertTrue(isSameObject(retrieved1, container1))
        XCTAssertTrue(isSameObject(retrieved2, container2))
        XCTAssertFalse(isSameObject(retrieved1, retrieved2))
    }

    // MARK: - setupMainContainer Tests

    func test_setupMainContainer_setsCurrentContainer() async {
        // Given
        await DIContainer.clearContainer()

        // When
        await DIContainer.setupMainContainer()

        // Then
        let current = await DIContainer.current
        XCTAssertNotNil(current)
    }

    // MARK: - Helper Methods

    private func isSameObject(_ lhs: (any ContainerProtocol)?, _ rhs: (any ContainerProtocol)?) -> Bool {
        guard let lhsObject = lhs as AnyObject?, let rhsObject = rhs as AnyObject? else {
            return lhs == nil && rhs == nil
        }
        return lhsObject === rhsObject
    }
}

// MARK: - Test Error

private enum DIContainerTestError: Error {
    case testError
}
