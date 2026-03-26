//
//  PayPalRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
struct PayPalBillingAgreementResult: Equatable {
  let billingAgreementId: String
  let externalPayerInfo: PayPalPayerInfo?
  let shippingAddress: PayPalShippingAddress?
}

@available(iOS 15.0, *)
struct PayPalPayerInfo: Equatable {
  let externalPayerId: String?
  let email: String?
  let firstName: String?
  let lastName: String?
}

@available(iOS 15.0, *)
struct PayPalShippingAddress: Equatable {
  let firstName: String?
  let lastName: String?
  let addressLine1: String?
  let addressLine2: String?
  let city: String?
  let state: String?
  let countryCode: String?
  let postalCode: String?
}

@available(iOS 15.0, *)
enum PayPalPaymentInstrumentData {
  case order(orderId: String, payerInfo: PayPalPayerInfo?)
  case billingAgreement(result: PayPalBillingAgreementResult)
}

@available(iOS 15.0, *)
protocol PayPalRepository {
  func startOrderSession() async throws -> (orderId: String, approvalUrl: String)
  func startBillingAgreementSession() async throws -> String
  func openWebAuthentication(url: URL) async throws -> URL
  func confirmBillingAgreement() async throws -> PayPalBillingAgreementResult
  func fetchPayerInfo(orderId: String) async throws -> PayPalPayerInfo
  func tokenize(paymentInstrument: PayPalPaymentInstrumentData) async throws -> PaymentResult
}
