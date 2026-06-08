//
//  PaymentResult.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct PaymentResult: Sendable, Equatable {
  public let paymentId: String
  public let status: PaymentStatus
  public let token: String?
  public let redirectUrl: String?
  public let errorMessage: String?
  public let amount: Int?
  public let currencyCode: String?
  public let paymentMethodType: String?

  public init(
    paymentId: String,
    status: PaymentStatus,
    token: String? = nil,
    redirectUrl: String? = nil,
    errorMessage: String? = nil,
    amount: Int? = nil,
    currencyCode: String? = nil,
    paymentMethodType: String? = nil
  ) {
    self.paymentId = paymentId
    self.status = status
    self.token = token
    self.redirectUrl = redirectUrl
    self.errorMessage = errorMessage
    self.amount = amount
    self.currencyCode = currencyCode
    self.paymentMethodType = paymentMethodType
  }
}

/// When switching on this enum, always include a `default` case to handle future additions.
public enum PaymentStatus: Sendable {
  case pending
  case success
  case failed

  init(from apiStatus: Response.Body.Payment.Status) {
    switch apiStatus {
    case .success: self = .success
    case .pending: self = .pending
    case .failed: self = .failed
    }
  }
}
