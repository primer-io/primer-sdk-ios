//
//  CountryCode.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable identifier_name
// swiftlint:disable type_body_length

import Foundation
import PrimerFoundation
import UIKit

// inspired by https://gist.github.com/proxpero/f7ddfd721a0d0d6159589916185d9dc9

extension CountryCode {

    var country: String {
        localizedCountryName
    }
}

extension CountryCode {

    static var phoneNumberCountryCodes: [PhoneNumberCountryCode] = CountryCode.loadedPhoneNumberCountryCodes ?? []
}

extension CountryCode {

    private static var languageCode: String {
        Locale.current.languageCode ?? "en"
    }

    struct DecodableLocalizedCountries: Decodable {
        let locale: String
        var countries: [CountryCode.RawValue: String]

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case locale
            case countries
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.locale = try container.decode(String.self, forKey: .locale)
            self.countries = [:]

            if let countriesWithMultipleOptionNames = try container.decodeIfPresent([CountryCode.RawValue: AnyCodable].self,
                                                                                    forKey: .countries) {
                var updatedCountries: [CountryCode.RawValue: String] = [:]
                countriesWithMultipleOptionNames.forEach {
                    if let countryNames = $0.value.value as? [String] {
                        updatedCountries[$0.key] = countryNames.first
                    } else if let countryName = $0.value.value as? String {
                        updatedCountries[$0.key] = countryName
                    }
                }
                self.countries = updatedCountries
            }
        }
    }

    struct LocalizedCountries {

        static var loadedCountriesBasedOnLocale: DecodableLocalizedCountries? = {
            guard let localizedCountriesData = JSONLoader.loadJsonData(fileName: CountryCode.languageCode) else {
                return nil
            }
            return try? JSONDecoder().decode(DecodableLocalizedCountries.self, from: localizedCountriesData)
        }()
    }

    private var localizedCountryName: String {
        LocalizedCountries.loadedCountriesBasedOnLocale?.countries
            .first { $0.key == self.rawValue }?
            .value ?? "N/A"
    }
}

extension CountryCode {

    struct PhoneNumberCountryCode: Codable {
        let name: String
        let dialCode: String
        let code: String
    }

    private static var loadedPhoneNumberCountryCodes: [PhoneNumberCountryCode]? = {
        guard let currenciesData = JSONLoader.loadJsonData(fileName: "phone_number_country_codes") else {
            return nil
        }
        let jsonDecoder = JSONDecoder().withSnakeCaseParsing()
        return try? jsonDecoder.decode([PhoneNumberCountryCode].self, from: currenciesData)
    }()
}
// swiftlint:enable identifier_name
// swiftlint:enable type_body_length
