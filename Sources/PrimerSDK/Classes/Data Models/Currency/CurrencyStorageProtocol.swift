//
//  CurrencyStorage.swift
//  PrimerSDK
//
//  Created by Boris on 11.1.24..
//

import Foundation

private let currencyFileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("currencies.json")

public protocol CurrencyStorageProtocol {
    var mockCurrencies: [Currency] { get set }
    func loadCurrencies() -> [Currency]
    func save(_ currencies: [Currency]) throws
    func deleteCurrenciesFile()
    func copyBundleFileIfNeeded()
}

class DefaultCurrencyStorage: CurrencyStorageProtocol {
    var mockCurrencies: [Currency] = []

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

class MockCurrencyStorage: CurrencyStorageProtocol {
    // Property to hold mock currencies you want to return in your tests
    var mockCurrencies: [Currency] = []

    // Optional properties to simulate errors
    var loadCurrenciesError: Error?
    var saveCurrenciesError: Error?
    var deleteCurrenciesFileError: Error?

    func loadCurrencies() -> [Currency] {
        // If there's a simulated error, you can throw it
        if let error = loadCurrenciesError {
            fatalError("Load Currencies Error: \(error.localizedDescription)")
        }

        // Return mock currencies set up in your test case
        return mockCurrencies
    }

    func save(_ currencies: [Currency]) throws {
        // If there's a simulated error, throw it
        if let error = saveCurrenciesError {
            throw error
        }

        // Optionally update mockCurrencies with the saved currencies
        // if you want to mimic a persistent storage behavior
        mockCurrencies = currencies
    }

    func deleteCurrenciesFile() {
        // If there's a simulated error, you can handle it here
        // For example, you could log the error or fatalError in tests
        if let error = deleteCurrenciesFileError {
            fatalError("Delete Currencies File Error: \(error.localizedDescription)")
        }

        // Clear mock currencies to simulate file deletion
        mockCurrencies = []
    }

    func copyBundleFileIfNeeded() {
        // This method can be left empty or implement logic to simulate
        // copying initial data from a bundle if required for your tests
    }
}
