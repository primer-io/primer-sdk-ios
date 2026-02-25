//
//  CheckoutComponentsPaymentMethodsBridge.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Bridge to connect CheckoutComponents to the existing SDK payment methods
@available(iOS 15.0, *)
class CheckoutComponentsPaymentMethodsBridge: GetPaymentMethodsInteractor, LogReporter {

  private let configurationService: ConfigurationService

  init(configurationService: ConfigurationService) {
    self.configurationService = configurationService
  }

  func execute() async throws -> [InternalPaymentMethod] {
    logger.info(message: "🌉 [PaymentMethodsBridge] Starting payment methods bridge...")

    guard let configuration = configurationService.apiConfiguration else {
      logger.error(message: "❌ [PaymentMethodsBridge] No configuration available")
      throw PrimerError.missingPrimerConfiguration()
    }

    logger.info(message: "✅ [PaymentMethodsBridge] Configuration found")

    guard let paymentMethods = configuration.paymentMethods, !paymentMethods.isEmpty else {
      logger.error(message: "❌ [PaymentMethodsBridge] No payment methods in configuration")
      throw PrimerError.misconfiguredPaymentMethods()
    }

    logger.info(
      message:
        "📊 [PaymentMethodsBridge] Found \(paymentMethods.count) payment methods in configuration")

    // Filter payment methods based on CheckoutComponents support (only show implemented payment methods)
    let filteredMethods = await filterPaymentMethodsBySupport(paymentMethods)
    logger.info(
      message:
        "🔍 [PaymentMethodsBridge] Filtered to \(filteredMethods.count) payment methods based on CheckoutComponents support"
    )

    let convertedMethods = filteredMethods.map { primerMethod -> InternalPaymentMethod in
      let type = primerMethod.type

      logger.debug(message: "🔄 [PaymentMethodsBridge] Converting payment method: \(type)")

      // Extract network surcharges for card payment methods
      let networkSurcharges = extractNetworkSurcharges(for: type)

      let displayButton = primerMethod.displayMetadata?.button
      let backgroundColor = displayButton?.backgroundColor?.uiColor
      let textColor = displayButton?.textColor?.uiColor
      let borderColor = displayButton?.borderColor?.uiColor
      let borderWidth = displayButton?.borderWidth?.resolvedValue
      let cornerRadius = displayButton?.cornerRadius.map(CGFloat.init)
      let buttonText = displayButton?.text

      return InternalPaymentMethod(
        id: type,
        type: type,
        name: primerMethod.name,
        icon: primerMethod.logo,
        configId: primerMethod.processorConfigId,
        isEnabled: true,
        supportedCurrencies: nil,
        requiredInputElements: getRequiredInputElements(for: type),
        metadata: nil,
        surcharge: primerMethod.surcharge,
        hasUnknownSurcharge: primerMethod.hasUnknownSurcharge,
        networkSurcharges: networkSurcharges,
        backgroundColor: backgroundColor,
        buttonText: buttonText,
        textColor: textColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        cornerRadius: cornerRadius
      )
    }

    logger.info(
      message:
        "✅ [PaymentMethodsBridge] Successfully converted \(convertedMethods.count) payment methods")

    for (index, method) in convertedMethods.enumerated() {
      logger.debug(
        message: "💳 [PaymentMethodsBridge] Method \(index + 1): \(method.type) - \(method.name)")
    }

    return convertedMethods
  }

  // MARK: - Surcharge Extraction Methods

  private func extractNetworkSurcharges(for paymentMethodType: String) -> [String: Int]? {
    // Only card payment methods have network-specific surcharges
    guard paymentMethodType == PrimerPaymentMethodType.paymentCard.rawValue else {
      return nil
    }

    let session = configurationService.apiConfiguration?.clientSession
    guard let paymentMethodData = session?.paymentMethod else {
      return nil
    }

    guard let options = paymentMethodData.options else {
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

  private func extractFromNetworksArray(_ networksArray: [[String: Any]]) -> [String: Int]? {
    var networkSurcharges: [String: Int] = [:]

    for networkData in networksArray {
      guard let networkType = networkData["type"] as? String else {
        continue
      }

      // Handle nested surcharge structure: surcharge.amount
      if let surchargeData = networkData["surcharge"] as? [String: Any],
        let surchargeAmount = surchargeData["amount"] as? Int,
        surchargeAmount > 0
      {
        networkSurcharges[networkType] = surchargeAmount
      }
      // Fallback: handle direct surcharge integer format
      else if let surcharge = networkData["surcharge"] as? Int,
        surcharge > 0
      {
        networkSurcharges[networkType] = surcharge
      } else {
      }
    }

    return networkSurcharges.isEmpty ? nil : networkSurcharges
  }

  private func extractFromNetworksDict(_ networksDict: [String: [String: Any]]) -> [String: Int]? {
    var networkSurcharges: [String: Int] = [:]

    for (networkType, networkData) in networksDict {
      // Handle nested surcharge structure: surcharge.amount
      if let surchargeData = networkData["surcharge"] as? [String: Any],
        let surchargeAmount = surchargeData["amount"] as? Int,
        surchargeAmount > 0
      {
        networkSurcharges[networkType] = surchargeAmount
      }
      // Fallback: handle direct surcharge integer format
      else if let surcharge = networkData["surcharge"] as? Int,
        surcharge > 0
      {
        networkSurcharges[networkType] = surcharge
      } else {
      }
    }

    return networkSurcharges.isEmpty ? nil : networkSurcharges
  }

  private func getRequiredInputElements(for paymentMethodType: String) -> [PrimerInputElementType] {
    switch paymentMethodType {
    case PrimerPaymentMethodType.paymentCard.rawValue:
      return [.cardNumber, .cvv, .expiryDate, .cardholderName]
    default:
      return []
    }
  }

  private func filterPaymentMethodsBySupport(_ paymentMethods: [PrimerPaymentMethod]) async
    -> [PrimerPaymentMethod] {
      let registeredTypes = Set(await PaymentMethodRegistry.shared.registeredTypes)

      logger.debug(message: "🔍 [PaymentMethodsBridge] Registered payment method types: \(registeredTypes)")

      let filtered = paymentMethods.filter { method in
        let isRegistered = registeredTypes.contains(method.type)
        if !isRegistered {
          logger.debug(message: "🚫 [PaymentMethodsBridge] Filtering out unregistered payment method: \(method.type)")
        }
        return isRegistered
      }

      logger.debug(
        message:
          "🔍 [PaymentMethodsBridge] Filtered \(paymentMethods.count) payment methods to \(filtered.count) registered types"
      )

      return filtered
  }
}
