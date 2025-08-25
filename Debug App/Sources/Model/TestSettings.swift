//
//  TestSettings.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct RNPrimerSettings: Codable {
    var paymentHandling: String?
    var localeData: RNPrimerLocaleData?
    var paymentMethodOptions: RNPrimerPaymentMethodOptions?
    var uiOptions: RNPrimerUIOptions?
    var debugOptions: RNPrimerDebugOptions?
    var clientSessionCachingEnabled: Bool?
    var apiVersion: String?
}

struct RNPrimerLocaleData: Codable {
    var languageCode: String?
    var localeCode: String?
}

struct RNPrimerPaymentMethodOptions: Codable {
    var iOS: IOSOptions?
    var applePayOptions: RNPrimerApplePayOptions?
    var cardPaymentOptions: RNPrimerCardPaymentOptions?
    var goCardlessOptions: RNPrimerGoCardlessOptions?
    var klarnaOptions: RNPrimerKlarnaOptions?
    var threeDsOptions: RNPrimerThreeDsOptions?
    var stripeOptions: RNPrimerStripeOptions?

    struct IOSOptions: Codable {
        var urlScheme: String?
    }
}

struct RNPrimerApplePayOptions: Codable {
    var merchantIdentifier: String
    var merchantName: String?
    var isCaptureBillingAddressEnabled: Bool
    var showApplePayForUnsupportedDevice: Bool?
    var checkProvidedNetworks: Bool?
    var shippingOptions: RNShippingOptions?
    var billingOptions: RNBillingOptions?
}

struct RNShippingOptions: Codable {
    var shippingContactFields: [RNRequiredContactField]?
    var requireShippingMethod: Bool
}

struct RNBillingOptions: Codable {
    var requiredBillingContactFields: [RNRequiredContactField]?
}

enum RNRequiredContactField: String, Codable {
    case name, emailAddress, phoneNumber, postalAddress
}

struct RNPrimerCardPaymentOptions: Codable {
    var is3DSOnVaultingEnabled: Bool
}

struct RNPrimerGoCardlessOptions: Codable {
    var businessName: String?
    var businessAddress: String?
}

struct RNPrimerGoogleShippingAddressParameters: Codable {
    var isPhoneNumberRequired: Bool?
}

struct RNPrimerKlarnaOptions: Codable {
    var recurringPaymentDescription: String?
    var webViewTitle: String?
}

struct RNPrimerUIOptions: Codable {
    var isInitScreenEnabled: Bool?
    var isSuccessScreenEnabled: Bool?
    var isErrorScreenEnabled: Bool?
    var dismissalMechanism: [RNDismissalMechanism]?
}

enum RNDismissalMechanism: String, Codable {
    case gestures, closeButton
}

struct RNPrimerDebugOptions: Codable {
    var is3DSSanityCheckEnabled: Bool?
}

struct RNPrimerThreeDsOptions: Codable {
    var iOS: ThreeDsOptionsPlatform?
    var android: ThreeDsOptionsPlatform?

    struct ThreeDsOptionsPlatform: Codable {
        var threeDsAppRequestorUrl: String?
    }
}

struct RNPrimerStripeOptions: Codable {
    var publishableKey: String?
    var mandateData: RNPrimerStripeMandateData?
}

enum RNPrimerStripeMandateData: Codable {
    case template(RNPrimerStripeTemplateMandateData)
    case full(RNPrimerFullMandateData)

    enum CodingKeys: String, CodingKey {
        case merchantName, fullMandateText, fullMandateStringResourceName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let merchantName = try? container.decode(String.self, forKey: .merchantName) {
            self = .template(RNPrimerStripeTemplateMandateData(merchantName: merchantName))
        } else if let fullMandateText = try? container.decode(String.self, forKey: .fullMandateText) {
            let fullMandateStringResourceName = try container.decodeIfPresent(String.self, forKey: .fullMandateStringResourceName)
            self = .full(RNPrimerFullMandateData(fullMandateText: fullMandateText, fullMandateStringResourceName: fullMandateStringResourceName))
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unknown PrimerStripeMandateData type"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .template(let data):
            try container.encode(data.merchantName, forKey: .merchantName)
        case .full(let data):
            try container.encode(data.fullMandateText, forKey: .fullMandateText)
            try container.encodeIfPresent(data.fullMandateStringResourceName, forKey: .fullMandateStringResourceName)
        }
    }
}

struct RNPrimerStripeTemplateMandateData {
    var merchantName: String
}

struct RNPrimerFullMandateData {
    var fullMandateText: String
    var fullMandateStringResourceName: String?
}
