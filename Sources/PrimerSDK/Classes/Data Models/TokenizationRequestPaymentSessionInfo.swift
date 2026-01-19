//
//  TokenizationRequestPaymentSessionInfo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

// MARK: OFF-SESSION PAYMENT INFO

private func urlScheme() -> String? {
    (try? PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString
}

protocol OffSessionPaymentSessionInfo: Encodable {}

struct CardOffSessionInfo: Encodable {
    var locale: String = PrimerSettings.current.localeData.localeCode
    var platform: String = "IOS"
    var browserInfo: [String: String] = ["userAgent": UserAgent.userAgentAsString]
    var redirectionUrl: String? = urlScheme()
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
    let redirectionUrl: String? = urlScheme()
}

struct InputPhonenumberSessionInfo: OffSessionPaymentSessionInfo {
    let phoneNumber: String
    let locale: String = PrimerSettings.current.localeData.localeCode
    let platform: String = "IOS"
    let redirectionUrl: String? = urlScheme()
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
    var redirectionUrl: String? = urlScheme()
}

struct IPay88SessionInfo: OffSessionPaymentSessionInfo {
    var refNo: String
    var locale: String
    var platform: String = "IOS"
    var redirectionUrl: String? = urlScheme()
}

struct NolPaySessionInfo: OffSessionPaymentSessionInfo {
    let platform: String
    let locale: String = PrimerSettings.current.localeData.localeCode
    let mobileCountryCode: String
    let mobileNumber: String
    let nolPayCardNumber: String
    let phoneVendor: String
    let phoneModel: String
}
