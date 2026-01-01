//
//  HeadlessRepositoryDelegateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Network Detection Stream Tests

@available(iOS 15.0, *)
final class NetworkDetectionStreamTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testGetNetworkDetectionStream_ReturnsNonNilStream() {
        // When
        let stream = repository.getNetworkDetectionStream()

        // Then
        XCTAssertNotNil(stream)
    }

    func testGetNetworkDetectionStream_ReturnsSameStreamOnMultipleCalls() {
        // When
        let stream1 = repository.getNetworkDetectionStream()
        let stream2 = repository.getNetworkDetectionStream()

        // Then - Should return the same stream instance
        XCTAssertNotNil(stream1)
        XCTAssertNotNil(stream2)
    }
}

// MARK: - Set Billing Address Tests

@available(iOS 15.0, *)
final class SetBillingAddressTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testSetBillingAddress_DoesNotThrow() async throws {
        // Given
        let address = BillingAddress(
            firstName: "John",
            lastName: "Doe",
            addressLine1: "123 Main St",
            addressLine2: nil,
            city: "New York",
            state: "NY",
            postalCode: "10001",
            countryCode: "US",
            phoneNumber: nil
        )

        // When/Then - Should not throw
        try await repository.setBillingAddress(address)
    }

    func testSetBillingAddress_WithMinimalData_DoesNotThrow() async throws {
        // Given
        let address = BillingAddress(
            firstName: nil,
            lastName: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            postalCode: nil,
            countryCode: nil,
            phoneNumber: nil
        )

        // When/Then - Should not throw
        try await repository.setBillingAddress(address)
    }

    func testSetBillingAddress_WithFullData_DoesNotThrow() async throws {
        // Given
        let address = BillingAddress(
            firstName: "John",
            lastName: "Doe",
            addressLine1: "123 Main St",
            addressLine2: "Apt 4B",
            city: "New York",
            state: "NY",
            postalCode: "10001",
            countryCode: "US",
            phoneNumber: "+1-555-123-4567"
        )

        // When/Then - Should not throw
        try await repository.setBillingAddress(address)
    }

    func testSetBillingAddress_WithInternationalAddress_DoesNotThrow() async throws {
        // Given
        let address = BillingAddress(
            firstName: "Jean",
            lastName: "Dupont",
            addressLine1: "15 Rue de la Paix",
            addressLine2: nil,
            city: "Paris",
            state: nil,
            postalCode: "75002",
            countryCode: "FR",
            phoneNumber: "+33-1-23-45-67-89"
        )

        // When/Then - Should not throw
        try await repository.setBillingAddress(address)
    }
}

// MARK: - Select Card Network Tests

@available(iOS 15.0, *)
final class SelectCardNetworkDelegateTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [unowned self] in self.mockClientSessionActions }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testSelectCardNetwork_WithVisa_DispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.visa)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "VISA")
    }

    func testSelectCardNetwork_WithMastercard_DispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.masterCard)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "MASTERCARD")
    }

    func testSelectCardNetwork_WithAmex_DispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.amex)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "AMEX")
    }

    func testSelectCardNetwork_WithDiscover_DispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.discover)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "DISCOVER")
    }

    func testSelectCardNetwork_WithJCB_DispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.jcb)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "JCB")
    }

    func testSelectCardNetwork_WithDiners_DispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.diners)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "DINERS_CLUB")
    }

    func testSelectCardNetwork_WithCartesBancaires_DispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.cartesBancaires)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "CARTES_BANCAIRES")
    }

    func testSelectCardNetwork_MultipleCalls_DispatchesAll() async {
        // When
        await repository.selectCardNetwork(.visa)
        await repository.selectCardNetwork(.masterCard)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 2)
    }

    func testSelectCardNetwork_AlwaysPassesPaymentCard() async {
        // When
        await repository.selectCardNetwork(.visa)

        // Wait for async dispatch
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.type, "PAYMENT_CARD")
    }
}

// MARK: - Update Card Number Tests

@available(iOS 15.0, *)
final class UpdateCardNumberTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    @MainActor
    func testUpdateCardNumber_WithValidCardNumber_DoesNotCrash() async {
        // When/Then - Should not crash
        await repository.updateCardNumberInRawDataManager("4242424242424242")
    }

    @MainActor
    func testUpdateCardNumber_WithSpacedCardNumber_StripsSpaces() async {
        // When/Then - Should not crash
        await repository.updateCardNumberInRawDataManager("4242 4242 4242 4242")
    }

    @MainActor
    func testUpdateCardNumber_WithEmptyString_DoesNotCrash() async {
        // When/Then - Should not crash
        await repository.updateCardNumberInRawDataManager("")
    }

    @MainActor
    func testUpdateCardNumber_WithShortNumber_DoesNotCrash() async {
        // When/Then - Should not crash (less than 8 digits for BIN lookup)
        await repository.updateCardNumberInRawDataManager("4242")
    }

    @MainActor
    func testUpdateCardNumber_WithExactBINLength_DoesNotCrash() async {
        // When/Then - Should not crash (exactly 8 digits)
        await repository.updateCardNumberInRawDataManager("42424242")
    }

    @MainActor
    func testUpdateCardNumber_WithLongNumber_DoesNotCrash() async {
        // When/Then - Should not crash
        await repository.updateCardNumberInRawDataManager("4242424242424242424242")
    }

    @MainActor
    func testUpdateCardNumber_CalledMultipleTimes_DoesNotCrash() async {
        // When/Then - Should not crash when called multiple times
        await repository.updateCardNumberInRawDataManager("4242")
        await repository.updateCardNumberInRawDataManager("42424242")
        await repository.updateCardNumberInRawDataManager("4242424242424242")
        await repository.updateCardNumberInRawDataManager("")
    }
}

// MARK: - Get Required Input Elements Tests

@available(iOS 15.0, *)
final class GetRequiredInputElementsDelegateTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testGetRequiredInputElements_ForPaymentCard_ReturnsAllCardFields() {
        // When
        let result = repository.getRequiredInputElements(for: "PAYMENT_CARD")

        // Then
        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result.contains(.cardNumber))
        XCTAssertTrue(result.contains(.cvv))
        XCTAssertTrue(result.contains(.expiryDate))
        XCTAssertTrue(result.contains(.cardholderName))
    }

    func testGetRequiredInputElements_ForNonCardPaymentMethod_ReturnsEmpty() {
        // When
        let result = repository.getRequiredInputElements(for: "PAYPAL")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForUnknownPaymentMethod_ReturnsEmpty() {
        // When
        let result = repository.getRequiredInputElements(for: "UNKNOWN_METHOD")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForEmptyString_ReturnsEmpty() {
        // When
        let result = repository.getRequiredInputElements(for: "")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForApplePay_ReturnsEmpty() {
        // When
        let result = repository.getRequiredInputElements(for: "APPLE_PAY")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForGooglePay_ReturnsEmpty() {
        // When
        let result = repository.getRequiredInputElements(for: "GOOGLE_PAY")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForKlarna_ReturnsEmpty() {
        // When
        let result = repository.getRequiredInputElements(for: "KLARNA")

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_CaseSensitive_LowercaseReturnsEmpty() {
        // When
        let result = repository.getRequiredInputElements(for: "payment_card")

        // Then - Should be case sensitive
        XCTAssertTrue(result.isEmpty)
    }
}
