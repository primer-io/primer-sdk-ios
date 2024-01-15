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
        
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
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
        
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
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
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
            expectation.fulfill()
        }
        
        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { rawDataManager, networks, cardState in
            if networks.detectedCardNetworks.count > 1 {
                XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
                XCTAssertEqual(networks.source, .remote)
                XCTAssertEqual(networks.detectedCardNetworks[0].displayName, "Visa")
                XCTAssertEqual(networks.detectedCardNetworks[0].network.rawValue, "VISA")
                XCTAssertEqual(networks.detectedCardNetworks[1].displayName, "Mastercard")
                XCTAssertEqual(networks.detectedCardNetworks[1].network.rawValue, "MASTERCARD")
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
        delegate.onMetadataForCardValidationState = { (rawDataManager: RawDataManager,
                                                       networks: PrimerCardNumberEntryMetadata,
                                                       cardState: PrimerCardNumberEntryState) in
            print("""
onMetadataForCardValidationStateCount: \(self.delegate.onMetadataForCardValidationStateCount), \
networks: \(networks.detectedCardNetworks.count)
""")
            if self.delegate.onMetadataForCardValidationStateCount == self.maxBinLength {
                XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
                XCTAssertEqual(networks.source, .remote)
                XCTAssertEqual(networks.detectedCardNetworks[0].displayName, "Visa")
                XCTAssertEqual(networks.detectedCardNetworks[0].network.rawValue, "VISA")
                XCTAssertEqual(networks.detectedCardNetworks[1].displayName, "Cartes Bancaires")
                XCTAssertEqual(networks.detectedCardNetworks[1].network.rawValue, "CARTES_BANCAIRES")
                expectation2.fulfill()
            }
            if self.delegate.onMetadataForCardValidationStateCount == (self.maxBinLength * 2) {
                XCTAssertEqual(cardState.cardNumber, String(altCardNumber.prefix(self.maxBinLength)))
                XCTAssertEqual(networks.source, .remote)
                XCTAssertEqual(networks.detectedCardNetworks[0].displayName, "Mastercard")
                XCTAssertEqual(networks.detectedCardNetworks[0].network.rawValue, "MASTERCARD")
                XCTAssertEqual(networks.detectedCardNetworks[1].displayName, "Cartes Bancaires")
                XCTAssertEqual(networks.detectedCardNetworks[1].network.rawValue, "CARTES_BANCAIRES")
                expectation3.fulfill()
            }
        }
        
        enterCardNumber(cardNumber, altCardNumber)
        
        waitForExpectations(timeout: 10)
    }
    
    
    
    func testReceiveError() throws {
        
        let cardNumber = "552266117788"
        
        apiClient.error = PrimerError.generic(message: "Generic Error Message",
                                              userInfo: nil,
                                              diagnosticsId: "Diagnostics ID")
        
        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(self.maxBinLength)))
            expectation.fulfill()
        }
        
        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { rawDataManager, networks, cardState in
            XCTAssertEqual(networks.detectedCardNetworks.count, 1)
            if self.delegate.onMetadataForCardValidationStateCount == self.maxBinLength {
                expectation2.fulfill()
            }
        }
        
        enterCardNumber(cardNumber)
        
        waitForExpectations(timeout: 5)
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
