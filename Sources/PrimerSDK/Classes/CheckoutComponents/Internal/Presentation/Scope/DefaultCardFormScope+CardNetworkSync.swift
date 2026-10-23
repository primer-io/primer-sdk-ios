//
//  DefaultCardFormScope+CardNetworkSync.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

@available(iOS 15.0, *)
extension DefaultCardFormScope {
  var isCardNetworkConfirmed: Bool {
    guard let binData = structuredState.binData,
      let digits = binData.status == .complete ? binData.firstDigits : binData.fallbackDigits
    else { return false }
    return structuredState.data[.cardNumber].replacingOccurrences(of: " ", with: "").hasPrefix(digits)
  }

  func updateSurchargeAmount(for network: CardNetwork?) {
    guard let network else {
      structuredState.surchargeAmountRaw = nil
      structuredState.surchargeAmount = nil
      return
    }

    guard isCardNetworkConfirmed, let surcharge = network.surcharge,
      configurationService.apiConfiguration?.clientSession?.order?.merchantAmount == nil,
      let currency = configurationService.currency
    else {
      structuredState.surchargeAmountRaw = nil
      structuredState.surchargeAmount = nil
      return
    }

    let formattedSurcharge =
      "+ \(surcharge.toCurrencyString(currency: currency, locale: configurationService.locale))"
    structuredState.surchargeAmountRaw = surcharge
    structuredState.surchargeAmount = formattedSurcharge
  }

  func observeCardNetworkSync(_ interactor: CardNetworkDetectionInteractor) -> Task<Void, Never> {
    Task { [weak self] in
      for await isSyncing in interactor.cardNetworkSyncStream {
        guard let self else { return }
        structuredState.isUpdatingClientSession = isSyncing
      }
    }
  }
}
