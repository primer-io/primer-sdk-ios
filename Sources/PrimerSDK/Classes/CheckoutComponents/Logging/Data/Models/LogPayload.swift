//
//  LogPayload.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct LogPayload: Codable, Sendable {
  let message: String
  let hostname: String
  let service: String
  let ddsource: String
  let ddtags: String

  init(
    message: String,
    hostname: String,
    service: String = "ios-sdk",
    ddsource: String = "lambda",
    ddtags: String
  ) {
    self.message = message
    self.hostname = hostname
    self.service = service
    self.ddsource = ddsource
    self.ddtags = ddtags
  }
}

struct DeviceInfoMetadata: Codable, Sendable {
  let model: String
  let osVersion: String
  let locale: String
  let timezone: String
  let networkType: String
}

struct AppMetadata: Codable, Sendable {
  let appName: String
  let appVersion: String
  let appId: String
}

struct SessionMetadata: Codable, Sendable {
  let paymentIntent: String
  let availablePaymentMethods: [String]
  let integrationType: String?

  init(paymentIntent: String, availablePaymentMethods: [String], integrationType: String? = nil) {
    self.paymentIntent = paymentIntent
    self.availablePaymentMethods = availablePaymentMethods
    self.integrationType = integrationType
  }
}
