//
//  CardValidationServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class CardValidationServiceTests: XCTestCase {
    // MARK: - Properties
    
    private var delegate: MockRawDataManagerDelegate!
    private var rawDataManager: RawDataManager!
    private var apiClient: MockBINDataAPIClient!
    private var debouncer: Debouncer!
    private var sut: CardValidationService!
    
    // MARK: - Test Constants
    
    private var maxBinLength: Int {
        DefaultCardValidationService.maximumBinLength
    }
    
    private enum TestConstants {
        static let shortCardNumber = "5555"
        static let mediumCardNumber = "5555226611"
        static let fullCardNumber = "552266117788"
        static let alternativeCardNumber = "552366117788"
        static let standardTimeout: TimeInterval = 5.0
        static let shortTimeout: TimeInterval = 2.0
    }

    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        SDKSessionHelper.setUp()
        
        delegate = MockRawDataManagerDelegate()
        rawDataManager = try RawDataManager(paymentMethodType: Mocks.PaymentMethods.paymentCardPaymentMethod.type)
        rawDataManager.delegate = delegate
        apiClient = MockBINDataAPIClient()
        debouncer = Debouncer(delay: 0.275)
    }

    override func tearDownWithError() throws {
        sut = nil
        rawDataManager?.delegate = nil
        rawDataManager = nil
        delegate = nil
        apiClient = nil
        debouncer = nil
        
        SDKSessionHelper.tearDown()
        try super.tearDownWithError()
    }

    // MARK: - Local Validation Tests
    
    func testFourDigitCardNumber_noRemoteValidation() throws {
        // Given
        sut = createCardValidationService()
        let metadataExpectation = expectation(description: "Local metadata received")
        
        // When
        delegate.onWillFetchCardMetadataForState = { _, _ in
            XCTFail("Remote validation should not be triggered for short card numbers")
        }
        
        delegate.onMetadataForCardValidationState = { _, networks, _ in
            XCTAssertEqual(networks.source, .local, "Should use local validation for incomplete BIN")
            metadataExpectation.fulfill()
        }
        
        // Then
        sut.validateCardNetworks(withCardNumber: TestConstants.shortCardNumber)
        
        wait(for: [metadataExpectation], timeout: TestConstants.shortTimeout)
    }

    // MARK: - Remote Validation Tests
    
    func testSixDigitCardNumber_startRemoteValidation() throws {
        // Given
        sut = createCardValidationService()
        let willFetchExpectation = expectation(description: "Remote validation initiated")
        
        // When
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, TestConstants.mediumCardNumber, "Card state should match input")
            willFetchExpectation.fulfill()
        }
        
        // Then
        sut.validateCardNetworks(withCardNumber: TestConstants.mediumCardNumber)
        
        wait(for: [willFetchExpectation], timeout: TestConstants.shortTimeout)
    }

    func testTwelveDigitCardNumber_fastEntry_successfulValidation() throws {
        // Given
        sut = createCardValidationService(allowedNetworks: [.visa, .masterCard])
        let bin = String(TestConstants.fullCardNumber.prefix(maxBinLength))
        configureMockAPIClient(bin: bin, networks: ["VISA", "MASTERCARD"])
        
        let willFetchExpectation = expectation(description: "Remote validation initiated")
        let metadataExpectation = expectation(description: "Remote metadata received")
        
        // When
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, bin, "Should fetch metadata for complete BIN")
            willFetchExpectation.fulfill()
        }
        
        delegate.onMetadataForCardValidationState = { _, networks, cardState in
            guard networks.detectedCardNetworks.items.count > 1,
                  networks.source == .remote,
                  cardState.cardNumber == bin else { return }
            
            self.assertRemoteValidationResult(
                networks: networks,
                expectedNetworks: [("Visa", "VISA"), ("Mastercard", "MASTERCARD")],
                shouldHaveSelectableNetworks: true
            )
            metadataExpectation.fulfill()
        }
        
        // Then
        enterCardNumber(TestConstants.fullCardNumber)
        
        wait(for: [willFetchExpectation, metadataExpectation], timeout: TestConstants.standardTimeout)
    }

    func testTwelveDigitCardNumber_replaceNumber_successfulValidation() throws {
        // Given
        sut = createCardValidationService(allowedNetworks: [.visa, .masterCard, .cartesBancaires])
        let firstBin = String(TestConstants.fullCardNumber.prefix(maxBinLength))
        let secondBin = String(TestConstants.alternativeCardNumber.prefix(maxBinLength))
        
        configureMockAPIClient(bin: firstBin, networks: ["VISA", "CARTES_BANCAIRES"])
        configureMockAPIClient(bin: secondBin, networks: ["MASTERCARD", "CARTES_BANCAIRES"])
        
        let firstCardExpectation = expectation(description: "First card validation completed")
        let secondCardExpectation = expectation(description: "Second card validation completed")
        
        // When
        delegate.onMetadataForCardValidationState = { _, networks, cardState in
            guard networks.source == .remote else { return }
            
            if cardState.cardNumber == firstBin {
                self.assertRemoteValidationResult(
                    networks: networks,
                    expectedNetworks: [("Visa", "VISA"), ("Cartes Bancaires", "CARTES_BANCAIRES")],
                    shouldHaveSelectableNetworks: true
                )
                firstCardExpectation.fulfill()
            } else if cardState.cardNumber == secondBin {
                self.assertRemoteValidationResult(
                    networks: networks,
                    expectedNetworks: [("Mastercard", "MASTERCARD"), ("Cartes Bancaires", "CARTES_BANCAIRES")],
                    shouldHaveSelectableNetworks: true
                )
                secondCardExpectation.fulfill()
            }
        }
        
        // Then
        enterCardNumber(TestConstants.fullCardNumber, TestConstants.alternativeCardNumber)
        
        wait(for: [firstCardExpectation, secondCardExpectation], timeout: 10.0)
    }

    func testTwelveDigitCardNumber_allowedSubset_successfulValidation() throws {
        // Given
        sut = createCardValidationService(allowedNetworks: [.visa, .cartesBancaires])
        let bin = String(TestConstants.fullCardNumber.prefix(maxBinLength))
        configureMockAPIClient(bin: bin, networks: ["VISA", "MASTERCARD", "CARTES_BANCAIRES"])
        
        let willFetchExpectation = expectation(description: "Remote validation initiated")
        let metadataExpectation = expectation(description: "Filtered metadata received")
        
        // When
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, bin, "Should fetch metadata for complete BIN")
            willFetchExpectation.fulfill()
        }
        
        delegate.onMetadataForCardValidationState = { _, networks, cardState in
            guard networks.detectedCardNetworks.items.count > 1,
                  networks.source == .remote,
                  cardState.cardNumber == bin else { return }
            
            // Should have 2 selectable networks (allowed subset)
            XCTAssertNotNil(networks.selectableCardNetworks, "Should have selectable networks")
            XCTAssertEqual(networks.selectableCardNetworks?.items.count, 2, "Should filter to allowed networks")
            
            // Should have 3 detected networks (all from API)
            XCTAssertEqual(networks.detectedCardNetworks.items.count, 3, "Should show all detected networks")
            
            self.assertSelectableNetworks(
                networks.selectableCardNetworks?.items,
                expectedNetworks: [("Visa", "VISA"), ("Cartes Bancaires", "CARTES_BANCAIRES")]
            )
            
            self.assertDetectedNetworks(
                networks.detectedCardNetworks.items,
                expectedNetworks: [("Visa", "VISA"), ("Cartes Bancaires", "CARTES_BANCAIRES"), ("Mastercard", "MASTERCARD")]
            )
            
            metadataExpectation.fulfill()
        }
        
        // Then
        enterCardNumber(TestConstants.fullCardNumber)
        
        wait(for: [willFetchExpectation, metadataExpectation], timeout: TestConstants.standardTimeout)
    }

    func testTwelveDigitCardNumber_unallowedNetworks_successfulValidation() throws {
        // Given
        sut = createCardValidationService(allowedNetworks: [.visa, .masterCard])
        let bin = String(TestConstants.fullCardNumber.prefix(maxBinLength))
        configureMockAPIClient(bin: bin, networks: ["CARTES_BANCAIRES"])
        
        let willFetchExpectation = expectation(description: "Remote validation initiated")
        let metadataExpectation = expectation(description: "Unallowed network metadata received")
        
        // When
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, bin, "Should fetch metadata for complete BIN")
            willFetchExpectation.fulfill()
        }
        
        delegate.onMetadataForCardValidationState = { _, networks, cardState in
            guard cardState.cardNumber == bin,
                  networks.source == .remote else { return }
            
            // No selectable networks (none are allowed)
            XCTAssertNil(networks.selectableCardNetworks, "Should have no selectable networks when none are allowed")
            
            // Should show detected network even if not allowed
            XCTAssertEqual(networks.detectedCardNetworks.items.count, 1, "Should show detected network")
            XCTAssertEqual(networks.detectedCardNetworks.items[0].displayName, "Cartes Bancaires")
            XCTAssertEqual(networks.detectedCardNetworks.items[0].network.rawValue, "CARTES_BANCAIRES")
            XCTAssertNil(networks.detectedCardNetworks.preferred, "Should have no preferred network")
            
            metadataExpectation.fulfill()
        }
        
        // Then
        enterCardNumber(TestConstants.fullCardNumber)
        
        wait(for: [willFetchExpectation, metadataExpectation], timeout: TestConstants.standardTimeout)
    }

    // MARK: - Error Handling Tests
    
    func testRemoteValidationError_fallsBackToLocal() throws {
        // Given
        sut = createCardValidationService()
        apiClient.error = PrimerError.unknown()
        
        let willFetchExpectation = expectation(description: "Remote validation initiated")
        let fallbackExpectation = expectation(description: "Local fallback triggered")
        
        // When
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            let expectedBin = String(TestConstants.fullCardNumber.prefix(self.maxBinLength))
            XCTAssertEqual(cardState.cardNumber, expectedBin, "Should attempt remote validation for complete BIN")
            willFetchExpectation.fulfill()
        }
        
        delegate.onMetadataForCardValidationState = { _, networks, cardState in
            let expectedBin = String(TestConstants.fullCardNumber.prefix(self.maxBinLength))
            
            // Should receive local fallback validation
            if networks.source == .localFallback, cardState.cardNumber == expectedBin {
                XCTAssertEqual(networks.detectedCardNetworks.items.count, 1, "Should detect one network locally")
                fallbackExpectation.fulfill()
            }
        }
        
        // Then
        enterCardNumber(TestConstants.fullCardNumber)
        
        wait(for: [willFetchExpectation, fallbackExpectation], timeout: TestConstants.standardTimeout)
    }

    // MARK: - Metadata Creation Tests
    
    func testCreateValidationMetadata_allAllowed_differentOrder() {
        // Given
        let sut = createCardValidationService(allowedNetworks: [.visa, .masterCard])
        
        // When
        let metadata = sut.createValidationMetadata(networks: [.masterCard, .visa], source: .remote)
        
        // Then
        XCTAssertEqual(metadata.source, .remote, "Should preserve source")
        XCTAssertEqual(
            metadata.selectableCardNetworks?.items.map { $0.network },
            [.visa, .masterCard],
            "Should order selectable networks according to allowed list"
        )
        XCTAssertEqual(
            metadata.detectedCardNetworks.items.map { $0.network },
            [.visa, .masterCard],
            "Should include all allowed networks in detected list"
        )
    }

    func testCreateValidationMetadata_noneAllowed_differentOrder() {
        // Given
        let sut = createCardValidationService(allowedNetworks: [.amex])
        
        // When
        let metadata = sut.createValidationMetadata(networks: [.masterCard, .visa], source: .remote)
        
        // Then
        XCTAssertEqual(metadata.source, .remote, "Should preserve source")
        XCTAssertNil(metadata.selectableCardNetworks, "Should have no selectable networks when none are allowed")
        XCTAssertEqual(
            metadata.detectedCardNetworks.items.map { $0.network },
            [.masterCard, .visa],
            "Should show all detected networks even if none are allowed"
        )
    }

    func testCreateValidationMetadata_someAllowed_someOrdered() {
        // Given
        let sut = createCardValidationService(allowedNetworks: [.masterCard, .visa, .jcb, .amex])
        
        // When
        let metadata = sut.createValidationMetadata(
            networks: [.masterCard, .visa, .amex, .elo, .jcb],
            source: .remote
        )
        
        // Then
        XCTAssertEqual(metadata.source, .remote, "Should preserve source")
        XCTAssertEqual(
            metadata.selectableCardNetworks?.items.map { $0.network },
            [.masterCard, .visa, .jcb, .amex],
            "Should order selectable networks according to allowed list"
        )
        XCTAssertEqual(
            metadata.detectedCardNetworks.items.map { $0.network },
            [.masterCard, .visa, .jcb, .amex, .elo],
            "Should include allowed networks first, then unallowed"
        )
    }

    // MARK: - Helper Methods
    
    private func createCardValidationService(
        allowedNetworks: [CardNetwork] = [CardNetwork].allowedCardNetworks
    ) -> CardValidationService {
        DefaultCardValidationService(
            rawDataManager: rawDataManager,
            allowedCardNetworks: allowedNetworks,
            apiClient: apiClient
        )
    }
    
    private func configureMockAPIClient(bin: String, networks: [String]) {
        apiClient.results[bin] = .init(networks: networks.map { .init(value: $0) })
    }
    
    private func enterCardNumber(
        _ cardFragment: String,
        _ altCardFragment: String? = nil
    ) {
        let typer = StringTyper { [weak self] string in
            self?.sut?.validateCardNetworks(withCardNumber: string)
        }
        
        if let altCardFragment = altCardFragment {
            typer.type(cardFragment) {
                typer.delete(cardFragment) {
                    typer.type(altCardFragment)
                }
            }
        } else {
            typer.type(cardFragment)
        }
    }
    
    private func assertRemoteValidationResult(
        networks: PrimerCardNumberEntryMetadata,
        expectedNetworks: [(displayName: String, rawValue: String)],
        shouldHaveSelectableNetworks: Bool
    ) {
        XCTAssertEqual(networks.source, .remote, "Should use remote validation")
        
        if shouldHaveSelectableNetworks {
            XCTAssertNotNil(networks.selectableCardNetworks, "Should have selectable networks")
            XCTAssertEqual(
                networks.detectedCardNetworks.items.map { $0.network },
                networks.selectableCardNetworks?.items.map { $0.network },
                "Detected and selectable networks should match when all are allowed"
            )
        }
        
        assertNetworkItems(networks.detectedCardNetworks.items, expectedNetworks: expectedNetworks)
    }
    
    private func assertSelectableNetworks(
        _ selectableNetworks: [PrimerCardNetwork]?,
        expectedNetworks: [(displayName: String, rawValue: String)]
    ) {
        guard let selectableNetworks = selectableNetworks else {
            XCTFail("Expected selectable networks but got nil")
            return
        }
        assertNetworkItems(selectableNetworks, expectedNetworks: expectedNetworks)
    }
    
    private func assertDetectedNetworks(
        _ detectedNetworks: [PrimerCardNetwork],
        expectedNetworks: [(displayName: String, rawValue: String)]
    ) {
        assertNetworkItems(detectedNetworks, expectedNetworks: expectedNetworks)
    }
    
    private func assertNetworkItems(
        _ actualNetworks: [PrimerCardNetwork],
        expectedNetworks: [(displayName: String, rawValue: String)]
    ) {
        XCTAssertEqual(
            actualNetworks.count,
            expectedNetworks.count,
            "Network count should match expected count"
        )
        
        for (index, expected) in expectedNetworks.enumerated() {
            guard index < actualNetworks.count else {
                XCTFail("Missing network at index \(index)")
                continue
            }
            
            let actual = actualNetworks[index]
            XCTAssertEqual(
                actual.displayName,
                expected.displayName,
                "Display name should match at index \(index)"
            )
            XCTAssertEqual(
                actual.network.rawValue,
                expected.rawValue,
                "Network raw value should match at index \(index)"
            )
        }
    }
}
