//
//  CurrencyStorageTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import XCTest

@testable import PrimerSDK

final class CurrencyStorageTests: XCTestCase {
    var storage: CurrencyStorageProtocol!
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("currencies.json")

    override func setUpWithError() throws {
        storage = DefaultCurrencyStorage(fileURL: url)
    }

    override func tearDownWithError() throws {
        storage.deleteCurrenciesFile()
        storage = nil
    }

    func testLoadSaveDelete() throws {

        let currencies = [Currency(code: "USD", decimalDigits: 2), Currency(code: "EUR", decimalDigits: 2)]
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

extension Currency: @retroactive Equatable {
    public static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.code == rhs.code && lhs.decimalDigits == rhs.decimalDigits
    }
}
