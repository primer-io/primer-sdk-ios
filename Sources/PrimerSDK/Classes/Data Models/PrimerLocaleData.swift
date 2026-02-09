//
//  PrimerLocaleData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Localization settings for the SDK including language and region preferences.
///
/// `PrimerLocaleData` determines the language used for SDK UI strings and the regional
/// formatting applied to currency and other locale-specific content.
///
/// By default, the SDK uses the device's current locale. You can override this by
/// providing specific language and/or region codes.
///
/// Example usage:
/// ```swift
/// // Use device locale (default)
/// let localeData = PrimerLocaleData()
///
/// // Specify language only
/// let germanLocale = PrimerLocaleData(languageCode: "de")
///
/// // Specify both language and region
/// let ukLocale = PrimerLocaleData(languageCode: "en", regionCode: "GB")
/// ```
public struct PrimerLocaleData: Codable, Equatable {

    /// The ISO 639-1 language code (e.g., "en", "de", "fr").
    /// Defaults to the device's language if not specified.
    public let languageCode: String

    /// The combined locale code in the format "language-region" (e.g., "en-US", "de-DE").
    /// This is computed from the language and region codes.
    public let localeCode: String

    /// The ISO 3166-1 alpha-2 region code (e.g., "US", "GB", "DE").
    /// Optional; when nil, only the language code is used.
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
