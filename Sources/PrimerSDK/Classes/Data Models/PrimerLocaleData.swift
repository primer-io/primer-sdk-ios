//
//  PrimerLocaleData.swift
//  PrimerSDK
//
//  Created by Evangelos on 2/9/22.
//

import Foundation

public struct PrimerLocaleData: Codable {

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
