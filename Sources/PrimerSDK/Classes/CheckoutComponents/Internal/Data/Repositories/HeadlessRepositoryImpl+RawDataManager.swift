//
//  HeadlessRepositoryImpl+RawDataManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension HeadlessRepositoryImpl: @preconcurrency PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

  func primerRawDataManager(
    _ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
    dataIsValid isValid: Bool,
    errors: [Error]?
  ) {}

  func primerRawDataManager(
    _ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
    metadataDidChange metadata: [String: Any]?
  ) {}

  func primerRawDataManager(
    _ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
    willFetchMetadataForState cardState: PrimerValidationState
  ) {}

  func primerRawDataManager(
    _ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
    didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
    forState cardState: PrimerValidationState
  ) {
    guard let metadataModel = metadata as? PrimerCardNumberEntryMetadata,
      cardState is PrimerCardNumberEntryState
    else {
      return
    }

    // Extract networks following traditional SDK pattern
    let primerNetworks: [PrimerCardNetwork] = if metadataModel.source == .remote,
      let selectable = metadataModel.selectableCardNetworks?.items,
      !selectable.isEmpty {
      selectable
    } else if let preferred = metadataModel.detectedCardNetworks.preferred {
      [preferred]
    } else if let first = metadataModel.detectedCardNetworks.items.first {
      [first]
    } else {
      []
    }

    let filteredNetworks = primerNetworks.filter { $0.displayName != "Unknown" }

    // Convert PrimerCardNetwork to CardNetwork
    let cardNetworks = filteredNetworks.compactMap { CardNetwork(rawValue: $0.network.rawValue) }

    // Only emit if networks changed to avoid duplicate notifications
    if cardNetworks != lastDetectedNetworks {
      lastDetectedNetworks = cardNetworks

      // Emit networks via AsyncStream for SwiftUI consumption
      networkDetectionContinuation.yield(cardNetworks)
    }
  }

  func primerRawDataManager(
    _ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
    didReceiveBinData binData: PrimerBinData
  ) {
    binDataContinuation.yield(binData)
  }
}
