//
//  CurrencyLoader.swift
//  PrimerSDK
//
//  Created by Boris on 11.1.24..
//

import Foundation

private let urlString = "https://assets.dev.core.primer.io/currency-information/latest/data.json"

internal struct CurrencyLoader: LogReporter {
	private static let storage: CurrencyStorage = DefaultCurrencyStorage()

	internal static func getCurrencyFor(_ code: String) -> Currency? {
		storage.copyBundleFileIfNeeded()
		return storage.loadCurrencies().first { $0.code == code }
	}

	internal static func updateCurrenciesFromAPI() {
		storage.copyBundleFileIfNeeded()
		guard let url = URL(string: urlString) else {
			logger.error(message: "Can't make URL from string: \(urlString)")
			return
		}

		let task = URLSession.shared.dataTask(with: url) { data, _, error in
			guard let data = data, error == nil else {
				if let error = error {
					ErrorHandler.handle(error: error)
				}
				logger.error(message: "Error fetching currencies from API: \(error?.localizedDescription ?? "Unknown error")")
				return
			}
			
			do {
				let currencies = try JSONDecoder().decode([Currency].self, from: data)
				try storage.save(currencies)
				logger.debug(message: "Sucesfully updated the list of currencies.")
				
				let sdkEvent = Analytics.Event(
					eventType: .sdkEvent,
					properties: SDKEventProperties(
						name: "\(Self.self).\(#function)",
						params: [
							"message": "Sucesfully updated the list of currencies."
						]))
				Analytics.Service.record(events: [sdkEvent])
			} catch {
				ErrorHandler.handle(error: error)
				logger.error(message: "Error parsing or saving currencies from API: \(error)")
			}
		}
		task.resume()
	}
}
