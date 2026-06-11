//
//  PrimerBillingAddressRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Billing address redirect flow:
/// `ready` -> `submitting` -> `redirecting` -> `polling` -> `success` | `failure`
@available(iOS 15.0, *)
struct PrimerBillingAddressRedirectState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  enum Status: Equatable {
    case ready
    case submitting
    case redirecting
    case polling
    case success
    case failure(String)
  }

  var status: Status
  var paymentMethod: CheckoutPaymentMethod?
  var surchargeAmount: String?

  // MARK: - Billing Address Fields

  var countryCode: String
  var addressLine1: String
  var addressLine2: String
  var postalCode: String
  var city: String
  var state: String

  // MARK: - Validation

  var errors: [PrimerInputElementType: FieldError]
  var isFormValid: Bool

  init(
    status: Status = .ready,
    paymentMethod: CheckoutPaymentMethod? = nil,
    surchargeAmount: String? = nil
  ) {
    self.status = status
    self.paymentMethod = paymentMethod
    self.surchargeAmount = surchargeAmount
    countryCode = ""
    addressLine1 = ""
    addressLine2 = ""
    postalCode = ""
    city = ""
    state = ""
    errors = [:]
    isFormValid = false
  }
}
