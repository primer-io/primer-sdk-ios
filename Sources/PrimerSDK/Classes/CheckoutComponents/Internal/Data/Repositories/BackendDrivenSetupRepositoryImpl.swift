//
//  BackendDrivenSetupRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking
@_spi(PrimerInternal) import PrimerStepResolver

protocol PaymentMethodSetupAPI {
  func start(paymentMethodConfigId: String?, intent: PrimerSessionIntent) async throws -> PaymentMethodSetupResponse
  func poll(setupId: String) async throws -> PaymentMethodSetupResponse
}

protocol SetupScreenRunning {
  func run(_ screen: PaymentMethodSetupResponse.Screen, paymentMethodType: String) async throws
}

enum BackendDrivenSetupError: Error, Equatable {
  case missingScreen
  case missingToken
  /// The server waits on the shopper, but no screen is left for the shopper to act on.
  case suspended
  case timedOut
}

/// Drives the ADR's setup loop: run each published screen, poll after it, and end at `SETUP_COMPLETE`.
/// It lives here until the setup contract settles, then belongs in BDC core next to `:pay`.
@available(iOS 15.0, *)
@MainActor
final class BackendDrivenSetupRepositoryImpl: BackendDrivenSetupRepository {

  static let maxConsecutiveWaits = 120
  static let defaultPollDelayMilliseconds = 1000

  private let api: PaymentMethodSetupAPI
  private let screenRunner: SetupScreenRunning
  private let paymentMethodConfigId: (String) -> String?

  init(
    api: PaymentMethodSetupAPI = NetworkPaymentMethodSetupAPI(),
    screenRunner: SetupScreenRunning = BackendDrivenSetupScreenRunner(),
    paymentMethodConfigId: @escaping (String) -> String? = { type in
      PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first { $0.type == type }?.id
    }
  ) {
    self.api = api
    self.screenRunner = screenRunner
    self.paymentMethodConfigId = paymentMethodConfigId
  }

  func setUp(paymentMethodType: String, intent: PrimerSessionIntent) async throws -> String {
    var response = try await api.start(paymentMethodConfigId: paymentMethodConfigId(paymentMethodType), intent: intent)
    var consecutiveWaits = 0

    while true {
      try Task.checkCancellation()
      let instruction = response.instruction
      switch instruction.type {
      case .setupComplete:
        guard let token = instruction.paymentInstrumentToken?.token else { throw BackendDrivenSetupError.missingToken }
        return token
      case .execute:
        guard let screen = instruction.payload else { throw BackendDrivenSetupError.missingScreen }
        consecutiveWaits = 0
        // The steps return once the shopper finished the screen, so the next poll sees what they did.
        try await screenRunner.run(screen, paymentMethodType: paymentMethodType)
      case .wait:
        guard instruction.nextPoll == .interval else { throw BackendDrivenSetupError.suspended }
        consecutiveWaits += 1
        guard consecutiveWaits <= Self.maxConsecutiveWaits else { throw BackendDrivenSetupError.timedOut }
        let delay = instruction.pollDelayMilliseconds ?? Self.defaultPollDelayMilliseconds
        try await Task.sleep(nanoseconds: UInt64(max(0, delay)) * 1_000_000)
      }
      response = try await api.poll(setupId: response.paymentMethodSetupId)
    }
  }
}

struct NetworkPaymentMethodSetupAPI: PaymentMethodSetupAPI {
  func start(paymentMethodConfigId: String?, intent: PrimerSessionIntent) async throws -> PaymentMethodSetupResponse {
    let endpoint = PaymentMethodSetupEndpoint.start(
      paymentMethodConfigId: paymentMethodConfigId,
      intent: intent,
      idempotencyKey: UUID().uuidString
    )
    return try await defaultNetworkService.request(endpoint)
  }

  func poll(setupId: String) async throws -> PaymentMethodSetupResponse {
    try await defaultNetworkService.request(PaymentMethodSetupEndpoint.poll(setupId: setupId))
  }
}

/// Runs published screens through the BDC engine, the way the Drop-In backend-driven flow does.
@available(iOS 15.0, *)
@MainActor
final class BackendDrivenSetupScreenRunner: SetupScreenRunning {
  private var orchestrator: BackendDrivenCheckoutOrchestrator?

  nonisolated init() {}

  func run(_ screen: PaymentMethodSetupResponse.Screen, paymentMethodType: String) async throws {
    let orchestrator = try await orchestrator(for: paymentMethodType)
    let configuration = PrimerAPIConfigurationModule.apiConfiguration
    try await orchestrator.execute(
      schema: screen.schema,
      parameters: screen.parameters,
      pciUrl: configuration?.pciUrl,
      coreUrl: configuration?.coreUrl
    )
  }

  private func orchestrator(for paymentMethodType: String) async throws -> BackendDrivenCheckoutOrchestrator {
    if let orchestrator { return orchestrator }
    let provider = NetworkSignedManifestProvider(token: PrimerAPIConfigurationModule.decodedJWTToken)
    let engine = try await BDCEngineProvider.shared.engine(manifestProvider: provider)
    await PrimerStepResolverRegistry.shared.register(HTTPRequestResolver(), for: .httpRequest)
    let orchestrator = BackendDrivenCheckoutOrchestrator(
      engine: engine,
      context: .generate(payment: SDKPayment(paymentMethodType: paymentMethodType))
    )
    self.orchestrator = orchestrator
    return orchestrator
  }
}
