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
        
    override func setUpWithError() throws {  
        setupSDKMocks()
        
        self.delegate = MockRawDataManagerDelegate()
        self.rawDataManager = try RawDataManager(paymentMethodType: Mocks.PaymentMethods.paymentCardPaymentMethod.type)
        self.apiClient = MockBINDataAPIClient()
        self.debouncer = Debouncer(delay: 0.5)
        self.rawDataManager.delegate = delegate
        self.binDataService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                    apiClient: apiClient)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        self.binDataService = nil
        self.rawDataManager = nil
        self.delegate = nil
    }

    func testFourDigitCardNumber_noRemoteValidation() throws {
        
        let expectation = self.expectation(description: "onWillFetchCardMetadata is not called")
        
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            XCTFail()
        }
        
        binDataService.validateCardNetworks(withCardNumber: "5555")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)

    }
    
    func testSixDigitCardNumber_startRemoteValidation() throws {
        
        let cardNumber = "555522"

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
        
        apiClient.results[String(cardNumber.prefix(8))] = .init(networks: [
            .init(displayName: "Network #1", value: "NETWORK_1"),
            .init(displayName: "Network #2", value: "NETWORK_2")
        ])
        
        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            XCTAssertEqual(cardState.cardNumber, cardNumber)
            expectation.fulfill()
        }
        
        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { rawDataManager, networks, cardState in
            if networks.availableCardNetworks.count > 1 {
                XCTAssertEqual(cardState.cardNumber, cardNumber)
                XCTAssertEqual(networks.availableCardNetworks[0].displayName, "Network #1")
                XCTAssertEqual(networks.availableCardNetworks[0].networkIdentifier, "NETWORK_1")
                XCTAssertEqual(networks.availableCardNetworks[1].displayName, "Network #2")
                XCTAssertEqual(networks.availableCardNetworks[1].networkIdentifier, "NETWORK_2")
                expectation2.fulfill()
            }
        }
        
        enterCardNumber(cardNumber)
        
        waitForExpectations(timeout: 5)
    }
    
    func testTwelveDigitCardNumber_mixedEntry_successfulValidation() throws {
        
        let cardNumber = "552266117788"
        
        apiClient.results[String(cardNumber.prefix(7))] = .init(networks: [
            .init(displayName: "Network #1", value: "NETWORK_1")
        ])
        apiClient.results[String(cardNumber.prefix(8))] = .init(networks: [
            .init(displayName: "Network #1", value: "NETWORK_1"),
            .init(displayName: "Network #2", value: "NETWORK_2")
        ])

        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        let expectShortcardNumberOnWillFetch = self.expectation(description: "After first call to onWillFetchCardMetadata, 8 digit card number is given")
        let expectLongCardNumberOnWillFetch = self.expectation(description: "After first call to onWillFetchCardMetadata, 12 digit card number is given")

        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            if self.delegate.onWillFetchCardMetadataForStateCount == 1 {
                XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(7)))
                expectShortcardNumberOnWillFetch.fulfill()
            }
            if self.delegate.onWillFetchCardMetadataForStateCount == 2 {
                XCTAssertEqual(cardState.cardNumber, cardNumber)
                expectLongCardNumberOnWillFetch.fulfill()
            }
            guard cardState.cardNumber.count >= 6 else { return }
            if self.delegate.onWillFetchCardMetadataForStateCount == 2 {
                expectation.fulfill()
            }
        }
        
        let expectShortcardNumberOnMetadata = self.expectation(description: "After first call to onMetadataForCardValidationState, 8 digit card number is given")
        let expectLongCardNumberOnMetadata = self.expectation(description: "After first call to onMetadataForCardValidationState, 12 digit card number is given")
        delegate.onMetadataForCardValidationState = { rawDataManager, networks, cardState in
            guard cardState.cardNumber.count >= 6 else { return }
            if self.delegate.onMetadataForCardValidationStateCount == 6 {
                XCTAssertEqual(cardState.cardNumber, String(cardNumber.prefix(7)))
                XCTAssertEqual(networks.availableCardNetworks.count, 1)
                XCTAssertEqual(networks.availableCardNetworks[0].displayName, "Network #1")
                XCTAssertEqual(networks.availableCardNetworks[0].networkIdentifier, "NETWORK_1")
                expectShortcardNumberOnMetadata.fulfill()
            }
            if self.delegate.onMetadataForCardValidationStateCount == 7 {
                XCTAssertEqual(cardState.cardNumber, cardNumber)
                XCTAssertEqual(networks.availableCardNetworks.count, 2)
                XCTAssertEqual(networks.availableCardNetworks[0].displayName, "Network #1")
                XCTAssertEqual(networks.availableCardNetworks[0].networkIdentifier, "NETWORK_1")
                XCTAssertEqual(networks.availableCardNetworks[1].displayName, "Network #2")
                XCTAssertEqual(networks.availableCardNetworks[1].networkIdentifier, "NETWORK_2")
                expectLongCardNumberOnMetadata.fulfill()
            }
        }
        
        enterCardNumber(cardNumber, delayAtIndex: 6)
        
        waitForExpectations(timeout: 10)
    }
    
    func testReceiveError() throws {
        
        let cardNumber = "552266117788"
        
        apiClient.error = PrimerError.generic(message: "Generic Error Message",
                                              userInfo: nil,
                                              diagnosticsId: "Diagnostics ID")
        
        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            XCTAssertEqual(cardState.cardNumber, cardNumber)
            expectation.fulfill()
        }
        
        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { rawDataManager, networks, cardState in
            XCTAssertEqual(networks.availableCardNetworks.count, 1)
            if self.delegate.onMetadataForCardValidationStateCount == 6 {
                expectation2.fulfill()
            }
        }
        
        enterCardNumber(cardNumber)
        
        waitForExpectations(timeout: 5)
    }
    
    // MARK: Helpers
    
    private func enterCardNumber(_ cardFragment: String, delayAtIndex delayIndex: Int? = nil) {
        let typer = StringTyper { string in
            self.binDataService.validateCardNetworks(withCardNumber: string)
        }

        if let delayIndex = delayIndex {
            // Type at fast speed
            var delays = Array(repeating: Double(0.1), count: 12)
            // Pause for request on the 7th character before resuming fast typing
            delays[delayIndex] = 1.0
            typer.type(cardFragment, delays: delays)
        } else {
            typer.type(cardFragment)
        }
    }
}

fileprivate func setupSDKMocks() {
    let paymentMethods = [
        Mocks.PaymentMethods.paymentCardPaymentMethod
    ]
    let session = ClientSession.APIResponse(clientSessionId: "client_session_id",
                                            paymentMethod: nil,
                                            order: nil,
                                            customer: nil,
                                            testId: nil)
    let apiConfig = PrimerAPIConfiguration(coreUrl: "core_url",
                                           pciUrl: "pci_url",
                                           clientSession: session,
                                           paymentMethods: paymentMethods,
                                           primerAccountId: "account_id",
                                           keys: nil,
                                           checkoutModules: nil)
    PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
    PrimerAPIConfigurationModule.apiConfiguration = apiConfig
}

fileprivate func tearDownSDKMocks() {
    PrimerAPIConfigurationModule.apiConfiguration = nil
    PrimerAPIConfigurationModule.clientToken = nil
}