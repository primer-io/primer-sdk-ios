//
//  PrimerClientSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@objc public final class PrimerClientSession: NSObject, Codable {

    public let customerId: String?
    public let orderId: String?
    public let currencyCode: String?
    public let totalAmount: Int?
    public let lineItems: [PrimerLineItem]?
    public let orderDetails: PrimerOrder?
    public let customer: PrimerCustomer?
    public let checkoutModules: [PrimerCheckoutModule]?

    public init(
        customerId: String?,
        orderId: String?,
        currencyCode: String?,
        totalAmount: Int?,
        lineItems: [PrimerLineItem]?,
        orderDetails: PrimerOrder?,
        customer: PrimerCustomer?,
        checkoutModules: [PrimerCheckoutModule]?
    ) {
        self.customerId = customerId
        self.orderId = orderId
        self.currencyCode = currencyCode
        self.totalAmount = totalAmount
        self.lineItems = lineItems
        self.orderDetails = orderDetails
        self.customer = customer
        self.checkoutModules = checkoutModules
    }
}

/// Merchant-facing projection of a `CheckoutModule` entry from the client session configuration.
/// Surfaces the module `type` (e.g. `"BILLING_ADDRESS"`) and its flat boolean `options` map so
/// consumers — RN bridge, headless integrators — can drive per-field UI without reaching into
/// the internal `PrimerAPIConfiguration.CheckoutModule` types.
@objc public final class PrimerCheckoutModule: NSObject, Codable {

    public let type: String
    public let options: [String: Bool]?

    public init(type: String, options: [String: Bool]?) {
        self.type = type
        self.options = options
    }
}

extension PrimerClientSession {
    convenience init(from apiConfiguration: PrimerAPIConfiguration) {
        let session = apiConfiguration.clientSession
        self.init(
            customerId: session?.customer?.id,
            orderId: session?.order?.id,
            currencyCode: session?.order?.currencyCode?.code,
            totalAmount: session?.order?.totalOrderAmount,
            lineItems: session?.order?.lineItems?.compactMap { PrimerLineItem(lineItem: $0, session: session) },
            orderDetails: PrimerOrder(clientSessionOrder: session?.order),
            customer: PrimerCustomer(customer: session?.customer),
            checkoutModules: apiConfiguration.checkoutModules?.map(PrimerCheckoutModule.init)
        )
    }
}

private extension PrimerCheckoutModule {
    convenience init(module: PrimerAPIConfiguration.CheckoutModule) {
        self.init(type: module.type, options: Self.flatten(module.options))
    }

    /// Flattens the typed, closed set of `CheckoutModuleOptions` subtypes into a generic
    /// `[String: Bool]` map suitable for cross-language consumers. Option types that don't
    /// fit a flat boolean shape (e.g. `ShippingMethodOptions`) map to `nil` for now — the
    /// module is still surfaced by `type`, just without an options payload.
    static func flatten(_ options: CheckoutModuleOptions?) -> [String: Bool]? {
        if let postal = options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions {
            var dict: [String: Bool] = [:]
            if let v = postal.firstName { dict["firstName"] = v }
            if let v = postal.lastName { dict["lastName"] = v }
            if let v = postal.city { dict["city"] = v }
            if let v = postal.postalCode { dict["postalCode"] = v }
            if let v = postal.addressLine1 { dict["addressLine1"] = v }
            if let v = postal.addressLine2 { dict["addressLine2"] = v }
            if let v = postal.countryCode { dict["countryCode"] = v }
            if let v = postal.phoneNumber { dict["phoneNumber"] = v }
            if let v = postal.state { dict["state"] = v }
            return dict.isEmpty ? nil : dict
        }
        if let card = options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions {
            var dict: [String: Bool] = [:]
            if let v = card.cardHolderName { dict["cardHolderName"] = v }
            if let v = card.saveCardCheckbox { dict["saveCardCheckbox"] = v }
            return dict.isEmpty ? nil : dict
        }
        return nil
    }
}

private extension PrimerLineItem {
    convenience init(lineItem: ClientSession.Order.LineItem, session: ClientSession.APIResponse?) {
        self.init(
            itemId: lineItem.itemId,
            itemDescription: lineItem.description,
            amount: lineItem.amount,
            discountAmount: lineItem.discountAmount,
            quantity: lineItem.quantity,
            taxCode: session?.customer?.taxId,
            taxAmount: session?.order?.totalTaxAmount
        )
    }
}

private extension PrimerCustomer {
    convenience init(customer: ClientSession.Customer?) {
        self.init(
            emailAddress: customer?.emailAddress,
            mobileNumber: customer?.mobileNumber,
            firstName: customer?.firstName,
            lastName: customer?.lastName,
            billingAddress: customer?.billingAddress.map(PrimerAddress.init),
            shippingAddress: customer?.shippingAddress.map(PrimerAddress.init)
        )
    }
}

private extension PrimerAddress {
    convenience init(address: ClientSession.Address) {
        self.init(
            firstName: address.firstName,
            lastName: address.lastName,
            addressLine1: address.addressLine1,
            addressLine2: address.addressLine2,
            postalCode: address.postalCode,
            city: address.city,
            state: address.state,
            countryCode: address.countryCode?.rawValue
        )
    }
}
