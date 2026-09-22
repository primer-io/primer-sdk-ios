//
//  ApplePayAuthorizationCoordinatorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Contacts
import PassKit
@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
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
        let task = Task { [self] in
            try await coordinator.authorize(
                with: mockRequest,
                presentationManager: mockPresentationManager
            )
        }

        // Wait until the presentation manager has actually been invoked
        try await withTimeout(2.0) { [self] in
            while !mockPresentationManager.presentWasCalled {
                await Task.yield()
            }
        }
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

    // MARK: - Shipping Delegates

    /// Before the coordinator implemented this delegate, PassKit kept the request's own list across
    /// address edits. An update that omits them clears the sheet, so legacy merchants must get
    /// their baked-in options back.
    func test_didSelectShippingContact_legacyMode_resendsTheRequestsShippingMethods() async throws {
        let method = PKShippingMethod(label: "Standard", amount: 5)
        method.identifier = "standard"
        let request = createMockRequest(shippingMethods: [method])
        let coordinator = ApplePayAuthorizationCoordinator(shippingSession: makeSession(mode: .legacy))
        try await present(coordinator, with: request)

        let update = await coordinator.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingContact: contact(countryCode: "GB")
        )

        XCTAssertEqual(update.shippingMethods.map(\.identifier), ["standard"])
    }

    func test_didSelectShippingContact_callbacksMode_showsTheMerchantsOptions() async throws {
        let coordinator = ApplePayAuthorizationCoordinator(
            shippingSession: makeSession(
                mode: .callbacks,
                options: [
                    PrimerShippingOption(id: "standard", name: "Standard", description: "3-5 days", amount: 500),
                    PrimerShippingOption(id: "express", name: "Express", description: "Next day", amount: 1500)
                ]
            )
        )
        try await present(coordinator, with: createMockRequest())

        let update = await coordinator.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingContact: contact(countryCode: "GB")
        )

        XCTAssertEqual(update.shippingMethods.map(\.identifier), ["standard", "express"])
        XCTAssertEqual(update.shippingMethods.first?.label, "Standard")
        XCTAssertEqual(update.shippingMethods.first?.detail, "3-5 days")
        XCTAssertTrue(update.errors.isEmpty)
    }

    func test_didSelectShippingContact_emptyList_showsTheUnserviceableAddressError() async throws {
        let coordinator = ApplePayAuthorizationCoordinator(
            shippingSession: makeSession(mode: .callbacks, options: [])
        )
        try await present(coordinator, with: createMockRequest())

        let update = await coordinator.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingContact: contact(countryCode: "GB")
        )

        XCTAssertTrue(update.shippingMethods.isEmpty)
        XCTAssertEqual((update.errors.first as? NSError)?.code, PKPaymentError.shippingAddressUnserviceableError.rawValue)
    }

    func test_address_splitsTheStreetIntoTwoLines() {
        let address = ApplePayAuthorizationCoordinator.address(from: contact(countryCode: "GB", street: "1 High Street\nFlat 2"))

        XCTAssertEqual(address.addressLine1, "1 High Street")
        XCTAssertEqual(address.addressLine2, "Flat 2")
        XCTAssertEqual(address.city, "London")
        XCTAssertEqual(address.postalCode, "SW1A 1AA")
        XCTAssertEqual(address.countryCode, "GB")
    }

    func test_address_withoutAPostalAddress_isEmpty() {
        let address = ApplePayAuthorizationCoordinator.address(from: PKContact())

        XCTAssertNil(address.addressLine1)
        XCTAssertNil(address.countryCode)
    }

    // MARK: - Helper

    /// Drives the coordinator to the point where it has recorded the request, without waiting for the
    /// authorization it never receives here.
    private func present(_ coordinator: ApplePayAuthorizationCoordinator, with request: ApplePayRequest) async throws {
        let manager = CoordinatorTestMockApplePayPresentationManager()
        manager.presentResult = .success(())
        Task { _ = try? await coordinator.authorize(with: request, presentationManager: manager) }
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    private func makeSession(
        mode: ApplePayShippingSession.Mode,
        options: [PrimerShippingOption] = []
    ) -> ApplePayShippingSession {
        // The merchant's backend is stubbed as already holding the default option, so the eager commit
        // that follows an address change verifies and the delegate takes its success path.
        let committed = options.first
        return ApplePayShippingSession(
            mode: mode,
            requireShippingMethod: true,
            addressChangeProvider: { { _ in options } },
            optionChangeProvider: { { _ in } },
            refreshConfiguration: {},
            currentShipping: {
                committed.map {
                    ClientSession.Order.ShippingMethod(
                        amount: $0.amount,
                        methodId: $0.id,
                        methodName: $0.name,
                        methodDescription: $0.description
                    )
                }
            }
        )
    }

    private func contact(countryCode: String, street: String = "1 High Street") -> PKContact {
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = street
        postalAddress.city = "London"
        postalAddress.postalCode = "SW1A 1AA"
        postalAddress.isoCountryCode = countryCode

        let contact = PKContact()
        contact.postalAddress = postalAddress
        return contact
    }

    private func createMockRequest(shippingMethods: [PKShippingMethod]? = nil) -> ApplePayRequest {
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
            items: items,
            shippingMethods: shippingMethods
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
            await MainActor.run {
                if shouldSimulateCancellation {
                    let mockController = CoordinatorTestMockPKPaymentAuthorizationController()
                    delegate.paymentAuthorizationControllerDidFinish(mockController)
                } else if shouldSimulateAuthorization {
                    let mockController = CoordinatorTestMockPKPaymentAuthorizationController()
                    let payment = SharedMockPKPayment()
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
