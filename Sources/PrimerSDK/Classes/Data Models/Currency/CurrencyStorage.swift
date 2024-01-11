//
//  CurrencyStorage.swift
//  PrimerSDK
//
//  Created by Boris on 11.1.24..
//

import Foundation

private let currencyFileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("currencies.json")

protocol CurrencyStorage {
	func loadCurrencies() -> [Currency]
	func save(_ currencies: [Currency]) throws
	func deleteCurrenciesFile()
	func copyBundleFileIfNeeded()
}

class DefaultCurrencyStorage: CurrencyStorage {
	let fileURL: URL
	
	init(fileURL: URL = currencyFileURL) {
		self.fileURL = fileURL
	}
	
	func loadCurrencies() -> [Currency] {
		guard FileManager.default.fileExists(atPath: fileURL.path) else {
			return []
		}
		return (try? Data(contentsOf: fileURL)).flatMap { try? JSONDecoder().decode([Currency].self, from: $0) } ?? []
	}
	
	func save(_ currencies: [Currency]) throws {
		let currencyData = try JSONEncoder().encode(currencies)
		try currencyData.write(to: fileURL)
	}
	
	func deleteCurrenciesFile() {
		if FileManager.default.fileExists(atPath: fileURL.path) {
			try? FileManager.default.removeItem(at: fileURL)
		}
	}

	func copyBundleFileIfNeeded() {
		if !FileManager.default.fileExists(atPath: fileURL.path),
		   let bundleURL = Bundle.primerResources.url(forResource: "currencies", withExtension: "json"),
		   let bundleData = try? Data(contentsOf: bundleURL) {
			try? bundleData.write(to: fileURL)
		}
	}
}
