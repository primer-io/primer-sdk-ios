//
//  BackendDrivenSetupRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@available(iOS 15.0, *)
protocol BackendDrivenSetupRepository {
  /// Runs a backend-driven payment method setup to its end and returns the payment instrument token.
  func setUp(paymentMethodType: String, intent: PrimerSessionIntent) async throws -> String
}
