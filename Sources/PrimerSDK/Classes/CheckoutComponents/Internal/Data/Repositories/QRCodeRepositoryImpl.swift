//
//  QRCodeRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
final class QRCodeRepositoryImpl: QRCodeRepository, LogReporter {

  private let tokenizationService: TokenizationServiceProtocol
  private var pollingModule: PollingModule?

  init(tokenizationService: TokenizationServiceProtocol = TokenizationService()) {
    self.tokenizationService = tokenizationService
  }

  func startPayment(paymentMethodType: String) async throws -> QRCodePaymentData {
    guard let paymentMethodConfig = findPaymentMethodConfig(for: paymentMethodType),
      let configId = paymentMethodConfig.id
    else {
      throw PrimerError.invalidValue(
        key: "configuration.id",
        value: nil,
        reason: "Payment method configuration not found for \(paymentMethodType)"
      )
    }

    let sessionInfo = WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
    let paymentInstrument = OffSessionPaymentInstrument(
      paymentMethodConfigId: configId,
      paymentMethodType: paymentMethodType,
      sessionInfo: sessionInfo
    )
    let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
    let tokenData = try await tokenizationService.tokenize(requestBody: requestBody)

    guard let token = tokenData.token else {
      throw PrimerError.invalidValue(
        key: "paymentMethodToken",
        value: nil,
        reason: "Tokenization returned nil token"
      )
    }

    let createPaymentService = CreateResumePaymentService(paymentMethodType: paymentMethodType)
    let paymentRequest = Request.Body.Payment.Create(token: token)
    let paymentResponse = try await createPaymentService.createPayment(paymentRequest: paymentRequest)

    guard let paymentId = paymentResponse.id else {
      throw PrimerError.invalidValue(
        key: "payment.id",
        value: nil,
        reason: "Payment creation returned nil payment ID"
      )
    }

    guard let requiredAction = paymentResponse.requiredAction else {
      throw PrimerError.invalidValue(
        key: "requiredAction",
        value: nil,
        reason: "Payment response missing required action for QR code flow"
      )
    }

    let configModule = PrimerAPIConfigurationModule()
    try await configModule.storeRequiredActionClientToken(requiredAction.clientToken)

    guard let decodedJWT = PrimerAPIConfigurationModule.decodedJWTToken else {
      throw PrimerError.invalidClientToken()
    }

    guard let statusUrlStr = decodedJWT.statusUrl, let statusUrl = URL(string: statusUrlStr) else {
      throw PrimerError.invalidValue(
        key: "statusUrl",
        value: decodedJWT.statusUrl,
        reason: "JWT missing or invalid statusUrl"
      )
    }

    guard let qrCodeString = decodedJWT.qrCode, !qrCodeString.isEmpty else {
      throw PrimerError.invalidValue(
        key: "qrCode",
        value: nil,
        reason: "JWT missing qrCode field"
      )
    }

    let qrCodeImage = try await convertQRCodeToImage(qrCodeString)

    return QRCodePaymentData(
      qrCodeImage: qrCodeImage,
      statusUrl: statusUrl,
      paymentId: paymentId
    )
  }

  func pollForCompletion(statusUrl: URL) async throws -> String {
    let polling = PollingModule(url: statusUrl)
    pollingModule = polling
    defer { pollingModule = nil }
    return try await polling.start()
  }

  func resumePayment(
    paymentId: String,
    resumeToken: String,
    paymentMethodType: String
  ) async throws -> PaymentResult {
    let createPaymentService = CreateResumePaymentService(paymentMethodType: paymentMethodType)
    let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
    let paymentResponse = try await createPaymentService.resumePaymentWithPaymentId(
      paymentId, paymentResumeRequest: resumeRequest)

    return PaymentResult(
      paymentId: paymentResponse.id ?? paymentId,
      status: PaymentStatus(from: paymentResponse.status),
      amount: paymentResponse.amount,
      currencyCode: paymentResponse.currencyCode,
      paymentMethodType: paymentMethodType
    )
  }

  func cancelPolling(paymentMethodType: String) {
    pollingModule?.cancel(
      withError: PrimerError.cancelled(paymentMethodType: paymentMethodType))
    pollingModule = nil
  }

  // MARK: - Private Helpers

  private func findPaymentMethodConfig(for paymentMethodType: String) -> PrimerPaymentMethod? {
    PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?
      .first(where: { $0.type == paymentMethodType })
  }

  private func convertQRCodeToImage(_ qrCodeString: String) async throws -> UIImage {
    if qrCodeString.isHttpOrHttpsURL, let url = URL(string: qrCodeString) {
      return try await fetchImageFromURL(url)
    } else {
      return try decodeBase64Image(qrCodeString)
    }
  }

  private func fetchImageFromURL(_ url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
      throw PrimerError.invalidValue(
        key: "qrCodeUrl",
        value: url.absoluteString,
        reason: "Failed to create image from URL data"
      )
    }
    return image
  }

  private func decodeBase64Image(_ base64String: String) throws -> UIImage {
    guard let data = Data(base64Encoded: base64String),
      let image = UIImage(data: data)
    else {
      throw PrimerError.invalidValue(
        key: "qrCode",
        value: nil,
        reason: "Failed to decode Base64 QR code image"
      )
    }
    return image
  }
}
