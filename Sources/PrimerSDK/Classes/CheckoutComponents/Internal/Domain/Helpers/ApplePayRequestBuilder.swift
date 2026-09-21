//
//  ApplePayRequestBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

@available(iOS 15.0, *)
struct ApplePayRequestBuilder {

  static func build(mode: ApplePayShippingSession.Mode = .legacy) throws -> ApplePayRequest {
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

    let shippingMethods = getShippingMethods(mode: mode)

    return ApplePayRequest(
      currency: currency,
      merchantIdentifier: merchantIdentifier,
      countryCode: countryCode,
      items: try createOrderItems(from: clientSession, selectedShippingItem: shippingMethods.selectedItem),
      shippingMethods: shippingMethods.methods
    )
  }

  /// Rebuilds the sheet's summary items from the client session as it stands now.
  ///
  /// Called after a shipping commit, where the total Apple must show is the one Primer recomputed from
  /// the merchant's `PATCH`, not the one the sheet opened with.
  static func orderItems(mode: ApplePayShippingSession.Mode) throws -> [ApplePayOrderItem] {
    guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
      throw PrimerError.invalidValue(key: "clientSession")
    }
    return try createOrderItems(
      from: clientSession,
      selectedShippingItem: getShippingMethods(mode: mode).selectedItem
    )
  }

  /// Maps the merchant's options onto the sheet. Apple renders the amount itself, so unlike Google Pay
  /// there is nothing to fold into the label.
  static func shippingMethods(from options: [PrimerShippingOption]) -> [PKShippingMethod] {
    let factor = AppState.current.currency.map { NSDecimalNumber(decimal: $0.minorUnitDivisor) } ?? 100
    return options.map { option in
      let method = PKShippingMethod(
        label: option.name,
        amount: NSDecimalNumber(value: option.amount).dividing(by: factor)
      )
      method.detail = option.description
      method.identifier = option.id
      return method
    }
  }

  private static func createOrderItems(
    from clientSession: ClientSession.APIResponse,
    selectedShippingItem: ApplePayOrderItem?
  ) throws -> [ApplePayOrderItem] {
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

      if let selectedShippingItem {
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

  private static func getShippingMethods(mode: ApplePayShippingSession.Mode) -> ShippingMethodsInfo {
    // In callback mode Primer stores no option list, and the shipping line is whatever the merchant's
    // PATCH committed. The sheet's options arrive from the merchant callback instead.
    guard mode == .legacy else {
      let committed = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.shippingMethod
      let selectedItem = committed.flatMap { try? ApplePayOrderItem(
        // The merchant's PATCH supplies the shopper-facing name; "Shipping" only shows if it omitted
        // methodName, and matches the label the legacy path already uses.
        name: $0.methodName ?? "Shipping",
        unitAmount: $0.amount,
        quantity: 1,
        discountAmount: nil,
        taxAmount: nil
      ) }
      return ShippingMethodsInfo(methods: nil, selectedItem: selectedItem)
    }

    guard
      let options = PrimerAPIConfigurationModule
        .apiConfiguration?
        .checkoutModules?
        .first(where: { $0.type == "SHIPPING" })?
        .options as? Response.Body.Configuration.CheckoutModule.ShippingMethodOptions
    else {
      return ShippingMethodsInfo(methods: nil, selectedItem: nil)
    }

    let factor = AppState.current.currency.map { NSDecimalNumber(decimal: $0.minorUnitDivisor) } ?? 100

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
