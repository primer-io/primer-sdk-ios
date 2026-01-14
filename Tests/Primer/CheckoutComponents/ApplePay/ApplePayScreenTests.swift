//
//  ApplePayScreenTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
import PassKit
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ApplePayScreenTests: XCTestCase {

    // MARK: - Properties

    private var mockPresentationManager: ScreenTestMockApplePayPresentationManager!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockPresentationManager = ScreenTestMockApplePayPresentationManager()
    }

    override func tearDown() {
        mockPresentationManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func test_init_storesScope() {
        // Given
        let scope = createScope()

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertNotNil(screen)
    }

    @MainActor
    func test_init_withDefaultContext_usesFromPaymentSelection() {
        // Given
        let scope = createScope()

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertNotNil(screen)
    }

    @MainActor
    func test_init_withDirectContext_storesContext() {
        // Given
        let scope = createScope(presentationContext: .direct)

        // When
        let screen = ApplePayScreen(scope: scope, presentationContext: .direct)

        // Then
        XCTAssertNotNil(screen)
    }

    @MainActor
    func test_init_withFromPaymentSelectionContext_storesContext() {
        // Given
        let scope = createScope(presentationContext: .fromPaymentSelection)

        // When
        let screen = ApplePayScreen(scope: scope, presentationContext: .fromPaymentSelection)

        // Then
        XCTAssertNotNil(screen)
    }

    // MARK: - Navigation Bar Tests

    @MainActor
    func test_navigationBar_withFromPaymentSelectionContext_shouldShowBackButton() {
        // Given
        let scope = createScope(presentationContext: .fromPaymentSelection)

        // When
        let screen = ApplePayScreen(scope: scope, presentationContext: .fromPaymentSelection)

        // Then
        XCTAssertTrue(scope.presentationContext.shouldShowBackButton)
        XCTAssertNotNil(screen)
    }

    @MainActor
    func test_navigationBar_withDirectContext_shouldNotShowBackButton() {
        // Given
        let scope = createScope(presentationContext: .direct)

        // When
        let screen = ApplePayScreen(scope: scope, presentationContext: .direct)

        // Then
        XCTAssertFalse(scope.presentationContext.shouldShowBackButton)
        XCTAssertNotNil(screen)
    }

    // MARK: - Content Tests

    @MainActor
    func test_content_whenAvailable_scopeReportsAvailable() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertTrue(scope.isAvailable)
        XCTAssertNotNil(screen)
    }

    @MainActor
    func test_content_whenUnavailable_scopeReportsUnavailable() {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertFalse(scope.isAvailable)
        XCTAssertNotNil(screen)
    }

    // MARK: - Loading State Tests

    @MainActor
    func test_availableContent_whenLoading_scopeReportsLoading() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        scope.structuredState.isLoading = true

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertTrue(scope.structuredState.isLoading)
        XCTAssertNotNil(screen)
    }

    @MainActor
    func test_availableContent_whenNotLoading_scopeReportsNotLoading() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        scope.structuredState.isLoading = false

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertFalse(scope.structuredState.isLoading)
        XCTAssertNotNil(screen)
    }

    // MARK: - Error Content Tests

    @MainActor
    func test_unavailableContent_showsAvailabilityError() {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertNotNil(scope.availabilityError)
        XCTAssertNotNil(screen)
    }

    @MainActor
    func test_unavailableContent_withCustomError_containsErrorMessage() {
        // Given
        mockPresentationManager.isPresentable = false
        mockPresentationManager.errorForDisplay = NSError(
            domain: "TestDomain",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Custom error message"]
        )
        let scope = createScope()

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertNotNil(scope.availabilityError)
        XCTAssertTrue(scope.availabilityError?.contains("Custom error message") ?? false)
        XCTAssertNotNil(screen)
    }

    // MARK: - Body Tests

    @MainActor
    func test_body_whenAvailable_createsView() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        let screen = ApplePayScreen(scope: scope)

        // When
        let body = screen.body

        // Then
        XCTAssertNotNil(body)
    }

    @MainActor
    func test_body_whenUnavailable_createsView() {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()
        let screen = ApplePayScreen(scope: scope)

        // When
        let body = screen.body

        // Then
        XCTAssertNotNil(body)
    }

    @MainActor
    func test_body_withAllContexts_createsViews() {
        // Given
        mockPresentationManager.isPresentable = true
        let contexts: [PresentationContext] = [.direct, .fromPaymentSelection]

        // When/Then
        for context in contexts {
            let scope = createScope(presentationContext: context)
            let screen = ApplePayScreen(scope: scope, presentationContext: context)
            XCTAssertNotNil(screen.body, "Failed for context: \(context)")
        }
    }

    // MARK: - Custom Button Tests

    @MainActor
    func test_applePayButton_whenCustomButtonSet_scopeHasCustomButton() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        scope.applePayButton = { _ in
            AnyView(Text("Custom Button"))
        }

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertNotNil(scope.applePayButton)
        XCTAssertNotNil(screen)
    }

    @MainActor
    func test_applePayButton_whenNotSet_scopeHasNoCustomButton() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        let screen = ApplePayScreen(scope: scope)

        // Then
        XCTAssertNil(scope.applePayButton)
        XCTAssertNotNil(screen)
    }

    // MARK: - Helper

    @MainActor
    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultApplePayScope {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: "mock_token",
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        return DefaultApplePayScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            applePayPresentationManager: mockPresentationManager
        )
    }
}

// MARK: - Mock Apple Pay Presentation Manager

@available(iOS 15.0, *)
private final class ScreenTestMockApplePayPresentationManager: ApplePayPresenting {

    var isPresentable: Bool = true
    var errorForDisplay: Error = NSError(
        domain: "ApplePay",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Apple Pay is not available"]
    )
    var onPresent: ((ApplePayRequest, PKPaymentAuthorizationControllerDelegate) -> Result<Void, Error>)?

    func present(
        withRequest request: ApplePayRequest,
        delegate: PKPaymentAuthorizationControllerDelegate
    ) async throws {
        switch onPresent?(request, delegate) {
        case .success:
            return
        case let .failure(error):
            throw error
        case nil:
            throw PrimerError.unknown()
        }
    }
}
