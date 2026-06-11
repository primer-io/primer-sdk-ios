//
//  HeadlessRepositoryDelegateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

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

    /// `selectCardNetwork` dispatches via a detached `Task`, so the recorded call lands asynchronously.
    /// Polls the mock's recorded calls until at least `count` are observed, deterministically replacing fixed sleeps.
    private func awaitSelectPaymentMethodCalls(
        atLeast count: Int,
        timeout: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await withTimeout(timeout) { [self] in
                while mockClientSessionActions.selectPaymentMethodCalls.count < count {
                    await Task.yield()
                }
            }
        } catch {
            XCTFail(
                "Timed out waiting for \(count) selectPaymentMethod call(s); "
                    + "recorded \(mockClientSessionActions.selectPaymentMethodCalls.count)",
                file: file,
                line: line
            )
        }
    }

    func test_selectCardNetwork_withVisa_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.visa)
        await awaitSelectPaymentMethodCalls(atLeast: 1)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "VISA")
    }

    func test_selectCardNetwork_withMastercard_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.masterCard)
        await awaitSelectPaymentMethodCalls(atLeast: 1)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "MASTERCARD")
    }

    func test_selectCardNetwork_withAmex_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.amex)
        await awaitSelectPaymentMethodCalls(atLeast: 1)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "AMEX")
    }

    func test_selectCardNetwork_withDiscover_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.discover)
        await awaitSelectPaymentMethodCalls(atLeast: 1)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "DISCOVER")
    }

    func test_selectCardNetwork_withJCB_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.jcb)
        await awaitSelectPaymentMethodCalls(atLeast: 1)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "JCB")
    }

    func test_selectCardNetwork_withDiners_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.diners)
        await awaitSelectPaymentMethodCalls(atLeast: 1)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "DINERS_CLUB")
    }

    func test_selectCardNetwork_withCartesBancaires_dispatchesCorrectAction() async {
        // When
        await repository.selectCardNetwork(.cartesBancaires)
        await awaitSelectPaymentMethodCalls(atLeast: 1)

        // Then
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "CARTES_BANCAIRES")
    }

    func test_selectCardNetwork_multipleCalls_dispatchesAll() async {
        // When
        await repository.selectCardNetwork(.visa)
        await repository.selectCardNetwork(.masterCard)
        await awaitSelectPaymentMethodCalls(atLeast: 2)

        // Then
        XCTAssertGreaterThanOrEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 2)
    }

    func test_selectCardNetwork_always_passesPaymentCard() async {
        // When
        await repository.selectCardNetwork(.visa)
        await awaitSelectPaymentMethodCalls(atLeast: 1)

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
        // Register PAYMENT_CARD so RawDataManager init succeeds during metadata seeding.
        SDKSessionHelper.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    /// Seeds `lastDetectedNetworks` with `[.visa]` by driving the metadata delegate, so a subsequent
    /// sub-BIN-threshold card number produces an observable `[]` emission. Returns the network
    /// detection stream after the seed value has been consumed.
    private func seededNetworkStream() async throws -> AsyncStream<[CardNetwork]> {
        let stream = repository.getNetworkDetectionStream()
        let metadata = PrimerCardNumberEntryMetadata(
            source: .local,
            selectableCardNetworks: nil,
            detectedCardNetworks: [PrimerCardNetwork(displayName: "Visa", network: .visa)]
        )
        let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
            paymentMethodType: "PAYMENT_CARD"
        )
        repository.primerRawDataManager(
            rawDataManager,
            didReceiveMetadata: metadata,
            forState: PrimerCardNumberEntryState(cardNumber: "4242424242424242")
        )
        // Consume the seed emission so later assertions observe only update-driven values.
        let seededNetworks = try await awaitValue(stream, equalTo: [.visa])
        XCTAssertEqual(seededNetworks, [.visa])
        return stream
    }

    /// Asserts the stream emits no further value within `window`. Used to prove a card-number update
    /// at/above the BIN threshold leaves the previously detected networks intact.
    private func assertNoFurtherEmission(
        _ stream: AsyncStream<[CardNetwork]>,
        window: TimeInterval = 0.3
    ) async {
        do {
            let unexpected = try await awaitFirst(stream, timeout: window)
            XCTFail("Expected no emission, got \(unexpected)")
        } catch AsyncTestError.timeout {
            // Success - networks were preserved, nothing emitted.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateCardNumber_WithFullCardNumber_KeepsDetectedNetworks() async throws {
        // Given - networks already detected for a full card number
        let stream = try await seededNetworkStream()

        // When - a full (16-digit) number is entered
        await repository.updateCardNumberInRawDataManager("4242424242424242")

        // Then - staying above the BIN threshold preserves the detected networks (no clear emitted)
        await assertNoFurtherEmission(stream)
    }

    func testUpdateCardNumber_WithSpacedCardNumber_StripsSpaces() async throws {
        // Given - networks already detected
        let stream = try await seededNetworkStream()

        // When - 13 raw chars (>= 8) but only 7 digits once spaces are stripped
        await repository.updateCardNumberInRawDataManager("4 2 4 2 4 2 4")

        // Then - stripping drops the value below the 8-digit BIN threshold, clearing networks.
        // Without stripping the 13-char string would stay above the threshold and emit nothing.
        let clearedNetworks = try await awaitValue(stream, equalTo: [])
        XCTAssertEqual(clearedNetworks, [])
    }

    func testUpdateCardNumber_WithEmptyString_ClearsDetectedNetworks() async throws {
        // Given - networks already detected
        let stream = try await seededNetworkStream()

        // When - the field is cleared
        await repository.updateCardNumberInRawDataManager("")

        // Then - networks are cleared below the BIN-lookup threshold
        let clearedNetworks = try await awaitValue(stream, equalTo: [])
        XCTAssertEqual(clearedNetworks, [])
    }

    func testUpdateCardNumber_WithShortNumber_ClearsDetectedNetworks() async throws {
        // Given - networks already detected
        let stream = try await seededNetworkStream()

        // When - fewer than 8 digits
        await repository.updateCardNumberInRawDataManager("4242")

        // Then - networks are cleared below the BIN-lookup threshold
        let clearedNetworks = try await awaitValue(stream, equalTo: [])
        XCTAssertEqual(clearedNetworks, [])
    }

    func testUpdateCardNumber_WithExactBINLength_KeepsDetectedNetworks() async throws {
        // Given - networks already detected
        let stream = try await seededNetworkStream()

        // When - exactly 8 digits (at the threshold, not below it)
        await repository.updateCardNumberInRawDataManager("42424242")

        // Then - the 8-digit value sits at the threshold and must not clear networks
        await assertNoFurtherEmission(stream)
    }

    func testUpdateCardNumber_CalledMultipleTimes_ClearsOnFirstThresholdCrossing() async throws {
        // Given - networks already detected
        let stream = try await seededNetworkStream()

        // When - cross below the threshold, climb back above it, then clear
        await repository.updateCardNumberInRawDataManager("4242")
        await repository.updateCardNumberInRawDataManager("42424242")
        await repository.updateCardNumberInRawDataManager("4242424242424242")
        await repository.updateCardNumberInRawDataManager("")

        // Then - the first below-threshold update clears the seeded networks
        let clearedNetworks = try await awaitValue(stream, equalTo: [])
        XCTAssertEqual(clearedNetworks, [])
    }
}

// GetRequiredInputElementsDelegateTests removed — getRequiredInputElements is now private
