//
//  LoggingService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
actor LoggingService: LogReporter {

  // MARK: - Dependencies

  private let networkClient: any LogNetworkClientProtocol
  private let payloadBuilder: any LogPayloadBuilding
  private let masker: SensitiveDataMasker

  // MARK: - Initialization

  init(
    networkClient: any LogNetworkClientProtocol,
    payloadBuilder: any LogPayloadBuilding,
    masker: SensitiveDataMasker
  ) {
    self.networkClient = networkClient
    self.payloadBuilder = payloadBuilder
    self.masker = masker
  }

  // MARK: - Public Methods

  func logErrorIfReportable(_ error: Error, message: String? = nil, userInfo: [String: Any]? = nil)
    async
  {
    guard error.shouldReportToDatadog else {
      Self.logger.debug(message: "📊 [Logging] Skipping non-reportable error: \(error)")
      return
    }

    await sendError(message: message, error: error, userInfo: userInfo)
  }

  func logInfo(message: String, event: String, userInfo: [String: Any]? = nil) async {
    await sendInfo(message: message, event: event, userInfo: userInfo)
  }

  // MARK: - Private Methods

  private func sendInfo(message: String, event: String, userInfo: [String: Any]?) async {
    do {
      let sessionData = await LoggingSessionContext.shared.getSessionData()

      let payload = try payloadBuilder.buildInfoPayload(
        message: message,
        event: event,
        userInfo: userInfo,
        sessionData: sessionData
      )

      let endpoint = LogEnvironmentProvider.getEndpointURL(for: sessionData.environment)

      try await networkClient.send(
        payload: payload,
        to: endpoint,
        token: sessionData.clientSessionToken
      )
    } catch {
      Self.logger.error(
        message: "📊 [Logging] Failed to send INFO log: \(error.localizedDescription)")
    }
  }

  private func sendError(message: String?, error: Error, userInfo: [String: Any]?) async {
    do {
      let sessionData = await LoggingSessionContext.shared.getSessionData()

      let datadogMessage = message ?? Self.extractDatadogMessage(from: error)
      let errorMessage = error.localizedDescription
      let errorId = Self.extractErrorId(from: error)
      let diagnosticsId = Self.extractDiagnosticsId(from: error)
      let stack = String(describing: error)

      let maskedMessage = await masker.mask(text: datadogMessage)
      let maskedErrorMessage = await masker.mask(text: errorMessage)
      let maskedStack = await masker.mask(text: stack)

      let payload = try payloadBuilder.buildErrorPayload(
        message: maskedMessage,
        errorMessage: maskedErrorMessage,
        diagnosticsId: diagnosticsId,
        stack: maskedStack,
        event: errorId,
        userInfo: userInfo,
        sessionData: sessionData
      )

      let endpoint = LogEnvironmentProvider.getEndpointURL(for: sessionData.environment)

      try await networkClient.send(
        payload: payload,
        to: endpoint,
        token: sessionData.clientSessionToken
      )
    } catch {
      Self.logger.error(
        message: "📊 [Logging] Failed to send ERROR log: \(error.localizedDescription)")
    }
  }

  private static func extractDatadogMessage(from error: Error) -> String {
    guard let errorId = extractErrorId(from: error) else {
      return "Unknown error"
    }
    return
      errorId
      .replacingOccurrences(of: "-", with: " ")
      .capitalized
  }

  private static func extractErrorId(from error: Error) -> String? {
    (error as? PrimerError)?.errorId ?? (error as? InternalError)?.errorId
  }

  private static func extractDiagnosticsId(from error: Error) -> String? {
    (error as? PrimerError)?.diagnosticsId ?? (error as? InternalError)?.diagnosticsId
  }
}

// MARK: - Error Extension

@available(iOS 15.0, *)
extension Error {
  var shouldReportToDatadog: Bool {
    (self as? PrimerErrorProtocol)?.isReportable ?? true
  }
}
