//
//  CurrencyLoaderTests.swift
//  Debug App Tests
//
//  Created by Boris on 11.1.24..
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class MockURLProtocol: URLProtocol {
    // Handler to intercept the request and provide a custom response
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is missing.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // This function is required but you don't need to implement anything here for this test
    }
}

class CurrencyLoaderTests: XCTestCase {

    var storage: CurrencyStorage!
    var currencyLoader: CurrencyLoader!
    var mockSession: URLSession!
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("currencies.json")
    let mockCurrencies = [Currency("USD")!, Currency("EUR")!]

    override func setUpWithError() throws {
        storage = DefaultCurrencyStorage(fileURL: url)
        try storage.save(mockCurrencies)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)

        currencyLoader = CurrencyLoader(storage: storage, urlSession: mockSession)
    }

    override func tearDownWithError() throws {
        storage.deleteCurrenciesFile()
        storage = nil
        currencyLoader = nil
    }

    func testGetCurrencyFor() {
        let currencyUSD = currencyLoader.getCurrencyFor("USD")
        XCTAssertNotNil(currencyUSD)
        XCTAssertEqual(currencyUSD?.code, "USD")

        let currencyEUR = currencyLoader.getCurrencyFor("EUR")
        XCTAssertNotNil(currencyEUR)
        XCTAssertEqual(currencyEUR?.code, "EUR")

        let currencyNonExistent = currencyLoader.getCurrencyFor("XYZ")
        XCTAssertNil(currencyNonExistent)
    }

    func testLoadAfterInitialBundleCopy() {
        // Trigger the bundle copy
        let _ = currencyLoader.getCurrencyFor("USD")

        // Now load the currencies
        let currencies = storage.loadCurrencies()

        // Assert that the currencies are not empty, indicating a successful copy from the bundle
        XCTAssertFalse(currencies.isEmpty)
        XCTAssertEqual(currencies.count, 2)
    }

    func testUpdateCurrenciesFromAPISuccess() {
        // Set up the mock response
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let mockCurrencyData = """
            [
                {"c": "USD", "m": 2},
                {"c": "EUR", "m": 2}
            ]
            """.data(using: .utf8)!
            return (response, mockCurrencyData)
        }

        let expectation = XCTestExpectation(description: "CurrencyLoader updates currencies from API")
        
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

        currencyLoader.updateCurrenciesFromAPI()

        // Wait for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // First, check the array count to avoid out-of-range error
            XCTAssertEqual(self.currencyLoader.inMemoryCurrencies.count, 2, "There should be 2 currencies loaded")

            // Then, safely access the elements
            if self.currencyLoader.inMemoryCurrencies.count >= 2 {
                XCTAssertEqual(self.currencyLoader.inMemoryCurrencies[0].code, "USD", "The first currency code should be USD")
                XCTAssertEqual(self.currencyLoader.inMemoryCurrencies[1].code, "EUR", "The second currency code should be EUR")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testUpdateCurrenciesFromAPIFailure() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let data = Data() // Empty data for failure scenario
            return (response, data)
        }

        let expectation = XCTestExpectation(description: "CurrencyLoader handles API failure")
        
        currencyLoader.updateCurrenciesFromAPI()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.currencyLoader.inMemoryCurrencies.isEmpty, "In-memory currencies should be empty on API failure")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testUpdateCurrenciesFromAPIInvalidResponse() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let invalidData = "Invalid Data".data(using: .utf8)!
            return (response, invalidData)
        }

        let expectation = XCTestExpectation(description: "CurrencyLoader handles invalid response data")

        currencyLoader.updateCurrenciesFromAPI()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.currencyLoader.inMemoryCurrencies.isEmpty, "In-memory currencies should be empty on invalid response")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testUpdateCurrenciesFromAPIEmptyResponse() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let emptyCurrencyData = "[]".data(using: .utf8)!
            return (response, emptyCurrencyData)
        }

        let expectation = XCTestExpectation(description: "CurrencyLoader handles empty response")

        currencyLoader.updateCurrenciesFromAPI()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.currencyLoader.inMemoryCurrencies.isEmpty, "In-memory currencies should be empty on empty response")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testUpdateCurrenciesFromAPIUnexpectedDataFormat() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let unexpectedData = """
            [
                {"unexpectedField": "value"}
            ]
            """.data(using: .utf8)!
            return (response, unexpectedData)
        }

        let expectation = XCTestExpectation(description: "CurrencyLoader handles unexpected data format")

        currencyLoader.updateCurrenciesFromAPI()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.currencyLoader.inMemoryCurrencies.isEmpty, "In-memory currencies should be empty on unexpected data format")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
