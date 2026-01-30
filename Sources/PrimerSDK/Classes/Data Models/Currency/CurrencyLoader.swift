//
//  CurrencyLoader.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
import Foundation
import PrimerCore
import PrimerFoundation

var inMemoryCurrencies: [Currency]? = []

public final class CurrencyLoader: LogReporter {

    private var storage: CurrencyStorageProtocol
    private var networkService: CurrencyNetworkServiceProtocol

    public init() {
        self.storage = DefaultCurrencyStorage()
        self.networkService = CurrencyNetworkService()
    }

    init(storage: CurrencyStorageProtocol, networkService: CurrencyNetworkServiceProtocol) {
        self.storage = storage
        self.networkService = networkService
    }

    public func getCurrency(_ code: String) -> Currency? {
        // Ensure currencies are loaded into memory
        loadCurrenciesIfNeeded()

        // Return the currency if it exists
        return inMemoryCurrencies?.first { $0.code == code }
    }

    private func loadCurrenciesIfNeeded() {
        storage.copyBundleFileIfNeeded()
        if inMemoryCurrencies?.isEmpty ?? true {
            inMemoryCurrencies = storage.loadCurrencies()
        }
    }

    func updateCurrenciesFromAPI(completion: ((Error?) -> Void)? = nil) {
        loadCurrenciesIfNeeded()

        guard let configuration = PrimerAPIConfigurationModule.apiConfiguration else {
            let error = handled(primerError: .missingPrimerConfiguration())
            logger.error(message: "Invalid client token: \(error)")
            completion?(error)
            return
        }

        let urlString = (configuration.assetsUrl ?? "-") + "/currency-information/v1/data.json"
        guard let url = URL(string: urlString) else {
            logger.error(message: "Can't make URL from string: \(urlString)")
            completion?(PrimerError.invalidUrl(url: urlString))
            return
        }

        let request = URLRequest(url: url)
        networkService.fetchData(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                if let error = error {
                    ErrorHandler.handle(error: error)
                }
                self?.logger.error(message: "Error fetching currencies from API: \(error?.localizedDescription ?? "Unknown error")")
                completion?(error)
                return
            }

            do {
                let currencies = try JSONDecoder().decode([Currency].self, from: data)
                try self?.storage.save(currencies)
                inMemoryCurrencies = currencies
                self?.logger.debug(message: "Successfully updated the list of currencies.")

                let sdkEvent = Analytics.Event.sdk(name: #function,
                                                   params: ["message": "Successfully updated the list of currencies."])
                Analytics.Service.fire(events: [sdkEvent])
                completion?(nil)
            } catch {
                self?.logger.error(message: "Error parsing or saving currencies from API: \(error)")
                completion?(handled(error: error))
            }
        }
    }
}
// swiftlint:enable function_body_length
