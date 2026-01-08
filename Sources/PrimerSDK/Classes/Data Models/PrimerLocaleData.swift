//
//  PrimerLocaleData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct PrimerLocaleData: Codable, Equatable {

    public let languageCode: String
    public let localeCode: String
    public let regionCode: String?

    public init(languageCode: String? = nil, regionCode: String? = nil) {
        // If both parameters are nil, use device locale for both
        if languageCode == nil, regionCode == nil {
            self.languageCode = Locale.current.languageCode ?? "en"
            self.regionCode = Locale.current.regionCode
        } else {
            // If languageCode is provided, use it; otherwise use device default
            self.languageCode = languageCode ?? (Locale.current.languageCode ?? "en")
            // Use provided regionCode (which might be explicitly nil)
            self.regionCode = regionCode
        }

        if let regionCode = self.regionCode {
            self.localeCode = "\(self.languageCode)-\(regionCode)"
        } else {
            self.localeCode = self.languageCode
        }
    }
}
