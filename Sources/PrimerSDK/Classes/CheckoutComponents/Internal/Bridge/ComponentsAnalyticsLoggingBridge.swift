//
//  ComponentsAnalyticsLoggingBridge.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public final class ComponentsAnalyticsLoggingBridge {

  private let analyticsService: CheckoutComponentsAnalyticsServiceProtocol
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol
  private let loggingService: any ComponentsLoggingServiceProtocol
  private let configurationModule: AnalyticsSessionConfigProviding

  public init() {
    let analyticsService = AnalyticsEventService.create(
      environmentProvider: AnalyticsEnvironmentProvider()
    )
    self.analyticsService = analyticsService
    analyticsInteractor = DefaultAnalyticsInteractor(eventService: analyticsService)
    loggingService = LoggingService(
      networkClient: LogNetworkClient(),
      payloadBuilder: LogPayloadBuilder()
    )
    configurationModule = PrimerAPIConfigurationModule()
  }

  init(
    analyticsService: CheckoutComponentsAnalyticsServiceProtocol,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol,
    loggingService: any ComponentsLoggingServiceProtocol,
    configurationModule: AnalyticsSessionConfigProviding
  ) {
    self.analyticsService = analyticsService
    self.analyticsInteractor = analyticsInteractor
    self.loggingService = loggingService
    self.configurationModule = configurationModule
  }

  // MARK: - Setup

  public func setup(clientToken: String) async {
    await LoggingSessionContext.shared.initialize(
      clientToken: clientToken,
      integrationType: .reactNative
    )

    guard let config = configurationModule.makeAnalyticsSessionConfig(
      checkoutSessionId: PrimerInternal.shared.checkoutSessionId ?? UUID().uuidString,
      clientToken: clientToken,
      sdkVersion: VersionUtils.releaseVersionNumber ?? "unknown"
    ) else {
      return
    }

    await analyticsService.initialize(config: config)
  }

  // MARK: - Analytics

  public func trackEvent(_ eventName: String, metadata: [String: String]?) async {
    guard let eventType = AnalyticsEventType(rawValue: eventName) else { return }
    await analyticsInteractor.trackEvent(eventType, metadata: Self.mapMetadata(metadata))
  }

  // MARK: - Logging

  public func logInfo(message: String, event: String, userInfo: [String: Any]? = nil) async {
    await loggingService.logInfo(message: message, event: event, userInfo: userInfo)
  }

  // MARK: - Metadata Mapping

  static func mapMetadata(_ metadata: [String: String]?) -> AnalyticsEventMetadata {
    guard let metadata, !metadata.isEmpty else { return .general() }
    guard let paymentMethod = metadata["paymentMethod"] else { return .general() }

    if let provider = metadata["threedsProvider"] {
      return .threeDS(ThreeDSEvent(paymentMethod: paymentMethod, provider: provider))
    }

    if let url = metadata["redirectDestinationUrl"] {
      return .redirect(RedirectEvent(paymentMethod: paymentMethod, destinationUrl: url))
    }

    return .payment(PaymentEvent(paymentMethod: paymentMethod, paymentId: metadata["paymentId"]))
  }
}
