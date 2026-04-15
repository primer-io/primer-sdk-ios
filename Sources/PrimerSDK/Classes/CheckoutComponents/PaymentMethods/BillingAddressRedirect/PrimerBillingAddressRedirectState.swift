//
//  PrimerBillingAddressRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Billing address redirect flow:
/// `ready` -> `submitting` -> `redirecting` -> `polling` -> `success` | `failure`
@available(iOS 15.0, *)
public struct PrimerBillingAddressRedirectState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  public enum Status: Equatable {
    case ready
    case submitting
    case redirecting
    case polling
    case success
    case failure(String)
  }

  public internal(set) var status: Status
  public internal(set) var paymentMethod: CheckoutPaymentMethod?
  public internal(set) var surchargeAmount: String?

  // MARK: - Billing Address Fields

  public internal(set) var countryCode: String
  public internal(set) var addressLine1: String
  public internal(set) var addressLine2: String
  public internal(set) var postalCode: String
  public internal(set) var city: String
  public internal(set) var state: String

  // MARK: - Validation

  public internal(set) var errors: [PrimerInputElementType: FieldError]
  public internal(set) var isFormValid: Bool

  public init(
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
