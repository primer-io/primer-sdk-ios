//
//  ProcessQRCodePaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

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
    logger.debug(message: "Starting QR code payment flow for \(paymentMethodType)")

    do {
      let paymentData = try await repository.startPayment(paymentMethodType: paymentMethodType)
      logger.debug(message: "QR code payment data received, statusUrl: \(paymentData.statusUrl)")
      return paymentData
    } catch {
      logger.error(message: "QR code start payment failed: \(error)", error: error)
      throw error
    }
  }

  func pollAndComplete(statusUrl: URL, paymentId: String) async throws -> PaymentResult {
    logger.debug(message: "Starting polling for QR code payment completion")

    do {
      let resumeToken = try await repository.pollForCompletion(statusUrl: statusUrl)
      logger.debug(message: "Polling complete, resuming payment")

      let result = try await repository.resumePayment(
        paymentId: paymentId,
        resumeToken: resumeToken,
        paymentMethodType: paymentMethodType
      )
      logger.debug(message: "QR code payment completed successfully")
      return result
    } catch {
      logger.error(message: "QR code poll/complete failed: \(error)", error: error)
      throw error
    }
  }

  func cancelPolling() {
    logger.debug(message: "Cancelling QR code polling")
    repository.cancelPolling(paymentMethodType: paymentMethodType)
  }
}
