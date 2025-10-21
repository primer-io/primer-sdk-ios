//
//  PrimerLocaleData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct PrimerLocaleData: Codable, Equatable {

    public let languageCode: String
    public let localeCode: String
    public let regionCode: String?

    public init(languageCode: String? = nil, regionCode: String? = nil) {
        self.languageCode = (languageCode ?? Locale.current.languageCode) ?? "en"
        self.regionCode = regionCode ?? Locale.current.regionCode

        if let regionCode = self.regionCode {
            self.localeCode = "\(self.languageCode)-\(regionCode)"
        } else {
            self.localeCode = self.languageCode
        }
    }
}
