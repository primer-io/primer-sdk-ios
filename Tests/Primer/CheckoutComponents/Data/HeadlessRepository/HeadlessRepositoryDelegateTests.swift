//
//  HeadlessRepositoryDelegateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
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

@available(iOS 15.0, *)
@MainActor
final class SelectCardNetworkDelegateTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func test_selectCardNetwork_withVisa_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.visa)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "VISA")
    }

    func test_selectCardNetwork_withMastercard_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.masterCard)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "MASTERCARD")
    }

    func test_selectCardNetwork_withAmex_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.amex)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "AMEX")
    }

    func test_selectCardNetwork_withDiscover_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.discover)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "DISCOVER")
    }

    func test_selectCardNetwork_withJCB_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.jcb)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "JCB")
    }

    func test_selectCardNetwork_withDiners_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.diners)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "DINERS_CLUB")
    }

    func test_selectCardNetwork_withCartesBancaires_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.cartesBancaires)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "CARTES_BANCAIRES")
    }

    func test_selectCardNetwork_multipleCalls_dispatchesAll() async {
        // When
        await repository.selectCardNetwork(.visa)
        await repository.selectCardNetwork(.masterCard)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 2)
    }

    func test_selectCardNetwork_always_passesPaymentCard() async {
        // When
        await repository.selectCardNetwork(.visa)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.type, "PAYMENT_CARD")
    }
}

@available(iOS 15.0, *)
@MainActor
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

// GetRequiredInputElementsDelegateTests removed — getRequiredInputElements is now private
