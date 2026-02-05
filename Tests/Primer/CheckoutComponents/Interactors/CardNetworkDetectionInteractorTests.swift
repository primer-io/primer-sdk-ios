//
//  CardNetworkDetectionInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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

    // MARK: - Network Detection Stream Tests

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

    func test_networkDetectionStream_emitsUpdatedValues() async {
        // Given
        mockRepository.networkDetectionToReturn = []

        // Setup expectation for stream values
        let expectation = XCTestExpectation(description: "Receive network updates")
        var receivedValues: [[CardNetwork]] = []

        // Create task to collect stream values
        let task = Task {
            for await networks in sut.networkDetectionStream {
                receivedValues.append(networks)
                if receivedValues.count >= 2 {
                    expectation.fulfill()
                    break
                }
            }
        }

        // When - emit a new value
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        mockRepository.emitNetworkDetection([.visa, .masterCard])

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        XCTAssertEqual(receivedValues.count, 2)
        XCTAssertEqual(receivedValues[0], []) // Initial empty
        XCTAssertEqual(receivedValues[1], [.visa, .masterCard]) // Updated
    }

    // MARK: - Detect Networks Tests

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

    // MARK: - Select Network Tests

    func test_selectNetwork_callsRepositoryWithNetwork() async {
        // Given
        let network = CardNetwork.visa

        // When
        await sut.selectNetwork(network)

        // Then
        XCTAssertEqual(mockRepository.selectCardNetworkCallCount, 1)
        XCTAssertEqual(mockRepository.lastSelectedNetwork, network)
    }

    // MARK: - Co-badged Card Flow Tests

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
}
