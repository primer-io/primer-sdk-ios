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
    
    var delegate: MockRawDataManagerDelegate!

    var binDataService: BinDataService!
        
    override func setUpWithError() throws {  
        setupMocks()
        self.delegate = MockRawDataManagerDelegate()
        self.rawDataManager = try RawDataManager(paymentMethodType: Mocks.PaymentMethods.paymentCardPaymentMethod.type)
        self.rawDataManager.delegate = delegate
        self.binDataService = DefaultBINDataService(rawDataManager: rawDataManager)
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
}

fileprivate func setupMocks() {
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

fileprivate func tearDownMocks() {
    PrimerAPIConfigurationModule.apiConfiguration = nil
    PrimerAPIConfigurationModule.clientToken = nil
}
