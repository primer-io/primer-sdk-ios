//
//  ApplePayAuthorizationCoordinatorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ApplePayAuthorizationCoordinatorTests: XCTestCase {

    // MARK: - Properties

    private var coordinator: ApplePayAuthorizationCoordinator!
    private var mockPresentationManager: CoordinatorTestMockApplePayPresentationManager!
    private var mockRequest: ApplePayRequest!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        coordinator = ApplePayAuthorizationCoordinator()
        mockPresentationManager = CoordinatorTestMockApplePayPresentationManager()
        mockRequest = createMockRequest()
    }

    override func tearDown() {
        coordinator = nil
        mockPresentationManager = nil
        mockRequest = nil
        super.tearDown()
    }

    // MARK: - Authorization Flow Tests

    func test_authorize_whenPresentationFails_throwsError() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: -1, userInfo: nil)
        mockPresentationManager.presentResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await coordinator.authorize(
                with: mockRequest,
                presentationManager: mockPresentationManager
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, expectedError.domain)
        }
    }

    func test_authorize_callsPresentationManager() async throws {
        // Given
        mockPresentationManager.presentResult = .success(())
        mockPresentationManager.shouldSimulateAuthorization = true

        // When
        let task = Task {
            try await coordinator.authorize(
                with: mockRequest,
                presentationManager: mockPresentationManager
            )
        }

        // Give time for authorization to start
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        // Then
        XCTAssertTrue(mockPresentationManager.presentWasCalled)
        XCTAssertNotNil(mockPresentationManager.lastRequest)
    }

    // MARK: - Delegate Callback Tests

    func test_didFinish_whenCancelled_resumesWithCancelledError() async {
        // Given
        mockPresentationManager.presentResult = .success(())
        mockPresentationManager.shouldSimulateCancellation = true

        // When/Then
        do {
            _ = try await coordinator.authorize(
                with: mockRequest,
                presentationManager: mockPresentationManager
            )
            XCTFail("Expected cancelled error")
        } catch let error as PrimerError {
            if case let .cancelled(paymentMethodType, _) = error {
                XCTAssertEqual(paymentMethodType, PrimerPaymentMethodType.applePay.rawValue)
            } else {
                XCTFail("Expected cancelled error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_didAuthorizePayment_resumesWithPaymentData() async throws {
        // Given
        mockPresentationManager.presentResult = .success(())
        mockPresentationManager.shouldSimulateAuthorization = true

        // When
        let result = try await coordinator.authorize(
            with: mockRequest,
            presentationManager: mockPresentationManager
        )

        // Then
        XCTAssertNotNil(result)
    }

    func test_authorize_fullFlow_succeeds() async throws {
        // Given
        mockPresentationManager.presentResult = .success(())
        mockPresentationManager.shouldSimulateAuthorization = true

        // When
        let result = try await coordinator.authorize(
            with: mockRequest,
            presentationManager: mockPresentationManager
        )

        // Then
        XCTAssertNotNil(result)
    }

    // MARK: - Helper

    private func createMockRequest() -> ApplePayRequest {
        let items = [
            // swiftlint:disable:next force_try
            try! ApplePayOrderItem(
                name: "Test Item",
                unitAmount: 1000,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil,
                isPending: false
            )
        ]

        return ApplePayRequest(
            currency: Currency(code: "GBP", decimalDigits: 2),
            merchantIdentifier: "merchant.test",
            countryCode: .gb,
            items: items
        )
    }
}

// MARK: - Mock Classes

@available(iOS 15.0, *)
private final class CoordinatorTestMockApplePayPresentationManager: ApplePayPresenting {

    var isPresentable: Bool = true
    var errorForDisplay: Error = NSError(
        domain: "ApplePay",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Apple Pay is not available"]
    )

    var presentResult: Result<Void, Error> = .success(())
    var presentWasCalled = false
    var lastRequest: ApplePayRequest?
    var shouldSimulateAuthorization = false
    var shouldSimulateCancellation = false

    func present(
        withRequest request: ApplePayRequest,
        delegate: PKPaymentAuthorizationControllerDelegate
    ) async throws {
        presentWasCalled = true
        lastRequest = request

        switch presentResult {
        case .success:
            // Simulate async behavior on main actor
            await MainActor.run {
                if shouldSimulateCancellation {
                    let mockController = CoordinatorTestMockPKPaymentAuthorizationController()
                    delegate.paymentAuthorizationControllerDidFinish(mockController)
                } else if shouldSimulateAuthorization {
                    let mockController = CoordinatorTestMockPKPaymentAuthorizationController()
                    let payment = CoordinatorTestMockPKPayment()
                    delegate.paymentAuthorizationController?(
                        mockController,
                        didAuthorizePayment: payment,
                        handler: { _ in }
                    )
                }
            }
        case let .failure(error):
            throw error
        }
    }
}

@available(iOS 15.0, *)
private final class CoordinatorTestMockPKPaymentAuthorizationController: PKPaymentAuthorizationController {

    private var _dismissed = false

    override func dismiss(completion: (() -> Void)? = nil) {
        _dismissed = true
        completion?()
    }
}

@available(iOS 15.0, *)
private final class CoordinatorTestMockPKPayment: PKPayment {

    private let _token: CoordinatorTestMockPKPaymentToken

    override var token: PKPaymentToken {
        _token
    }

    override init() {
        _token = CoordinatorTestMockPKPaymentToken()
        super.init()
    }
}

@available(iOS 15.0, *)
private final class CoordinatorTestMockPKPaymentToken: PKPaymentToken {

    override var paymentData: Data {
        Data()
    }

    override var transactionIdentifier: String {
        "mock_transaction_id"
    }

    override var paymentMethod: PKPaymentMethod {
        CoordinatorTestMockPKPaymentMethod()
    }
}

@available(iOS 15.0, *)
private final class CoordinatorTestMockPKPaymentMethod: PKPaymentMethod {

    override var displayName: String? {
        "Mock Card"
    }

    override var network: PKPaymentNetwork? {
        .visa
    }

    override var type: PKPaymentMethodType {
        .credit
    }
}
