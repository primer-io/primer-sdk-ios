//
//  QRCodeRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
struct QRCodePaymentData {
  let qrCodeImageData: Data
  let statusUrl: URL
  let paymentId: String
}

@available(iOS 15.0, *)
protocol QRCodeRepository {
  func startPayment(paymentMethodType: String) async throws -> QRCodePaymentData
  func pollForCompletion(statusUrl: URL) async throws -> String
  func resumePayment(paymentId: String, resumeToken: String, paymentMethodType: String) async throws -> PaymentResult
  func cancelPolling(paymentMethodType: String)
}
