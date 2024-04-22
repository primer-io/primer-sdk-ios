//
//  BINDataServiceTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 30/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

typealias RawDataManager = PrimerHeadlessUniversalCheckout.RawDataManager

final class CardValidationServiceTests: XCTestCase {

    var rawDataManager: RawDataManager!

    var apiClient: MockBINDataAPIClient!

    var delegate: MockRawDataManagerDelegate!

    var debouncer: Debouncer!

    var binDataService: CardValidationService!

    var maxBinLength: Int {
        DefaultCardValidationService.maximumBinLength
    }

    override func setUpWithError() throws {
        SDKSessionHelper.setUp()

        self.delegate = MockRawDataManagerDelegate()
        self.rawDataManager = try RawDataManager(paymentMethodType: Mocks.PaymentMethods.paymentCardPaymentMethod.type)
        self.apiClient = MockBINDataAPIClient()
        self.debouncer = Debouncer(delay: 0.275)
        self.rawDataManager.delegate = delegate
        self.binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                           apiClient: apiClient)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        self.binDataService = nil
        self.rawDataManager = nil
        self.delegate = nil

        SDKSessionHelper.tearDown()
    }

    func testFourDigitCardNumber_noRemoteValidation() throws {

        let expectation = self.expectation(description: "onWillFetchCardMetadata is not called")

        delegate.onWillFetchCardMetadataForState = { _, _ in
            XCTFail()
        }

        delegate.onMetadataForCardValidationState = { _, networks, _ in
            XCTAssertEqual(networks.source, .local)
            expectation.fulfill()
        }

        binDataService.validateCardNetworks(withCardNumber: "5555")

        waitForExpectations(timeout: 2)

    }

    func testSixDigitCardNumber_startRemoteValidation() throws {

        let cardNumber = "5555226611"

        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")

        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, cardNumber)
            expectation.fulfill()
        }

        binDataService.validateCardNetworks(withCardNumber: cardNumber)

        waitForExpectations(timeout: 1)
    }

    func testTwelveDigitCardNumber_fastEntry_successfulValidation() throws {

        let cardNumber = "552266117788"

        apiClient.results[String(cardNumber.prefix(self.maxBinLength))] = .init(networks: [
            .init(displayName: "Visa", value: "VISA"),
            .init(displayName: "Mastercard", value: "MASTERCARD")
        ])

        self.binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                           allowedCardNetworks: [.visa, .masterCard],
                                                           apiClient: apiClient)

        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
            expectation.fulfill()
        }

        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { _, networks, cardState in
            if networks.detectedCardNetworks.items.count > 1 {
                XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
                XCTAssertEqual(networks.source, .remote)

                XCTAssertEqual(networks.detectedCardNetworks.items.map { $0.network },
                               networks.selectableCardNetworks?.items.map { $0.network })

                XCTAssertEqual(networks.detectedCardNetworks.items[0].displayName, "Visa")
                XCTAssertEqual(networks.detectedCardNetworks.items[0].network.rawValue, "VISA")
                XCTAssertEqual(networks.detectedCardNetworks.items[1].displayName, "Mastercard")
                XCTAssertEqual(networks.detectedCardNetworks.items[1].network.rawValue, "MASTERCARD")
                expectation2.fulfill()
            }
        }

        enterCardNumber(cardNumber)

        waitForExpectations(timeout: 5)
    }

    func testTwelveDigitCardNumber_replaceNumber_successfulValidation() throws {

        let cardNumber = "552266117788"
        let altCardNumber = "552366117788"

        apiClient.results[String(cardNumber.prefix(self.maxBinLength))] = .init(networks: [
            .init(displayName: "Visa", value: "VISA"),
            .init(displayName: "Cartes Bancaires", value: "CARTES_BANCAIRES")
        ])

        apiClient.results[String(altCardNumber.prefix(self.maxBinLength))] = .init(networks: [
            .init(displayName: "Mastercard", value: "MASTERCARD"),
            .init(displayName: "Cartes Bancaires", value: "CARTES_BANCAIRES")
        ])

        self.binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                           allowedCardNetworks: [.visa, .masterCard, .cartesBancaires],
                                                           apiClient: apiClient)

        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called with networks for '\(cardNumber)'")
        let expectation3 = self.expectation(description: "onMetadataForCardValidationState is called with networks for '\(altCardNumber)'")
        delegate.onMetadataForCardValidationState = { (_: RawDataManager,
                                                       networks: PrimerCardNumberEntryMetadata,
                                                       cardState: PrimerCardNumberEntryState) in
            print("""
onMetadataForCardValidationStateCount: \(self.delegate.onMetadataForCardValidationStateCount), \
networks: \(networks.detectedCardNetworks.items.count)
""")
            if self.delegate.onMetadataForCardValidationStateCount == self.maxBinLength {
                XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
                XCTAssertEqual(networks.source, .remote)

                XCTAssertEqual(networks.detectedCardNetworks.items.map { $0.network },
                               networks.selectableCardNetworks?.items.map { $0.network })

                XCTAssertEqual(networks.detectedCardNetworks.items[0].displayName, "Visa")
                XCTAssertEqual(networks.detectedCardNetworks.items[0].network.rawValue, "VISA")
                XCTAssertEqual(networks.detectedCardNetworks.items[1].displayName, "Cartes Bancaires")
                XCTAssertEqual(networks.detectedCardNetworks.items[1].network.rawValue, "CARTES_BANCAIRES")
                expectation2.fulfill()
            }
            if self.delegate.onMetadataForCardValidationStateCount == (self.maxBinLength * 2) {
                XCTAssertEqual(cardState.cardNumber, String(altCardNumber.prefix(self.maxBinLength)))
                XCTAssertEqual(networks.source, .remote)
                XCTAssertEqual(networks.detectedCardNetworks.items[0].displayName, "Mastercard")
                XCTAssertEqual(networks.detectedCardNetworks.items[0].network.rawValue, "MASTERCARD")
                XCTAssertEqual(networks.detectedCardNetworks.items[1].displayName, "Cartes Bancaires")
                XCTAssertEqual(networks.detectedCardNetworks.items[1].network.rawValue, "CARTES_BANCAIRES")
                expectation3.fulfill()
            }
        }

        enterCardNumber(cardNumber, altCardNumber)

        waitForExpectations(timeout: 10)
    }

    func testTwelveDigitCardNumber_fastEntry_allowedSubset_successfulValidation() throws {

        let cardNumber = "552266117788"

        apiClient.results[String(cardNumber.prefix(self.maxBinLength))] = .init(networks: [
            .init(displayName: "Visa", value: "VISA"),
            .init(displayName: "Mastercard", value: "MASTERCARD"),
            .init(displayName: "Cartes Bancaires", value: "CARTES_BANCAIRES")
        ])

        self.binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                           allowedCardNetworks: [.visa, .cartesBancaires],
                                                           apiClient: apiClient)

        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
            expectation.fulfill()
        }

        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { _, networks, cardState in
            if networks.detectedCardNetworks.items.count > 1 {
                XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
                XCTAssertEqual(networks.source, .remote)
                XCTAssertNotNil(networks.selectableCardNetworks)
                XCTAssertEqual(networks.selectableCardNetworks?.items.count, 2)
                XCTAssertEqual(networks.selectableCardNetworks?.items[0].displayName, "Visa")
                XCTAssertEqual(networks.selectableCardNetworks?.items[0].network.rawValue, "VISA")
                XCTAssertEqual(networks.selectableCardNetworks?.items[1].displayName, "Cartes Bancaires")
                XCTAssertEqual(networks.selectableCardNetworks?.items[1].network.rawValue, "CARTES_BANCAIRES")

                XCTAssertEqual(networks.detectedCardNetworks.items.count, 3)
                XCTAssertEqual(networks.detectedCardNetworks.items[0].displayName, "Visa")
                XCTAssertEqual(networks.detectedCardNetworks.items[0].network.rawValue, "VISA")
                XCTAssertEqual(networks.detectedCardNetworks.items[1].displayName, "Cartes Bancaires")
                XCTAssertEqual(networks.detectedCardNetworks.items[1].network.rawValue, "CARTES_BANCAIRES")
                XCTAssertEqual(networks.detectedCardNetworks.items[2].displayName, "Mastercard")
                XCTAssertEqual(networks.detectedCardNetworks.items[2].network.rawValue, "MASTERCARD")
                expectation2.fulfill()
            }
        }

        enterCardNumber(cardNumber)

        waitForExpectations(timeout: 5)
    }

    func testTwelveDigitCardNumber_fastEntry_unallowed_successfulValidation() throws {

        let cardNumber = "552266117788"

        apiClient.results[String(cardNumber.prefix(self.maxBinLength))] = .init(networks: [
            .init(displayName: "Cartes Bancaires", value: "CARTES_BANCAIRES")
        ])

        self.binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                           allowedCardNetworks: [.visa, .masterCard],
                                                           apiClient: apiClient)

        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
            expectation.fulfill()
        }

        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { _, networks, cardState in
            guard cardState.cardNumber == cardNumber.prefix(8) else { return }

            XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
            XCTAssertEqual(networks.source, .remote)

            XCTAssertNil(networks.selectableCardNetworks)

            XCTAssertEqual(networks.detectedCardNetworks.items.count, 1)
            XCTAssertEqual(networks.detectedCardNetworks.items[0].displayName, "Cartes Bancaires")
            XCTAssertEqual(networks.detectedCardNetworks.items[0].network.rawValue, "CARTES_BANCAIRES")
            XCTAssertNil(networks.detectedCardNetworks.preferred)

            expectation2.fulfill()
        }

        enterCardNumber(cardNumber)

        waitForExpectations(timeout: 5)
    }

    func testReceiveError() throws {

        let cardNumber = "552266117788"

        apiClient.error = PrimerError.generic(message: "Generic Error Message",
                                              userInfo: nil,
                                              diagnosticsId: "Diagnostics ID")

        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { _, cardState in
            XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
            expectation.fulfill()
        }

        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { _, networks, _ in
            XCTAssertEqual(networks.detectedCardNetworks.items.count, 1)
            if self.delegate.onMetadataForCardValidationStateCount == self.maxBinLength {
                expectation2.fulfill()
            }
        }

        enterCardNumber(cardNumber)

        waitForExpectations(timeout: 5)
    }

    // MARK: Validation creation tests

    func testCreateValidationMetadata_allAllowed_differentOrder() {
        let binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                          allowedCardNetworks: [.visa, .masterCard],
                                                          apiClient: apiClient)

        let metadata = binDataService.createValidationMetadata(networks: [.masterCard, .visa], source: .remote)

        XCTAssertEqual(metadata.source, .remote)
        XCTAssertEqual(metadata.selectableCardNetworks?.items.map { $0.network }, [.visa, .masterCard])
        XCTAssertEqual(metadata.detectedCardNetworks.items.map { $0.network }, [.visa, .masterCard])
    }

    func testCreateValidationMetadata_noneAllowed_differentOrder() {
        let binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                          allowedCardNetworks: [.amex],
                                                          apiClient: apiClient)

        let metadata = binDataService.createValidationMetadata(networks: [.masterCard, .visa], source: .remote)

        XCTAssertEqual(metadata.source, .remote)
        XCTAssertNil(metadata.selectableCardNetworks)
        XCTAssertEqual(metadata.detectedCardNetworks.items.map { $0.network }, [.masterCard, .visa])
    }

    func testCreateValidationMetadata_someAllowed_someOrdered() {
        let binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                          allowedCardNetworks: [.masterCard, .visa, .jcb, .amex],
                                                          apiClient: apiClient)

        let metadata = binDataService.createValidationMetadata(networks: [.masterCard, .visa, .amex, .elo, .jcb], source: .remote)

        XCTAssertEqual(metadata.source, .remote)
        XCTAssertEqual(metadata.selectableCardNetworks?.items.map { $0.network }, [.masterCard, .visa, .jcb, .amex])
        XCTAssertEqual(metadata.detectedCardNetworks.items.map { $0.network }, [.masterCard, .visa, .jcb, .amex, .elo])
    }

    // MARK: Helpers

    private func enterCardNumber(_ cardFragment: String, _ altCardFragment: String? = nil) {
        let typer = StringTyper { string in
            self.binDataService.validateCardNetworks(withCardNumber: string)
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
}
