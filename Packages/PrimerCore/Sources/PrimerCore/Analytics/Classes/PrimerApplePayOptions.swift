//
//  PrimerApplePayOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public final class PrimerApplePayOptions: Codable {

    public let merchantIdentifier: String
    @available(*, deprecated, message: "Use Client Session API to provide merchant name value: https://primer.io/docs/payment-methods/apple-pay/direct-integration#prepare-the-client-session")
    public let merchantName: String?
    @available(*, deprecated, message: "Use BillingOptions to configure required billing fields.")
    public let isCaptureBillingAddressEnabled: Bool
    /// If in some cases you dont want to present ApplePay option if the device is not supporting it set this to `false`.
    /// Default value is `true`.
    public let showApplePayForUnsupportedDevice: Bool
    /// Due to merchant report about ApplePay flow which was not presenting because
    /// canMakePayments(usingNetworks:) was returning false if there were no cards in the Wallet,
    /// we introduced this flag to continue supporting the old behaviour. Default value is `true`.
    public let checkProvidedNetworks: Bool
    public let shippingOptions: ShippingOptions?
    public let billingOptions: BillingOptions?

    public init(
        merchantIdentifier: String,
        merchantName: String?,
        isCaptureBillingAddressEnabled: Bool = false,
        showApplePayForUnsupportedDevice: Bool = true,
        checkProvidedNetworks: Bool = true
    ) {
        self.merchantIdentifier = merchantIdentifier
        self.merchantName = merchantName
        self.isCaptureBillingAddressEnabled = isCaptureBillingAddressEnabled
        self.showApplePayForUnsupportedDevice = showApplePayForUnsupportedDevice
        self.checkProvidedNetworks = checkProvidedNetworks
        self.shippingOptions = nil
        self.billingOptions = nil
    }

    public init(merchantIdentifier: String,
                merchantName: String?,
                isCaptureBillingAddressEnabled: Bool = false,
                showApplePayForUnsupportedDevice: Bool = true,
                checkProvidedNetworks: Bool = true,
                shippingOptions: ShippingOptions? = nil,
                billingOptions: BillingOptions? = nil) {
        self.merchantIdentifier = merchantIdentifier
        self.merchantName = merchantName
        self.isCaptureBillingAddressEnabled = isCaptureBillingAddressEnabled
        self.showApplePayForUnsupportedDevice = showApplePayForUnsupportedDevice
        self.checkProvidedNetworks = checkProvidedNetworks
        self.shippingOptions = shippingOptions
        self.billingOptions = billingOptions
    }

    public struct ShippingOptions: Codable {
        public let shippingContactFields: [RequiredContactField]?
        public let requireShippingMethod: Bool

        public init(shippingContactFields: [RequiredContactField]? = nil,
                    requireShippingMethod: Bool) {
            self.shippingContactFields = shippingContactFields
            self.requireShippingMethod = requireShippingMethod
        }
    }

    public struct BillingOptions: Codable {
        public let requiredBillingContactFields: [RequiredContactField]?

        public init(requiredBillingContactFields: [RequiredContactField]? = nil) {
            self.requiredBillingContactFields = requiredBillingContactFields
        }
    }

    public enum RequiredContactField: String, Codable {
        case name, emailAddress, phoneNumber, postalAddress
    }
}
