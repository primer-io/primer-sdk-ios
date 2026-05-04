//
//  NetworkSurchargeExtractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
enum NetworkSurchargeExtractor {

  static func extractNetworkSurcharges(
    for paymentMethodType: String,
    from configurationService: ConfigurationService
  ) -> [String: Int]? {
    guard paymentMethodType == PrimerPaymentMethodType.paymentCard.rawValue else {
      return nil
    }

    let session = configurationService.apiConfiguration?.clientSession
    guard let options = session?.paymentMethod?.options else {
      return nil
    }

    guard
      let paymentCardOption = options.first(where: { ($0["type"] as? String) == paymentMethodType })
    else {
      return nil
    }

    if let networksArray = paymentCardOption["networks"] as? [[String: Any]] {
      return extractFromNetworksArray(networksArray)
    } else if let networksDict = paymentCardOption["networks"] as? [String: [String: Any]] {
      return extractFromNetworksDict(networksDict)
    } else {
      return nil
    }
  }

  static func getRequiredInputElements(for paymentMethodType: String) -> [PrimerInputElementType] {
    switch paymentMethodType {
    case PrimerPaymentMethodType.paymentCard.rawValue:
      [.cardNumber, .cvv, .expiryDate, .cardholderName]
    default:
      []
    }
  }

  // MARK: - Private

  private static func extractFromNetworksArray(_ networksArray: [[String: Any]]) -> [String: Int]? {
    var networkSurcharges: [String: Int] = [:]

    for networkData in networksArray {
      guard let networkType = networkData["type"] as? String else {
        continue
      }

      if let surchargeData = networkData["surcharge"] as? [String: Any],
        let surchargeAmount = surchargeData["amount"] as? Int,
        surchargeAmount > 0 {
        networkSurcharges[networkType] = surchargeAmount
      } else if let surcharge = networkData["surcharge"] as? Int,
        surcharge > 0 {
        networkSurcharges[networkType] = surcharge
      }
    }

    return networkSurcharges.isEmpty ? nil : networkSurcharges
  }

  private static func extractFromNetworksDict(_ networksDict: [String: [String: Any]]) -> [String: Int]? {
    var networkSurcharges: [String: Int] = [:]

    for (networkType, networkData) in networksDict {
      if let surchargeData = networkData["surcharge"] as? [String: Any],
        let surchargeAmount = surchargeData["amount"] as? Int,
        surchargeAmount > 0 {
        networkSurcharges[networkType] = surchargeAmount
      } else if let surcharge = networkData["surcharge"] as? Int,
        surcharge > 0 {
        networkSurcharges[networkType] = surcharge
      }
    }

    return networkSurcharges.isEmpty ? nil : networkSurcharges
  }
}
