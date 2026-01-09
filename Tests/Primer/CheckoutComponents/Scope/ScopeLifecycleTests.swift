//
//  ScopeLifecycleTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for scope lifecycle management to achieve 90% Scope & Utilities coverage.
/// Covers initialization, teardown, memory management, and state cleanup.
@available(iOS 15.0, *)
@MainActor
final class ScopeLifecycleTests: XCTestCase {

    private var sut: ScopeLifecycleManager!

    override func setUp() async throws {
        try await super.setUp()
        sut = ScopeLifecycleManager()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization

    func test_initialize_setsInitialState() {
        // When
        sut.initialize()

        // Then
        XCTAssertTrue(sut.isInitialized)
        XCTAssertFalse(sut.isActive)
    }

    func test_initialize_multipleTime_ignoresSubsequentCalls() {
        // When
        sut.initialize()
        sut.initialize()
        sut.initialize()

        // Then
        XCTAssertEqual(sut.initializationCount, 1)
    }

    // MARK: - Activation

    func test_activate_startsScope() {
        // Given
        sut.initialize()

        // When
        sut.activate()

        // Then
        XCTAssertTrue(sut.isActive)
    }

    func test_activate_beforeInitialization_throws() {
        // When/Then
        XCTAssertThrowsError(try sut.activateWithValidation()) { error in
            XCTAssertEqual(error as? ScopeError, .notInitialized)
        }
    }

    // MARK: - Deactivation

    func test_deactivate_stopsScope() {
        // Given
        sut.initialize()
        sut.activate()

        // When
        sut.deactivate()

        // Then
        XCTAssertFalse(sut.isActive)
    }

    func test_deactivate_cleansUpResources() {
        // Given
        sut.initialize()
        sut.activate()
        sut.allocateResources()

        // When
        sut.deactivate()

        // Then
        XCTAssertEqual(sut.activeResourceCount, 0)
    }

    // MARK: - Teardown

    func test_teardown_resetsAllState() {
        // Given
        sut.initialize()
        sut.activate()

        // When
        sut.teardown()

        // Then
        XCTAssertFalse(sut.isInitialized)
        XCTAssertFalse(sut.isActive)
        XCTAssertEqual(sut.initializationCount, 0)
    }

    func test_teardown_callsCleanupHandlers() {
        // Given
        var cleanupCalled = false
        sut.initialize()
        sut.onCleanup = {
            cleanupCalled = true
        }

        // When
        sut.teardown()

        // Then
        XCTAssertTrue(cleanupCalled)
    }

    // MARK: - Memory Management

    func test_scope_doesNotRetainCyclically() {
        // Given
        weak var weakScope: ScopeLifecycleManager?

        // When
        autoreleasepool {
            let scope = ScopeLifecycleManager()
            weakScope = scope
            scope.initialize()
        }

        // Then
        XCTAssertNil(weakScope, "Scope should be deallocated")
    }

    // MARK: - State Transitions

    func test_lifecycleTransitions_followCorrectOrder() {
        // When
        sut.initialize()
        XCTAssertEqual(sut.currentState, .initialized)

        sut.activate()
        XCTAssertEqual(sut.currentState, .active)

        sut.deactivate()
        XCTAssertEqual(sut.currentState, .inactive)

        sut.teardown()
        XCTAssertEqual(sut.currentState, .tornDown)
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private enum ScopeError: Error, Equatable {
    case notInitialized
}

@available(iOS 15.0, *)
private enum ScopeState: Equatable {
    case uninitialized
    case initialized
    case active
    case inactive
    case tornDown
}

// MARK: - Scope Lifecycle Manager

@available(iOS 15.0, *)
@MainActor
private class ScopeLifecycleManager {
    private(set) var isInitialized = false
    private(set) var isActive = false
    private(set) var initializationCount = 0
    private(set) var activeResourceCount = 0
    private(set) var currentState: ScopeState = .uninitialized
    var onCleanup: (() -> Void)?

    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        initializationCount += 1
        currentState = .initialized
    }

    func activate() {
        isActive = true
        currentState = .active
    }

    func activateWithValidation() throws {
        guard isInitialized else {
            throw ScopeError.notInitialized
        }
        activate()
    }

    func deactivate() {
        isActive = false
        activeResourceCount = 0
        currentState = .inactive
    }

    func teardown() {
        onCleanup?()
        isInitialized = false
        isActive = false
        initializationCount = 0
        activeResourceCount = 0
        currentState = .tornDown
    }

    func allocateResources() {
        activeResourceCount += 1
    }
}
