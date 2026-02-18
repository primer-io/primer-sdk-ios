//
//  DecodedJWTToken.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public struct DecodedJWTToken: Codable {

    public var accessToken: String? // Always present
    public var analyticsUrl: String?
    public var analyticsUrlV2: String?
    public var configurationUrl: String?
    public var coreUrl: String?
    public var env: String?
    public var expDate: Date? // Always present
    public var intent: String? // Always present
    public var paymentFlow: String?
    public var pciUrl: String?
    public var redirectUrl: String?
    public var statusUrl: String?
    public var threeDSecureInitUrl: String?
    public var threeDSecureToken: String?
    public var useThreeDsWeakValidation: Bool?
    public var supportedThreeDsProtocolVersions: [String]?
    public var qrCode: String?
    public var accountNumber: String?

    // iPay88
    public var backendCallbackUrl: String?
    public var primerTransactionId: String?
    public var iPay88PaymentMethodId: String?
    public var iPay88ActionType: String?
    public var supportedCurrencyCode: String?
    public var supportedCountry: String?

    // Nol
    public var nolPayTransactionNo: String?

    // StripeACH
    public var stripeClientSecret: String?
    public var sdkCompleteUrl: String?

    // Voucher info
    public var expiresAt: Date?
    public var entity: String?
    public var reference: String?

    enum CodingKeys: String, CodingKey {
        case accessToken
        case analyticsUrl
        case analyticsUrlV2
        case configurationUrl
        case coreUrl
        case env
        case intent
        case paymentFlow
        case pciUrl
        case redirectUrl
        case statusUrl
        case threeDSecureInitUrl
        case threeDSecureToken
        case useThreeDsWeakValidation
        case supportedThreeDsProtocolVersions
        case accountNumber
        // Expiration
        case exp
        case expiration
        // iPay88
        case backendCallbackUrl
        case primerTransactionId
        case iPay88PaymentMethodId
        case iPay88ActionType
        case supportedCurrencyCode
        case supportedCountry
        // QR Code
        case qrCode
        case qrCodeUrl
        // Voucher info
        case expiresAt
        case entity
        case reference
        // Nol
        case nolPayTransactionNo
        // StripeACH
        case stripeClientSecret
        case sdkCompleteUrl
    }

    public init(
        accessToken: String?,
        expDate: Date?,
        configurationUrl: String?,
        paymentFlow: String?,
        threeDSecureInitUrl: String?,
        threeDSecureToken: String?,
        supportedThreeDsProtocolVersions: [String]?,
        coreUrl: String?,
        pciUrl: String?,
        env: String?,
        intent: String?,
        statusUrl: String?,
        redirectUrl: String?,
        qrCode: String?,
        accountNumber: String?,
        backendCallbackUrl: String?,
        primerTransactionId: String?,
        iPay88PaymentMethodId: String?,
        iPay88ActionType: String?,
        supportedCurrencyCode: String?,
        supportedCountry: String?,
        nolPayTransactionNo: String?,
        stripeClientSecret: String?,
        sdkCompleteUrl: String?
    ) {
        self.accessToken = accessToken
        self.expDate = expDate
        self.configurationUrl = configurationUrl
        self.paymentFlow = paymentFlow
        self.threeDSecureInitUrl = threeDSecureInitUrl
        self.threeDSecureToken = threeDSecureToken
        self.supportedThreeDsProtocolVersions = supportedThreeDsProtocolVersions
        self.coreUrl = coreUrl
        self.pciUrl = pciUrl
        self.env = env
        self.intent = intent
        self.statusUrl = statusUrl
        self.redirectUrl = redirectUrl
        self.qrCode = qrCode
        self.accountNumber = accountNumber
        self.backendCallbackUrl = backendCallbackUrl
        self.primerTransactionId = primerTransactionId
        self.iPay88PaymentMethodId = iPay88PaymentMethodId
        self.iPay88ActionType = iPay88ActionType
        self.supportedCurrencyCode = supportedCurrencyCode
        self.supportedCountry = supportedCountry
        self.nolPayTransactionNo = nolPayTransactionNo
        self.stripeClientSecret = stripeClientSecret
        self.sdkCompleteUrl = sdkCompleteUrl
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try? container.decode(String.self, forKey: .accessToken)
        self.analyticsUrl = try? container.decode(String.self, forKey: .analyticsUrl)
        self.analyticsUrlV2 = try? container.decode(String.self, forKey: .analyticsUrlV2)
        self.configurationUrl = try? container.decode(String.self, forKey: .configurationUrl)
        self.paymentFlow = try? container.decode(String.self, forKey: .paymentFlow)
        self.threeDSecureInitUrl = try? container.decode(String.self, forKey: .threeDSecureInitUrl)
        self.threeDSecureToken = try? container.decode(String.self, forKey: .threeDSecureToken)
        self.useThreeDsWeakValidation = try? container.decode(Bool.self, forKey: .useThreeDsWeakValidation)
        self.supportedThreeDsProtocolVersions = try container.decodeIfPresent([String].self,
                                                                              forKey: .supportedThreeDsProtocolVersions)
        self.coreUrl = try? container.decode(String.self, forKey: .coreUrl)
        self.pciUrl = try? container.decode(String.self, forKey: .pciUrl)
        self.env = try? container.decode(String.self, forKey: .env)
        self.intent = try? container.decode(String.self, forKey: .intent)
        self.statusUrl = try? container.decode(String.self, forKey: .statusUrl)
        self.redirectUrl = try? container.decode(String.self, forKey: .redirectUrl)
        self.accountNumber = try? container.decode(String.self, forKey: .accountNumber)
        self.nolPayTransactionNo = try? container.decode(String.self, forKey: .nolPayTransactionNo)
        self.stripeClientSecret = try? container.decode(String.self, forKey: .stripeClientSecret)
        self.sdkCompleteUrl = try? container.decode(String.self, forKey: .sdkCompleteUrl)
        // For some APMs we receive another value out of the client token `expiration`
        // They may have different values.
        // We understand this should be changed in the future
        // In the meantime, in case of having both `exp` and `expiration`
        // we let `expiration` take the value of our parameter `expDate`
        // we use thorughout the codebase
        if let expDateInt = try? container.decode(Int.self, forKey: .exp) {
            self.expDate = Date(timeIntervalSince1970: TimeInterval(expDateInt))
        }
        if let expirationDateInt = try? container.decode(Int.self, forKey: .expiration) {
            self.expDate = Date(timeIntervalSince1970: TimeInterval(expirationDateInt))
        }

        // For some APMs we receive one more value out of the client token `qrCode`
        // They may have different values.
        // Either a URL or a Base64 string.
        // In case of `qrCode`, we get the Base64 String
        // In case of `qrCodeUrl`, we get the Image URL
        // We understand this should be changed in the future.
        // However, for now, we evaluate the `qrCode` variable with either URL or Base64
        if let qrCode = try? container.decode(String.self, forKey: .qrCode) {
            self.qrCode = qrCode
        } else if let qrCode = try? container.decode(String.self, forKey: .qrCodeUrl) {
            self.qrCode = qrCode
        }

        // iPay88
        self.backendCallbackUrl = try container.decodeIfPresent(String.self, forKey: .backendCallbackUrl)
        self.primerTransactionId = try container.decodeIfPresent(String.self, forKey: .primerTransactionId)
        self.iPay88PaymentMethodId = try container.decodeIfPresent(String.self, forKey: .iPay88PaymentMethodId)
        self.iPay88ActionType = try container.decodeIfPresent(String.self, forKey: .iPay88ActionType)
        self.supportedCurrencyCode = try container.decodeIfPresent(String.self, forKey: .supportedCurrencyCode)
        self.supportedCountry = try container.decodeIfPresent(String.self, forKey: .supportedCountry)

        // Voucher info
        if let dateString = try? container.decode(String.self, forKey: .expiresAt) {
            let dateFormatter = DateFormatter().withVoucherExpirationDateFormat()
            self.expiresAt = dateFormatter.date(from: dateString)
        }
        // Voucher info date returned in ISO8601
        if let dateString = try? container.decode(String.self, forKey: .expiresAt) {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = .withFullDate
            self.expiresAt = dateFormatter.date(from: dateString)
        }
        self.reference = try? container.decode(String.self, forKey: .reference)
        self.entity = try? container.decode(String.self, forKey: .entity)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(accessToken, forKey: .accessToken)
        try? container.encode(configurationUrl, forKey: .configurationUrl)
        try? container.encode(paymentFlow, forKey: .paymentFlow)
        try? container.encode(threeDSecureInitUrl, forKey: .threeDSecureInitUrl)
        try? container.encode(threeDSecureToken, forKey: .threeDSecureToken)
        try container.encodeIfPresent(useThreeDsWeakValidation, forKey: .useThreeDsWeakValidation)
        try container.encodeIfPresent(supportedThreeDsProtocolVersions, forKey: .supportedThreeDsProtocolVersions)
        try? container.encode(coreUrl, forKey: .coreUrl)
        try? container.encode(pciUrl, forKey: .pciUrl)
        try? container.encode(env, forKey: .env)
        try? container.encode(intent, forKey: .intent)
        try? container.encode(statusUrl, forKey: .statusUrl)
        try? container.encode(redirectUrl, forKey: .redirectUrl)
        try? container.encode(accountNumber, forKey: .accountNumber)
        try? container.encode(expDate?.timeIntervalSince1970, forKey: .expiration)
        try? container.encode(expDate?.timeIntervalSince1970, forKey: .exp)

        if qrCode?.isHttpOrHttpsURL == true {
            try? container.encode(qrCode, forKey: .qrCodeUrl)
        } else {
            try? container.encode(qrCode, forKey: .qrCode)
        }

        // iPay88
        try? container.encode(backendCallbackUrl, forKey: .backendCallbackUrl)
        try? container.encode(primerTransactionId, forKey: .primerTransactionId)
        try? container.encode(iPay88PaymentMethodId, forKey: .iPay88PaymentMethodId)
        try? container.encode(iPay88ActionType, forKey: .iPay88ActionType)
        try? container.encode(supportedCurrencyCode, forKey: .supportedCurrencyCode)
        try? container.encode(supportedCountry, forKey: .supportedCountry)

        // Voucher info
        try? container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(reference, forKey: .reference)
        try? container.encode(entity, forKey: .entity)

        // Nol
        try? container.encode(nolPayTransactionNo, forKey: .nolPayTransactionNo)

        // StripeACH
        try? container.encode(stripeClientSecret, forKey: .stripeClientSecret)
        try? container.encode(sdkCompleteUrl, forKey: .sdkCompleteUrl)
    }
}
