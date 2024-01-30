//
//  CurrencyLoaderTests.swift
//  Debug App Tests
//
//  Created by Boris on 11.1.24..
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class CurrencyLoaderTests: XCTestCase {

    var storage: CurrencyStorageProtocol!
    var networkService: MockCurrencyNetworkService!
    var currencyLoader: CurrencyLoader!

    override func setUpWithError() throws {
        super.setUp()
        storage = MockCurrencyStorage()
        networkService = MockCurrencyNetworkService()
        currencyLoader = CurrencyLoader(storage: storage, networkService: networkService)
    }

    override func tearDownWithError() throws {
        inMemoryCurrencies = []
        storage = nil
        networkService = nil
        currencyLoader = nil
        super.tearDown()
    }
    
    private func mockConfiguration() {
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
                                               assetsUrl: "https://assets.staging.core.primer.io",
                                               clientSession: session,
                                               paymentMethods: paymentMethods,
                                               primerAccountId: "account_id",
                                               keys: nil,
                                               checkoutModules: nil)
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfig
    }

    func testGetCurrencyReturnsCurrencyIfExists() {
        // Given
        let expectedCurrency = Currency(code: "USD", decimalDigits: 2)
        storage.mockCurrencies = [expectedCurrency]

        // When
        let currency = currencyLoader.getCurrency("USD")

        // Then
        XCTAssertNotNil(currency)
        XCTAssertEqual(currency?.code, "USD")
        XCTAssertEqual(currency?.decimalDigits, 2)
    }

    func testGetCurrencyReturnsNilIfNotExists() {
        // Given
        inMemoryCurrencies = []
        storage.mockCurrencies = [Currency(code: "EUR", decimalDigits: 2)]

        // When
        let currency = currencyLoader.getCurrency("USD")

        // Then
        XCTAssertNil(currency)
    }
        
    func testUpdateCurrenciesFromAPISuccess() {
        // Given
        let mockCurrencyData = """
        [
            {"c": "USD", "m": 2},
            {"c": "EUR", "m": 2}
        ]
        """.data(using: .utf8)!
        networkService.mockResponse = (mockCurrencyData, nil, nil)
        mockConfiguration()
        let expectation = XCTestExpectation(description: "CurrencyLoader updates currencies from API")

        // When
        currencyLoader.updateCurrenciesFromAPI { error in
            // Then
            XCTAssertNil(error, "Expected no error, received: \(String(describing: error))")
            XCTAssertNotNil(inMemoryCurrencies)
            XCTAssertEqual(inMemoryCurrencies?.count, 2)
            XCTAssertEqual(inMemoryCurrencies?.first?.code, "USD")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }


    
    func testUpdateCurrenciesFromAPIWithEmptyResponse() {
        // Simulate an empty response
        let emptyData = "[]".data(using: .utf8)!
        networkService.mockResponse = (emptyData, nil, nil)

        let expectation = XCTestExpectation(description: "CurrencyLoader handles empty API response")

        currencyLoader.updateCurrenciesFromAPI()

        DispatchQueue.main.async {
            XCTAssertTrue(inMemoryCurrencies?.isEmpty ?? false, "inMemoryCurrencies should be empty after receiving an empty response")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateCurrenciesFromAPIWithUnexpectedDataFormat() {
        // Simulate a response with unexpected data format
        let invalidData = "{\"invalid\":\"data\"}".data(using: .utf8)!
        networkService.mockResponse = (invalidData, nil, nil)
        mockConfiguration()
        
        let expectation = XCTestExpectation(description: "CurrencyLoader handles unexpected data format")

        currencyLoader.updateCurrenciesFromAPI { error in
            // Then
            XCTAssertNotNil(error, "Expected error, but request was succesfull)")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadingCurrenciesFromStorage() {
        // Given currencies in storage
        let storedCurrencies = [Currency(code: "JPY", decimalDigits: 0)]
        storage.mockCurrencies = storedCurrencies

        // When getting a currency
        let currency = currencyLoader.getCurrency("JPY")

        // Then it should be loaded from storage
        XCTAssertNotNil(currency!, "Currency should be loaded from storage")
        XCTAssertEqual(currency!.code, "JPY", "Loaded currency should match stored currency")
    }

    func testCopyBundleFileIfNeeded() {
        // Simulate an empty storage
        storage.mockCurrencies = []

        // Simulate bundle data
        // You'll need to adjust this part to actually simulate bundle data loading in your `MockCurrencyStorage`
        let bundleCurrencies = [Currency(code: "BRL", decimalDigits: 2)]
        storage.mockCurrencies = bundleCurrencies // Simulate as if loaded from bundle

        // Load currencies
        let currency = currencyLoader.getCurrency("BRL")

        // Verify currency is loaded as if from bundle
        XCTAssertNotNil(currency, "Currency should be loaded from the bundle")
        XCTAssertEqual(currency?.code, "BRL", "Currency loaded should match the one simulated from the bundle")
    }
    
    func testUpdateCurrenciesFromAPIWithNetworkFailure() {
        // Simulate a network failure
        let networkError = NSError(domain: "NetworkError", code: 1, userInfo: nil)
        networkService.mockResponse = (nil, nil, networkError)
        
        let expectation = XCTestExpectation(description: "CurrencyLoader handles network failure")

        currencyLoader.updateCurrenciesFromAPI { error in
            // Then
            XCTAssertNotNil(error, "Expected network error, received nil")
            // Optionally, verify that the in-memory currencies are unchanged or empty
            XCTAssertTrue(inMemoryCurrencies?.isEmpty ?? true, "inMemoryCurrencies should remain unchanged or empty on network failure")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFallbackToStorageOnAPIFailure() {
        // Given
        let networkError = NSError(domain: "NetworkError", code: 1, userInfo: nil)
        networkService.mockResponse = (nil, nil, networkError)
        
        // Preset some currencies in storage to simulate previously stored data
        let fallbackCurrencies = [Currency(code: "CNY", decimalDigits: 2)]
        storage.mockCurrencies = fallbackCurrencies
        inMemoryCurrencies = fallbackCurrencies
        
        let expectation = XCTestExpectation(description: "CurrencyLoader uses fallback data from storage on API failure")

        currencyLoader.updateCurrenciesFromAPI { error in
            // Then
            XCTAssertNotNil(error, "Expected API error, received nil")
            
            // Verify that the loader falls back to using stored currencies
            XCTAssertFalse(inMemoryCurrencies?.isEmpty ?? true, "inMemoryCurrencies should not be empty after API failure")
            XCTAssertEqual(inMemoryCurrencies?.first?.code, "CNY", "Fallback currency should be used from storage")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCurrencySymbolResolution() {
        // Given a known currency
        let currency = Currency(code: "USD", decimalDigits: 2)
        
        // When fetching its symbol
        let symbol = currency.symbol
        
        // Then the symbol should match the expected value
        XCTAssertEqual(symbol, "US$", "Currency symbol for USD should be 'US$'")
    }
}
