//
//  AnalyticsPayloadBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

struct AnalyticsPayloadBuilder {

  func buildPayload(
    eventType: AnalyticsEventType,
    metadata: AnalyticsEventMetadata?,
    config: AnalyticsSessionConfig,
    timestamp: Int? = nil
  ) -> AnalyticsPayload {
    AnalyticsPayload(
      id: .uuid,
      timestamp: timestamp ?? Int(Date().timeIntervalSince1970),
      sdkType: NSClassFromString("RCTBridge") != nil ? "RN_IOS" : "IOS_NATIVE",
      eventName: eventType.rawValue,
      checkoutSessionId: config.checkoutSessionId,
      clientSessionId: config.clientSessionId,
      primerAccountId: config.primerAccountId,
      sdkVersion: config.sdkVersion,
      userAgent: UIDevice.userAgent,
      eventType: nil,
      userLocale: metadata?.locale ?? GeneralEvent.formattedCurrentLocale,
      paymentMethod: metadata?.paymentMethod,
      paymentId: metadata?.paymentId,
      redirectDestinationUrl: metadata?.redirectDestinationUrl,
      threedsProvider: metadata?.threedsProvider,
      threedsResponse: metadata?.threedsResponse,
      browser: nil,
      device: UIDevice.model.rawValue,
      deviceType: UIDevice.deviceType
    )
  }
}
