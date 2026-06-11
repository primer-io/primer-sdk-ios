//
//  CardNetworkDetectionInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
final class CardNetworkDetectionInteractorTests: XCTestCase {

    private var sut: CardNetworkDetectionInteractorImpl!
    private var mockRepository: MockHeadlessRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockHeadlessRepository()
        sut = CardNetworkDetectionInteractorImpl(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_networkDetectionStream_emitsInitialValue() async {
        // Given
        mockRepository.networkDetectionToReturn = [.visa]

        // When
        var receivedNetworks: [CardNetwork]?
        for await networks in sut.networkDetectionStream {
            receivedNetworks = networks
            break // Just get the first value
        }

        // Then
        XCTAssertEqual(receivedNetworks, [.visa])
    }

    func test_networkDetectionStream_emitsUpdatedValues() async throws {
        // Given - stream is created once; the initial value is buffered immediately
        mockRepository.networkDetectionToReturn = []
        let stream = sut.networkDetectionStream

        // When - emit a new value into the same buffered stream
        mockRepository.emitNetworkDetection([.visa, .masterCard])

        // Then
        let receivedValues = try await collect(stream, count: 2)
        XCTAssertEqual(receivedValues.count, 2)
        XCTAssertEqual(receivedValues[0], []) // Initial empty
        XCTAssertEqual(receivedValues[1], [.visa, .masterCard]) // Updated
    }

    func test_detectNetworks_callsRepositoryWithCardNumber() async {
        // Given
        let cardNumber = TestData.CardNumbers.validVisa

        // When
        await sut.detectNetworks(for: cardNumber)

        // Then
        XCTAssertEqual(mockRepository.updateCardNumberCallCount, 1)
        XCTAssertEqual(mockRepository.lastCardNumber, cardNumber)
    }

    func test_detectNetworks_withShortCardNumber_stillCallsRepository() async {
        // Given - short card number (less than 8 digits)
        let cardNumber = "4111"

        // When
        await sut.detectNetworks(for: cardNumber)

        // Then - repository should still be called (it handles the < 8 digit case)
        XCTAssertEqual(mockRepository.updateCardNumberCallCount, 1)
        XCTAssertEqual(mockRepository.lastCardNumber, cardNumber)
    }

    func test_detectNetworks_withEmptyString_callsRepository() async {
        // Given
        let cardNumber = ""

        // When
        await sut.detectNetworks(for: cardNumber)

        // Then
        XCTAssertEqual(mockRepository.updateCardNumberCallCount, 1)
        XCTAssertEqual(mockRepository.lastCardNumber, cardNumber)
    }

    func test_detectNetworks_multipleCalls_updatesEachTime() async {
        // Given
        let cardNumbers = ["4111", "41111111", TestData.CardNumbers.validVisa]

        // When
        for cardNumber in cardNumbers {
            await sut.detectNetworks(for: cardNumber)
        }

        // Then
        XCTAssertEqual(mockRepository.updateCardNumberCallCount, 3)
        XCTAssertEqual(mockRepository.lastCardNumber, TestData.CardNumbers.validVisa)
    }

    func test_selectNetwork_callsRepositoryWithNetwork() async {
        // Given
        let network = CardNetwork.visa

        // When
        await sut.selectNetwork(network)

        // Then
        XCTAssertEqual(mockRepository.selectCardNetworkCallCount, 1)
        XCTAssertEqual(mockRepository.lastSelectedNetwork, network)
    }

    func test_coBadgedFlow_detectThenSelect() async {
        // Given - simulate co-badged card detection
        mockRepository.networkDetectionToReturn = [.visa, .masterCard]

        // When - detect networks first
        await sut.detectNetworks(for: TestData.CardNumbers.validVisa)

        // Then - select one network
        await sut.selectNetwork(.visa)

        // Verify flow
        XCTAssertEqual(mockRepository.updateCardNumberCallCount, 1)
        XCTAssertEqual(mockRepository.selectCardNetworkCallCount, 1)
        XCTAssertEqual(mockRepository.lastSelectedNetwork, .visa)
    }

    func test_binDataStream_emitsCompleteBinData() async {
        // Given
        let binData = PrimerBinData(
            preferred: PrimerCardNetwork(network: .visa),
            alternatives: [PrimerCardNetwork(network: .masterCard)],
            status: .complete,
            firstDigits: "552266"
        )
        mockRepository.binDataToReturn = binData

        // When
        var receivedBinData: PrimerBinData?
        for await data in sut.binDataStream {
            receivedBinData = data
            break
        }

        // Then
        XCTAssertEqual(receivedBinData?.status, .complete)
        XCTAssertEqual(receivedBinData?.firstDigits, "552266")
        XCTAssertEqual(receivedBinData?.preferred?.network, .visa)
        XCTAssertEqual(receivedBinData?.alternatives.count, 1)
        XCTAssertEqual(receivedBinData?.alternatives.first?.network, .masterCard)
    }

    func test_binDataStream_emitsPartialBinData() async {
        // Given
        let binData = PrimerBinData(
            preferred: PrimerCardNetwork(network: .visa),
            alternatives: [],
            status: .partial,
            firstDigits: nil
        )
        mockRepository.binDataToReturn = binData

        // When
        var receivedBinData: PrimerBinData?
        for await data in sut.binDataStream {
            receivedBinData = data
            break
        }

        // Then
        XCTAssertEqual(receivedBinData?.status, .partial)
        XCTAssertNil(receivedBinData?.firstDigits)
        XCTAssertEqual(receivedBinData?.preferred?.network, .visa)
        XCTAssertTrue(receivedBinData?.alternatives.isEmpty ?? false)
    }

    func test_binDataStream_emitsUpdatedValues() async throws {
        // Given - no initial value is buffered (binDataToReturn is nil)
        let stream = sut.binDataStream

        // When - emit a new value into the same buffered stream
        let binData = PrimerBinData(
            preferred: PrimerCardNetwork(network: .visa),
            alternatives: [],
            status: .complete,
            firstDigits: "411111"
        )
        mockRepository.emitBinData(binData)

        // Then
        let received = try await awaitFirst(stream)
        XCTAssertEqual(received.status, .complete)
        XCTAssertEqual(received.firstDigits, "411111")
    }
}
