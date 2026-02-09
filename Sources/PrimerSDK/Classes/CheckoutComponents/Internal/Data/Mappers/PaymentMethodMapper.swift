//
//  PaymentMethodMapper.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

protocol PaymentMethodMapper {
  func mapToPublic(_ internalMethod: InternalPaymentMethod) -> CheckoutPaymentMethod
  func mapToPublic(_ internalMethods: [InternalPaymentMethod]) -> [CheckoutPaymentMethod]
}

@available(iOS 15.0, *)
final class PaymentMethodMapperImpl: PaymentMethodMapper {

  private let configurationService: ConfigurationService

  init(configurationService: ConfigurationService) {
    self.configurationService = configurationService
  }

  func mapToPublic(_ internalMethod: InternalPaymentMethod) -> CheckoutPaymentMethod {
    let formattedSurcharge = formatSurcharge(
      internalMethod.surcharge, hasUnknownSurcharge: internalMethod.hasUnknownSurcharge)

    return CheckoutPaymentMethod(
      id: internalMethod.id,
      type: internalMethod.type,
      name: internalMethod.name,
      icon: internalMethod.icon,
      metadata: internalMethod.metadata,
      surcharge: internalMethod.surcharge,
      hasUnknownSurcharge: internalMethod.hasUnknownSurcharge,
      formattedSurcharge: formattedSurcharge,
      backgroundColor: internalMethod.backgroundColor
    )
  }

  func mapToPublic(_ internalMethods: [InternalPaymentMethod]) -> [CheckoutPaymentMethod] {
    internalMethods.map { mapToPublic($0) }
  }

  private func formatSurcharge(_ surcharge: Int?, hasUnknownSurcharge: Bool) -> String? {

    // Priority: unknown surcharge > actual surcharge > no fee
    if hasUnknownSurcharge {
      return CheckoutComponentsStrings.additionalFeeMayApply
    }

    guard let surcharge = surcharge,
      surcharge > 0,
      let currency = configurationService.currency
    else {
      return CheckoutComponentsStrings.noAdditionalFee
    }

    // Use existing currency formatting extension to match Drop-in/Headless behavior
    let formatted = surcharge.toCurrencyString(currency: currency)
    let result = "+\(formatted)"  // "+" prefix for surcharges
    return result
  }
}
