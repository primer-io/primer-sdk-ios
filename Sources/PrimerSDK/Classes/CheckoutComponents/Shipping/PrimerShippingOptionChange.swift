//
//  PrimerShippingOptionChange.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// The shopper selected ``selectedShippingOption``, or the default option is being committed.
@available(iOS 15.0, *)
public struct PrimerShippingOptionChange: Sendable {

  public let paymentMethodType: String
  public let selectedShippingOption: PrimerShippingOption

  public init(paymentMethodType: String, selectedShippingOption: PrimerShippingOption) {
    self.paymentMethodType = paymentMethodType
    self.selectedShippingOption = selectedShippingOption
  }
}
