//
//  LoggingSessionContext.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Integration Type

public enum CheckoutComponentsIntegrationType: String, Sendable {
  case swiftUI = "swiftui"
  case uiKit = "uikit"
}

// MARK: - Logging Session Context

public actor LoggingSessionContext {
  // MARK: - Constants

  private enum Constants {
    static let unknownIosApp = "unknown-ios-app"
    static let unknownValue = "unknown"
  }

  // MARK: - Singleton

  public static let shared = LoggingSessionContext()

  // MARK: - Session Properties

  private var environment: AnalyticsEnvironment
  private var sdkVersion: String
  private var clientSessionToken: String?
  private var sdkInitStartTime: CFAbsoluteTime?
  private var hostname: String
  private var integrationType: CheckoutComponentsIntegrationType?

  // Note: Session IDs are sourced dynamically from SDK state, not stored locally
  // - checkoutSessionId: PrimerInternal.shared.checkoutSessionId
  // - clientSessionId: PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId
  // - primerAccountId: Parsed from JWT token or PrimerAPIConfigurationModule.apiConfiguration?.primerAccountId

  // MARK: - Initialization

  private init() {
    environment = .production
    sdkVersion = ""
    clientSessionToken = nil
    sdkInitStartTime = nil
    hostname = Bundle.main.bundleIdentifier ?? Constants.unknownIosApp
    integrationType = nil
  }

  // MARK: - Public Methods

  public func initialize(clientToken: String, integrationType: CheckoutComponentsIntegrationType) {
    clientSessionToken = clientToken
    self.integrationType = integrationType

    // Parse JWT client token to extract environment
    let components = clientToken.components(separatedBy: ".")
    guard components.count == 3,
      let payloadData = Data(base64Encoded: components[1].base64PaddedString())
    else {
      // Invalid token format - use defaults
      environment = .production
      sdkVersion = VersionUtils.releaseVersionNumber ?? Constants.unknownValue
      return
    }

    do {
      let json = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any]

      // Parse environment - check both "env" and "environment" for compatibility
      if let envString = json?["env"] as? String {
        environment = AnalyticsEnvironment(rawValue: envString) ?? .production
      } else if let envString = json?["environment"] as? String {
        environment = AnalyticsEnvironment(rawValue: envString) ?? .production
      } else {
        environment = .production
      }

      sdkVersion = VersionUtils.releaseVersionNumber ?? Constants.unknownValue
    } catch {
      // JSON parsing failed - use defaults
      environment = .production
      sdkVersion = VersionUtils.releaseVersionNumber ?? Constants.unknownValue
    }
  }

  public func initialize(
    environment: AnalyticsEnvironment,
    sdkVersion: String,
    clientSessionToken: String?,
    integrationType: CheckoutComponentsIntegrationType? = nil
  ) {
    self.environment = environment
    self.sdkVersion = sdkVersion
    self.clientSessionToken = clientSessionToken
    self.integrationType = integrationType
  }

  public func recordInitStartTime() {
    sdkInitStartTime = CFAbsoluteTimeGetCurrent()
  }

  public func calculateInitDuration() -> Int? {
    guard let startTime = sdkInitStartTime else { return nil }
    let currentTime = CFAbsoluteTimeGetCurrent()
    return Int((currentTime - startTime) * 1000)
  }

  public func getSessionData() -> SessionData {
    SessionData(
      environment: environment,
      checkoutSessionId: PrimerInternal.shared.checkoutSessionId ?? "",
      clientSessionId: PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId
        ?? "",
      primerAccountId: parsePrimerAccountId() ?? "",
      sdkVersion: sdkVersion,
      clientSessionToken: clientSessionToken,
      hostname: hostname,
      integrationType: integrationType
    )
  }

  // MARK: - Internal Methods (for testing)

  func resetInitStartTime() {
    sdkInitStartTime = nil
  }

  // MARK: - Private Helpers

  private func parsePrimerAccountId() -> String? {
    // First try from API configuration
    if let configAccountId = PrimerAPIConfigurationModule.apiConfiguration?.primerAccountId,
      !configAccountId.isEmpty
    {
      return configAccountId
    }

    // Fallback to parsing from JWT token
    guard let token = clientSessionToken else { return nil }

    let components = token.components(separatedBy: ".")
    guard components.count == 3,
      let payloadData = Data(base64Encoded: components[1].base64PaddedString()),
      let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
    else {
      return nil
    }

    // Try both "primerAccountId" and "accountId" keys
    if let accountId = json["primerAccountId"] as? String, !accountId.isEmpty {
      return accountId
    }
    if let accountId = json["accountId"] as? String, !accountId.isEmpty {
      return accountId
    }

    return nil
  }

  // MARK: - Nested Types

  public struct SessionData: Sendable {
    public let environment: AnalyticsEnvironment
    public let checkoutSessionId: String
    public let clientSessionId: String
    public let primerAccountId: String
    public let sdkVersion: String
    public let clientSessionToken: String?
    public let hostname: String
    public let integrationType: CheckoutComponentsIntegrationType?
  }
}

// MARK: - String Extension for Base64 Padding

extension String {
  fileprivate func base64PaddedString() -> String {
    var base64 = replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")

    let paddingLength = (4 - base64.count % 4) % 4
    base64 += String(repeating: "=", count: paddingLength)
    return base64
  }
}
