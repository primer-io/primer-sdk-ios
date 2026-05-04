//
//  RawDataManagerProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
protocol RawDataManagerProtocol: AnyObject {
  var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? { get set }
  var rawData: PrimerRawData? { get set }
  var isDataValid: Bool { get }
  var requiredInputElementTypes: [PrimerInputElementType] { get }
  func configure(completion: @escaping (PrimerInitializationData?, Error?) -> Void)
  func submit()
}

@available(iOS 15.0, *)
protocol RawDataManagerFactoryProtocol {
  func createRawDataManager(
    paymentMethodType: String,
    delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
  ) throws -> RawDataManagerProtocol
}

@available(iOS 15.0, *)
final class DefaultRawDataManagerFactory: RawDataManagerFactoryProtocol {
  func createRawDataManager(
    paymentMethodType: String,
    delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
  ) throws -> RawDataManagerProtocol {
    try PrimerHeadlessUniversalCheckout.RawDataManager(
      paymentMethodType: paymentMethodType,
      delegate: delegate
    )
  }
}

// MARK: - RawDataManager Conformance

@available(iOS 15.0, *)
extension PrimerHeadlessUniversalCheckout.RawDataManager: RawDataManagerProtocol {}
