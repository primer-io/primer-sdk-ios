//
//  CurrencyStorageTests.swift
//  Debug App Tests
//
//  Created by Boris on 11.1.24..
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest

@testable import PrimerSDK

final class CurrencyStorageTests: XCTestCase {
	var storage: CurrencyStorage!
	let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("currencies.json")

	override func setUpWithError() throws {
		storage = DefaultCurrencyStorage(fileURL: url)
	}

	override func tearDownWithError() throws {
		storage.deleteCurrenciesFile()
		storage = nil
	}

	func testLoadSaveDelete() throws {
		let currencies = [Currency("USD")!, Currency("EUR")!]
		try storage.save(currencies)
		XCTAssertEqual(storage.loadCurrencies(), currencies)
		storage.deleteCurrenciesFile()
		XCTAssertTrue(storage.loadCurrencies().isEmpty)
	}

	func testCopyBundleFileIfNeeded() {
		storage.deleteCurrenciesFile()
		XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
		storage.copyBundleFileIfNeeded()
		XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
	}

	func testInitialLoadFromBundle() {
		storage.deleteCurrenciesFile()
		storage.copyBundleFileIfNeeded()
		let currencies = storage.loadCurrencies()
		XCTAssertFalse(currencies.isEmpty, "Currencies should be loaded from bundle on initial load")
	}

	func testDeletingNonExistentFile() {
		storage.deleteCurrenciesFile()  // Delete if exists
		storage.deleteCurrenciesFile()  // Attempt to delete again
		XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "File should not exist after deletion")
	}
}


extension Currency: Equatable {
	public static func == (lhs: Currency, rhs: Currency) -> Bool {
		lhs.code == rhs.code && lhs.decimalDigits == rhs.decimalDigits
	}
}

