//
//  LocaleData.swift
//  PrimerSDK
//
//  Created by Evangelos on 14/4/22.
//

#if canImport(UIKit)

import Foundation

public struct LocaleData: Codable {
    let languageCode: String?
    var localeCode: String?
    let regionCode: String?
    
    public init(languageCode: String?, regionCode: String?) {
        self.languageCode = languageCode ?? Locale.current.languageCode
        self.regionCode = regionCode ?? Locale.current.regionCode
        
        if let languageCode = self.languageCode {
            if let regionCode = self.regionCode {
                self.localeCode = "\(languageCode)-\(regionCode)"
            } else {
                self.localeCode = "\(languageCode)"
            }
        }
    }
}

#endif
