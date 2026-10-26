//
//  AnalyticsPayloadBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import UIKit

struct AnalyticsPayloadBuilder {

  private static let isReactNative = NSClassFromString("RCTBridge") != nil

  func buildPayload(
    eventType: AnalyticsEventType,
    metadata: AnalyticsEventMetadata?,
    config: AnalyticsSessionConfig,
    timestamp: Int? = nil,
    envelope: AnalyticsFunnelState.Envelope? = nil,
    integrationSurface: String? = nil
  ) -> AnalyticsPayload {
    buildPayload(
      eventName: eventType.rawValue,
      metadata: metadata,
      config: config,
      timestamp: timestamp,
      envelope: envelope,
      integrationSurface: integrationSurface
    )
  }

  func buildPayload(
    eventName: String,
    metadata: AnalyticsEventMetadata?,
    config: AnalyticsSessionConfig,
    timestamp: Int? = nil,
    envelope: AnalyticsFunnelState.Envelope? = nil,
    integrationSurface: String? = nil
  ) -> AnalyticsPayload {
    let vault = metadata?.vaultEvent
    let payment = metadata?.paymentEvent
    return AnalyticsPayload(
      id: .uuid,
      timestamp: timestamp ?? Int(Date().timeIntervalSince1970),
      sdkType: Self.isReactNative ? "RN_IOS" : "IOS_NATIVE",
      eventName: eventName,
      checkoutSessionId: config.checkoutSessionId,
      clientSessionId: config.clientSessionId,
      primerAccountId: config.primerAccountId,
      sdkVersion: config.sdkVersion,
      userAgent: UIDevice.userAgent,
      eventType: nil,
      userLocale: metadata?.locale ?? GeneralEvent.formattedCurrentLocale,
      paymentMethod: metadata?.paymentMethod ?? envelope?.paymentMethod,
      paymentId: metadata?.paymentId ?? envelope?.paymentId,
      redirectDestinationUrl: metadata?.redirectDestinationUrl,
      threedsProvider: metadata?.threedsProvider,
      threedsResponse: metadata?.threedsResponse,
      browser: nil,
      device: UIDevice.model.rawValue,
      deviceType: UIDevice.deviceType,
      vaultedMethodId: vault?.vaultedMethodId,
      previousVaultedMethodId: vault?.previousVaultedMethodId,
      promotedVaultedMethodId: vault?.promotedVaultedMethodId,
      isActive: vault?.isActive,
      vaultedMethodCount: vault?.vaultedMethodCount,
      exitedFromConfirmation: vault?.exitedFromConfirmation,
      network: vault?.network,
      expectedCvvLength: vault?.expectedCvvLength,
      errorId: vault?.errorId,
      contractVersion: AnalyticsContract.version,
      attemptId: envelope?.attemptId,
      integrationSurface: integrationSurface,
      reason: payment?.reason,
      errorCode: payment?.errorCode,
      errorOrigin: payment?.errorOrigin,
      outcome: payment?.outcome,
      previousPaymentMethod: payment?.previousPaymentMethod,
      lastStep: envelope?.lastStep,
      availablePaymentMethods: metadata?.availablePaymentMethods,
      protocolVersion: metadata?.threedsProtocolVersion,
      authenticationOutcome: envelope?.threeDSOutcome?.authenticationOutcome,
      skippedReasonCode: envelope?.threeDSOutcome?.skippedReasonCode
    )
  }
}
