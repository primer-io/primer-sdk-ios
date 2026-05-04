//
//  ProcessQRCodePaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
protocol ProcessQRCodePaymentInteractor {
  func startPayment() async throws -> QRCodePaymentData
  func pollAndComplete(statusUrl: URL, paymentId: String) async throws -> PaymentResult
  func cancelPolling()
}

@available(iOS 15.0, *)
final class ProcessQRCodePaymentInteractorImpl: ProcessQRCodePaymentInteractor, LogReporter {

  private let repository: QRCodeRepository
  private let paymentMethodType: String

  init(repository: QRCodeRepository, paymentMethodType: String) {
    self.repository = repository
    self.paymentMethodType = paymentMethodType
  }

  func startPayment() async throws -> QRCodePaymentData {
    do {
      return try await repository.startPayment(paymentMethodType: paymentMethodType)
    } catch {
      logger.error(message: "QR code start payment failed: \(error)", error: error)
      throw error
    }
  }

  func pollAndComplete(statusUrl: URL, paymentId: String) async throws -> PaymentResult {
    do {
      let resumeToken = try await repository.pollForCompletion(statusUrl: statusUrl)
      return try await repository.resumePayment(
        paymentId: paymentId,
        resumeToken: resumeToken,
        paymentMethodType: paymentMethodType
      )
    } catch {
      logger.error(message: "QR code poll/complete failed: \(error)", error: error)
      throw error
    }
  }

  func cancelPolling() {
    repository.cancelPolling(paymentMethodType: paymentMethodType)
  }
}
