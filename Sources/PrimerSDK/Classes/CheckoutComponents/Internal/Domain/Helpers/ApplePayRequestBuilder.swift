//
//  ApplePayRequestBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit

/// Helper to construct ApplePayRequest from session data.
/// Reuses logic from ApplePayTokenizationViewModel for order item construction.
@available(iOS 15.0, *)
struct ApplePayRequestBuilder {

    // MARK: - Build Request

    /// Builds an ApplePayRequest from the current API configuration and settings.
    /// - Returns: A configured ApplePayRequest ready for presentation
    /// - Throws: PrimerError if required configuration is missing
    static func build() throws -> ApplePayRequest {
        // Validate and get required configuration
        guard let countryCode = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode else {
            throw PrimerError.invalidClientSessionValue(name: "order.countryCode")
        }

        guard let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier else {
            throw PrimerError.invalidMerchantIdentifier()
        }

        guard let currency = AppState.current.currency else {
            throw PrimerError.invalidValue(key: "currency")
        }

        guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
            throw PrimerError.invalidValue(key: "clientSession")
        }

        // Build order items
        let orderItems = try createOrderItems(from: clientSession)

        // Get shipping methods if available
        let shippingMethods = getShippingMethods()

        return ApplePayRequest(
            currency: currency,
            merchantIdentifier: merchantIdentifier,
            countryCode: countryCode,
            items: orderItems,
            shippingMethods: shippingMethods.methods
        )
    }

    // MARK: - Order Items Construction

    /// Creates order items from client session.
    /// Reuses logic from ApplePayTokenizationViewModel.createOrderItemsFromClientSession
    private static func createOrderItems(from clientSession: ClientSession.APIResponse) throws -> [ApplePayOrderItem] {
        var orderItems: [ApplePayOrderItem] = []

        // Get merchant name from server config or local settings
        let applePayOptions = getApplePayOptions()
        let merchantName = applePayOptions?.merchantName
            ?? PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName
            ?? ""

        if let merchantAmount = clientSession.order?.merchantAmount {
            // Hardcoded amount - create single summary item
            let summaryItem = try ApplePayOrderItem(
                name: merchantName,
                unitAmount: merchantAmount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil
            )
            orderItems.append(summaryItem)

        } else if let lineItems = clientSession.order?.lineItems, !lineItems.isEmpty {
            // Map line items
            for lineItem in lineItems {
                let orderItem = try lineItem.toOrderItem()
                orderItems.append(orderItem)
            }

            // Add fees (surcharge)
            if let fees = clientSession.order?.fees {
                for fee in fees {
                    switch fee.type {
                    case .surcharge:
                        let feeItem = try ApplePayOrderItem(
                            name: Strings.ApplePay.surcharge,
                            unitAmount: fee.amount,
                            quantity: 1,
                            discountAmount: nil,
                            taxAmount: nil
                        )
                        orderItems.append(feeItem)
                    }
                }
            }

            // Add shipping if selected
            let shippingInfo = getShippingMethods()
            if let selectedShippingItem = shippingInfo.selectedItem {
                orderItems.append(selectedShippingItem)
            }

            // Add total summary item
            let summaryItem = try ApplePayOrderItem(
                name: merchantName,
                unitAmount: clientSession.order?.totalOrderAmount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil
            )
            orderItems.append(summaryItem)

        } else {
            throw PrimerError.invalidValue(
                key: "clientSession.order.lineItems or clientSession.order.merchantAmount"
            )
        }

        return orderItems
    }

    // MARK: - Shipping Methods

    private struct ShippingMethodsInfo {
        let methods: [PKShippingMethod]?
        let selectedItem: ApplePayOrderItem?
    }

    private static func getShippingMethods() -> ShippingMethodsInfo {
        guard let options = PrimerAPIConfigurationModule
            .apiConfiguration?
            .checkoutModules?
            .first(where: { $0.type == "SHIPPING" })?
            .options as? Response.Body.Configuration.CheckoutModule.ShippingMethodOptions else {
            return ShippingMethodsInfo(methods: nil, selectedItem: nil)
        }

        var factor: NSDecimalNumber
        if AppState.current.currency?.isZeroDecimal == true {
            factor = 1
        } else {
            factor = 100
        }

        // Convert to PKShippingMethods
        let pkShippingMethods = options.shippingMethods.map { method -> PKShippingMethod in
            let amount = NSDecimalNumber(value: method.amount).dividing(by: factor)
            let pkMethod = PKShippingMethod(label: method.name, amount: amount)
            pkMethod.detail = method.description
            pkMethod.identifier = method.id
            return pkMethod
        }

        // Get selected shipping item
        var selectedItem: ApplePayOrderItem?
        if let selectedMethod = options.shippingMethods.first(where: { $0.id == options.selectedShippingMethod }) {
            selectedItem = try? ApplePayOrderItem(
                name: "Shipping",
                unitAmount: selectedMethod.amount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil
            )
        }

        return ShippingMethodsInfo(methods: pkShippingMethods, selectedItem: selectedItem)
    }

    // MARK: - Helpers

    private static func getApplePayOptions() -> ApplePayOptions? {
        PrimerAPIConfiguration.current?.paymentMethods?
            .first(where: { $0.internalPaymentMethodType == .applePay })?
            .options as? ApplePayOptions
    }
}
