//
//  TokenizationPaymentSessionInfo.swift
//  PrimerSDK
//
//  Created by Evangelos on 29/8/22.
//

#if canImport(UIKit)

import Foundation

// MARK: OFF-SESSION PAYMENT INFO

protocol OffSessionPaymentSessionInfo: Encodable {}

struct BankSelectorSessionInfo: OffSessionPaymentSessionInfo {
    var issuer: String?
    var locale: String = "en_US"
    var platform: String = "IOS"
}

struct BlikSessionInfo: OffSessionPaymentSessionInfo {
    let blikCode: String
    let locale: String
    let platform: String = "IOS"
    let redirectionUrl: String? = PrimerSettings.current.paymentMethodOptions.urlScheme
}

struct InputPhonenumberSessionInfo: OffSessionPaymentSessionInfo {
    let phoneNumber: String
    let locale: String = PrimerSettings.current.localeData.localeCode
    let platform: String = "IOS"
    let redirectionUrl: String? = PrimerSettings.current.paymentMethodOptions.urlScheme
}

struct PrimerTestPaymentMethodSessionInfo: OffSessionPaymentSessionInfo {
    var locale: String = PrimerSettings.current.localeData.localeCode
    var platform: String = "IOS"
    var flowDecision: FlowDecision
    
    enum FlowDecision: String, Codable, CaseIterable {
        case success = "SUCCESS"
        case decline = "DECLINE"
        case fail    = "FAIL"
    }
}

struct WebRedirectSessionInfo: OffSessionPaymentSessionInfo {
    var locale: String
    var platform: String = "IOS"
    var redirectionUrl: String? = PrimerSettings.current.paymentMethodOptions.urlScheme
}

#endif
