//
//  ApplePay.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
import PrimerFoundation
import PrimerNetworking

public enum MerchantCapability {
    case capability3DS
    case capabilityEMV
    case capabilityCredit
    case capabilityDebit
}

struct ApplePayRequest {
    var amount: Int?
    var paymentDescriptor: String?
    var currency: Currency
    var merchantIdentifier: String
    var countryCode: CountryCode
    var items: [ApplePayOrderItem]
    var shippingMethods: [PKShippingMethod]?
    var recurringPaymentRequest: ApplePayRecurringPaymentRequest?
    var deferredPaymentRequest: ApplePayDeferredPaymentRequest?
    var automaticReloadRequest: ApplePayAutomaticReloadRequest?
}

struct ApplePayPaymentResponse {
    let token: ApplePayPaymentInstrument.PaymentResponseToken
    let billingAddress: ClientSession.Address?
    let shippingAddress: ClientSession.Address?
    let mobileNumber: String?
    let emailAddress: String?
}

struct ApplePayPaymentResponsePaymentMethod: Codable {
    let displayName: String?
    let network: String?
    let type: String?
}

struct ApplePayPaymentResponseTokenPaymentData: Codable {
    let data: String
    let signature: String
    let version: String
    let header: ApplePayTokenPaymentDataHeader
}

struct ApplePayTokenPaymentDataHeader: Codable {
    let ephemeralPublicKey: String
    let publicKeyHash: String
    let transactionId: String
}
