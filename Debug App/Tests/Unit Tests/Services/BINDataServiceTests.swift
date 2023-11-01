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

final class BINDataServiceTests: XCTestCase {
    
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
        
        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            expectation.fulfill()
        }
        
        binDataService.validateCardNetworks(withCardNumber: "555522")

        waitForExpectations(timeout: 1)
    }
    
    func testTwelveDigitCardNumber_fastEntry_successfulValidation() throws {
        
        apiClient.result = .init(networks: [
            .init(displayName: "Network #1", value: "NETWORK_1"),
            .init(displayName: "Network #2", value: "NETWORK_2")
        ])
        
        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            expectation.fulfill()
        }
        
        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { rawDataManager, networks, cardState in
            XCTAssertNotNil(rawDataManager)
            if networks.availableCardNetworks.count > 1 {
                expectation2.fulfill()
            }
        }
        
        let typer = StringTyper { string in
            self.binDataService.validateCardNetworks(withCardNumber: string)
        }
        typer.type("552266117788")
        
        waitForExpectations(timeout: 5)
    }
    
    func testTwelveDigitCardNumber_slowEntry_successfulValidation() throws {
        
        apiClient.result = .init(networks: [
            .init(displayName: "Network #1", value: "NETWORK_1"),
            .init(displayName: "Network #2", value: "NETWORK_2")
        ])
        
        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            expectation.fulfill()
        }
        
        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        delegate.onMetadataForCardValidationState = { rawDataManager, networks, cardState in
            XCTAssertNotNil(rawDataManager)
            if networks.availableCardNetworks.count > 1 {
                expectation2.fulfill()
            }
        }
        
        let typer = StringTyper { string in
            self.binDataService.validateCardNetworks(withCardNumber: string)
        }
        typer.type("552266117788")
        
        waitForExpectations(timeout: 5)
    }
    
    func testTwelveDigitCardNumber_mixedEntry_successfulValidation() throws {
        apiClient.result = .init(networks: [
            .init(displayName: "Network #1", value: "NETWORK_1"),
            .init(displayName: "Network #2", value: "NETWORK_2")
        ])
        
        let expectation = self.expectation(description: "onWillFetchCardMetadata is called")
        var onWillFetchCardMetadataForStateCount = 0
        delegate.onWillFetchCardMetadataForState = { rawDataManager, cardState in
            guard cardState.cardNumber.count >= 6 else { return }
            onWillFetchCardMetadataForStateCount += 1
            print("CALLED: onWillFetchCardMetadataForState -> \(onWillFetchCardMetadataForStateCount)")
            if onWillFetchCardMetadataForStateCount == 2 {
                expectation.fulfill()
            }
        }
        
        let expectation2 = self.expectation(description: "onMetadataForCardValidationState is called")
        var onMetadataForCardValidationStateCount = 0
        delegate.onMetadataForCardValidationState = { rawDataManager, networks, cardState in
            guard cardState.cardNumber.count >= 6 else { return }
            onMetadataForCardValidationStateCount += 1
            print("CALLED: onMetadataForCardValidationState -> \(onMetadataForCardValidationStateCount)")
            if onMetadataForCardValidationStateCount == 2, networks.availableCardNetworks.count > 1 {
                expectation2.fulfill()
            }
        }
        
        let typer = StringTyper { string in
            self.binDataService.validateCardNetworks(withCardNumber: string)
        }
        
        let cardFragment = "552266117788"
        // Type at fast speed
        var delays = Array(repeating: Double(0.1), count: 12)
        // Pause for request on the 7th character before resuming fast typing
        delays[7] = 1.0
        typer.type(cardFragment, delays: delays)
        
        waitForExpectations(timeout: 10)
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
