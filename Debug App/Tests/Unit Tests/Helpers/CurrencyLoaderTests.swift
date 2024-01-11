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
