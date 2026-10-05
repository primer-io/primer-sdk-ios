//
//  PaymentMethodSetupEndpoint.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

/// The merchant-api payment method setup routes from the Partners ADR "Payment method setups on
/// backend-driven checkout". The ADR is still in review and no backend serves these routes yet.
enum PaymentMethodSetupEndpoint {
  case start(paymentMethodConfigId: String?, intent: PrimerSessionIntent, idempotencyKey: String)
  case poll(setupId: String)
}

extension PaymentMethodSetupEndpoint: Endpoint {
  var baseURL: String? { PrimerAPIConfigurationModule.apiConfiguration?.pciUrl }

  var path: String {
    let setups = "client-session/\(clientSessionId)/payment-method-setups"
    return switch self {
    case .start: setups
    case let .poll(setupId): "\(setups)/\(setupId)"
    }
  }

  var method: HTTPMethod {
    switch self {
    case .start: .post
    case .poll: .get
    }
  }

  var headers: [String: String]? {
    switch self {
    case let .start(_, _, idempotencyKey): PrimerRuntimeHeaders.default.merging(["X-Idempotency-Key": idempotencyKey]) { $1 }
    case .poll: PrimerRuntimeHeaders.default
    }
  }

  var queryParameters: [String: String]? { nil }

  var body: Data? {
    switch self {
    case let .start(paymentMethodConfigId, intent, _):
      try? JSONEncoder().encode(PaymentMethodSetupStartBody(paymentMethodConfigId: paymentMethodConfigId, flow: intent))
    case .poll:
      nil
    }
  }

  var timeout: TimeInterval? { 30 }

  private var clientSessionId: String {
    PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId ?? "unknown"
  }
}

/// `flow` encodes as `CHECKOUT` or `VAULT`.
struct PaymentMethodSetupStartBody: Encodable {
  let paymentMethodConfigId: String?
  let flow: PrimerSessionIntent
  var clientInfo = ClientInfo()

  struct ClientInfo: Encodable {
    var platform = "IOS"
    var locale = PrimerSettings.current.localeData.localeCode
    var returnUri = try? PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme()
  }
}
