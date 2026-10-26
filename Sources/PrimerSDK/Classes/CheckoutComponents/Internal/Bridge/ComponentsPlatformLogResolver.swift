//
//  ComponentsPlatformLogResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

@available(iOS 15.0, *)
struct ComponentsPlatformLogResolver: StepResolver {
  let loggingService: any ComponentsLoggingServiceProtocol

  func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
    if let log = try? data.casted(to: PlatformLog.self).properties, !log.message.isEmpty {
      await send(log)
    }
    return StepResolutionResult(outcome: .success)
  }

  private func send(_ log: PlatformLog.Properties) async {
    switch log.status {
    case .error:
      await loggingService.logError(
        message: log.message, event: log.event, errorMessage: nil, stack: nil, userInfo: log.userInfo)
    case .warn:
      await loggingService.logWarning(message: log.message, event: log.event, userInfo: log.userInfo)
    case .info:
      await loggingService.logInfo(message: log.message, event: log.event, userInfo: log.userInfo)
    }
  }
}

@available(iOS 15.0, *)
private extension ComponentsPlatformLogResolver {
  struct PlatformLog: Decodable {
    let properties: Properties

    struct Properties: Decodable {
      let message: String
      let messageType: String?
      let severity: String?
      let context: CodableValue?

      var event: String { messageType ?? "platform_log" }
      var status: DatadogLogStatus { severity.flatMap { DatadogLogStatus(rawValue: $0.lowercased()) } ?? .info }
      var userInfo: [String: Any]? { metadata.map { ["metadata": $0] } }

      private var metadata: [String: Any]? {
        guard let context, let json = try? JSONEncoder().encode(context) else { return nil }
        return try? JSONSerialization.jsonObject(with: json) as? [String: Any]
      }
    }
  }
}
