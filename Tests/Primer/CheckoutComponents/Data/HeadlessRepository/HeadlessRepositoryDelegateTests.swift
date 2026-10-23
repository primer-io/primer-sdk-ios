//
//  HeadlessRepositoryDelegateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
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
