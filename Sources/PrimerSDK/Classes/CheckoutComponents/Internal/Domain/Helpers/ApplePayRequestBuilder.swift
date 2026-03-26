//
//  ApplePayRequestBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit

@available(iOS 15.0, *)
struct ApplePayRequestBuilder {

  static func build() throws -> ApplePayRequest {
    guard
      let countryCode = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?
        .countryCode
    else {
      throw PrimerError.invalidClientSessionValue(name: "order.countryCode")
    }

    guard
      let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?
        .merchantIdentifier
    else {
      throw PrimerError.invalidMerchantIdentifier()
    }

    guard let currency = AppState.current.currency else {
      throw PrimerError.invalidValue(key: "currency")
    }

    guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
      throw PrimerError.invalidValue(key: "clientSession")
    }

    let shippingMethods = getShippingMethods()

    return ApplePayRequest(
      currency: currency,
      merchantIdentifier: merchantIdentifier,
      countryCode: countryCode,
      items: try createOrderItems(from: clientSession),
      shippingMethods: shippingMethods.methods
    )
  }

  private static func createOrderItems(from clientSession: ClientSession.APIResponse) throws
    -> [ApplePayOrderItem] {
    var orderItems: [ApplePayOrderItem] = []

    let merchantName =
      getApplePayOptions()?.merchantName
      ?? PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName
      ?? ""

    if let merchantAmount = clientSession.order?.merchantAmount {
      orderItems.append(try ApplePayOrderItem(
        name: merchantName,
        unitAmount: merchantAmount,
        quantity: 1,
        discountAmount: nil,
        taxAmount: nil
      ))

    } else if let lineItems = clientSession.order?.lineItems, !lineItems.isEmpty {
      for lineItem in lineItems {
        orderItems.append(try lineItem.toOrderItem())
      }

      if let fees = clientSession.order?.fees {
        for fee in fees {
          switch fee.type {
          case .surcharge:
            orderItems.append(try ApplePayOrderItem(
              name: Strings.ApplePay.surcharge,
              unitAmount: fee.amount,
              quantity: 1,
              discountAmount: nil,
              taxAmount: nil
            ))
          }
        }
      }

      if let selectedShippingItem = getShippingMethods().selectedItem {
        orderItems.append(selectedShippingItem)
      }

      orderItems.append(try ApplePayOrderItem(
        name: merchantName,
        unitAmount: clientSession.order?.totalOrderAmount,
        quantity: 1,
        discountAmount: nil,
        taxAmount: nil
      ))

    } else {
      throw PrimerError.invalidValue(
        key: "clientSession.order.lineItems or clientSession.order.merchantAmount"
      )
    }

    return orderItems
  }

  private struct ShippingMethodsInfo {
    let methods: [PKShippingMethod]?
    let selectedItem: ApplePayOrderItem?
  }

  private static func getShippingMethods() -> ShippingMethodsInfo {
    guard
      let options = PrimerAPIConfigurationModule
        .apiConfiguration?
        .checkoutModules?
        .first(where: { $0.type == "SHIPPING" })?
        .options as? Response.Body.Configuration.CheckoutModule.ShippingMethodOptions
    else {
      return ShippingMethodsInfo(methods: nil, selectedItem: nil)
    }

    let factor: NSDecimalNumber = AppState.current.currency?.isZeroDecimal == true ? 1 : 100

    let pkShippingMethods = options.shippingMethods.map { method -> PKShippingMethod in
      let amount = NSDecimalNumber(value: method.amount).dividing(by: factor)
      let pkMethod = PKShippingMethod(label: method.name, amount: amount)
      pkMethod.detail = method.description
      pkMethod.identifier = method.id
      return pkMethod
    }

    let selectedItem = options.shippingMethods
      .first { $0.id == options.selectedShippingMethod }
      .flatMap { try? ApplePayOrderItem(
        name: "Shipping",
        unitAmount: $0.amount,
        quantity: 1,
        discountAmount: nil,
        taxAmount: nil
      ) }

    return ShippingMethodsInfo(methods: pkShippingMethods, selectedItem: selectedItem)
  }

  private static func getApplePayOptions() -> ApplePayOptions? {
    PrimerAPIConfiguration.current?.paymentMethods?
      .first(where: { $0.internalPaymentMethodType == .applePay })?
      .options as? ApplePayOptions
  }
}
