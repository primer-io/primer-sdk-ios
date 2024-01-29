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

	var storage: CurrencyStorage!
	let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("currencies.json")
	let mockCurrencies = [Currency("USD")!, Currency("EUR")!]

	override func setUpWithError() throws {
		storage = DefaultCurrencyStorage(fileURL: url)
		try storage.save(mockCurrencies)
	}

	override func tearDownWithError() throws {
		storage.deleteCurrenciesFile()
		storage = nil
	}

	func testGetCurrencyFor() {
		let currencyUSD = CurrencyLoader.getCurrencyFor("USD")
		XCTAssertNotNil(currencyUSD)
		XCTAssertEqual(currencyUSD?.code, "USD")

		let currencyEUR = CurrencyLoader.getCurrencyFor("EUR")
		XCTAssertNotNil(currencyEUR)
		XCTAssertEqual(currencyEUR?.code, "EUR")

		let currencyNonExistent = CurrencyLoader.getCurrencyFor("XYZ")
		XCTAssertNil(currencyNonExistent)
	}
	
	func testUpdateCurrencies() {
		// Here you would mock the network request to return specific data
		// For example, let's assume the mock returns ["GBP", "JPY"]
		// MockNetworkSession.mockResponse = ...

		CurrencyLoader.updateCurrenciesFromAPI()

		// Wait for the async call to complete
		let expectation = XCTestExpectation(description: "Update currencies")
		DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 3)

		// Load currencies and check if they match the mock response
		let currencyGBP = CurrencyLoader.getCurrencyFor("GBP")
		XCTAssertNotNil(currencyGBP)
		let currencyJPY = CurrencyLoader.getCurrencyFor("JPY")
		XCTAssertNotNil(currencyJPY)
	}
	
	func testLoadAfterInitialBundleCopy() {
		// Ensure the file doesn't exist
		storage.deleteCurrenciesFile()

		// Trigger the bundle copy
		let _ = CurrencyLoader.getCurrencyFor("USD")

		// Now load the currencies
		let currencies = storage.loadCurrencies()

		// Assert that the currencies are not empty, indicating a successful copy from the bundle
		XCTAssertFalse(currencies.isEmpty)
	}
}
