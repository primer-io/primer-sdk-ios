//
//  KlarnaRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
struct KlarnaSessionResult {
  let clientToken: String
  let sessionId: String
  let categories: [KlarnaPaymentCategory]
  let hppSessionId: String?
}

@available(iOS 15.0, *)
enum KlarnaAuthorizationResult: Equatable {
  case approved(authToken: String)
  case finalizationRequired(authToken: String)
  case declined
}

@available(iOS 15.0, *)
@MainActor
protocol KlarnaRepository {
  func createSession() async throws -> KlarnaSessionResult
  func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView?
  func authorize() async throws -> KlarnaAuthorizationResult
  func finalize() async throws -> KlarnaAuthorizationResult
  func tokenize(authToken: String) async throws -> PaymentResult
}
