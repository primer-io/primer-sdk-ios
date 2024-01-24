//
//  CurrencyLoader.swift
//  PrimerSDK
//
//  Created by Boris on 11.1.24..
//

import Foundation

internal class CurrencyLoader: LogReporter {
    private var storage: CurrencyStorage
    private var urlSession: URLSession
    internal var inMemoryCurrencies: [Currency] = []

    init(storage: CurrencyStorage, urlSession: URLSession = .shared) {
        self.storage = storage
        self.urlSession = urlSession
    }

    internal func getCurrencyFor(_ code: String) -> Currency? {
        storage.copyBundleFileIfNeeded()
        if inMemoryCurrencies.isEmpty {
            inMemoryCurrencies = storage.loadCurrencies()
        }
        return inMemoryCurrencies.first { $0.code == code }
    }

    internal func updateCurrenciesFromAPI() {
        storage.copyBundleFileIfNeeded()

        guard let configuration = PrimerAPIConfigurationModule.apiConfiguration else {
            let err = PrimerError.missingPrimerConfiguration(
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)

            ErrorHandler.handle(error: err)
            logger.error(message: "Invalid client token: \(err)")
            return
        }

        let urlString = (configuration.assetsUrl ?? "-") + "/currency-information/v1/data.json"
        guard let url = URL(string: urlString) else {
            logger.error(message: "Can't make URL from string: \(urlString)")
            return
        }

        let task = urlSession.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                if let error = error {
                    ErrorHandler.handle(error: error)
                }
                self?.logger.error(message: "Error fetching currencies from API: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                let currencies = try JSONDecoder().decode([Currency].self, from: data)
                try self?.storage.save(currencies)
                self?.inMemoryCurrencies = currencies
                self?.logger.debug(message: "Successfully updated the list of currencies.")

                let sdkEvent = Analytics.Event(
                    eventType: .sdkEvent,
                    properties: SDKEventProperties(
                        name: "\(Self.self).\(#function)",
                        params: [
                            "message": "Successfully updated the list of currencies."
                        ]))
                Analytics.Service.record(events: [sdkEvent])
            } catch {
                ErrorHandler.handle(error: error)
                self?.logger.error(message: "Error parsing or saving currencies from API: \(error)")
            }
        }
        task.resume()
    }
}
