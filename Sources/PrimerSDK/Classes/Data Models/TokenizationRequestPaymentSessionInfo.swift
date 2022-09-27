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

struct CardOffSessionInfo: Encodable {
    var locale: String = PrimerSettings.current.localeData.localeCode
    var platform: String = "IOS"
    var browserInfo: [String: String] = ["userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) appleWebKit/537.36 (KHTML, like Gecko) Chrome 70.0.3538.110 Safari/537.36"]
    var redirectionUrl: String? = PrimerSettings.current.paymentMethodOptions.urlScheme
}

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
