//
//  PrimerConfiguration.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length

import Foundation
import PassKit
import PrimerCore
import PrimerFoundation
import PrimerNetworking

typealias PrimerAPIConfiguration = Response.Body.Configuration<PrimerPaymentMethod>

// MARK: - ConfigurationPaymentMethod conformance

extension PrimerPaymentMethod: ConfigurationPaymentMethod {}

// MARK: - SDK behaviour

extension Response.Body.Configuration: @retroactive LogReporter where PM == PrimerPaymentMethod {

    static var current: PrimerAPIConfiguration? {
        PrimerAPIConfigurationModule.apiConfiguration
    }

    static var paymentMethodConfigs: [PrimerPaymentMethod]? {
        PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods
    }

    var hasSurchargeEnabled: Bool {
        let pmSurcharge = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.paymentMethod?.options?
            .first(where: { $0["surcharge"] as? Int != nil })

        let options = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.paymentMethod?.options
        let cardSurcharge = options?
            .first(where: {
                (
                    ($0["networks"] as? [[String: Any]])?
                    .first(where: {
                        $0["surcharge"] as? Int != nil
                    })
                ) != nil
            })
        return pmSurcharge != nil || cardSurcharge != nil
    }

    static var paymentMethodConfigViewModels: [PaymentMethodTokenizationViewModelProtocol] {
        var viewModels: [PaymentMethodTokenizationViewModelProtocol] = PrimerAPIConfiguration.paymentMethodConfigs?
            .filter(\.isEnabled)
            .filter({ $0.baseLogoImage != nil })
            .compactMap(\.tokenizationViewModel)
            ?? []

        if !ApplePayUtils.canMakeApplePayPayments() {
            if let applePayViewModel = viewModels.filter({ $0.config.type == PrimerPaymentMethodType.applePay.rawValue }).first,
               let applePayViewModelIndex = viewModels.firstIndex(where: { $0 == applePayViewModel }) {
                viewModels.remove(at: applePayViewModelIndex)
            }
        }

        #if !canImport(PrimerKlarnaSDK)
        if let klarnaViewModelIndex = viewModels.firstIndex(where: { $0.config.type == PrimerPaymentMethodType.klarna.rawValue }) {
            viewModels.remove(at: klarnaViewModelIndex)
            let message =
                """
Klarna configuration has been found but module 'PrimerKlarnaSDK' is missing. \
Add `PrimerKlarnaSDK' in your project by adding \"pod 'PrimerKlarnaSDK'\" in your Podfile, \
or by adding \"primer-klarna-sdk-ios\" in your Swift Package Manager.
"""
            logger.warn(message: message)

            let event = Analytics.Event.message(
                message: "PrimerKlarnaSDK has not been integrated",
                messageType: .error,
                severity: .error
            )
            Analytics.Service.fire(events: [event])
        }
        #endif

        #if !canImport(PrimerIPay88MYSDK)
        if let iPay88ViewModelIndex = viewModels.firstIndex(where: { $0.config.type == PrimerPaymentMethodType.iPay88Card.rawValue }) {
            viewModels.remove(at: iPay88ViewModelIndex)
            let message =
                """
iPay88 configuration has been found but module 'PrimerIPay88SDK' is missing. \
Add `PrimerIPay88SDK' in your project by adding \"pod 'PrimerIPay88SDK'\" in your Podfile.
"""
            logger.warn(message: message)

            let event = Analytics.Event.message(
                message: "PrimerIPay88MYSDK has not been integrated",
                messageType: .error,
                severity: .error
            )
            Analytics.Service.fire(events: [event])
        }
        #endif

        var validViewModels: [PaymentMethodTokenizationViewModelProtocol] = []

        for viewModel in viewModels {
            do {
                try viewModel.validate()
                validViewModels.append(viewModel)
            } catch {
                var warningStr = "\(viewModel.config.type) configuration has been found, but it cannot be presented."

                if let primerErr = error as? PrimerError {
                    if case let .underlyingErrors(errors, _) = primerErr {
                        for err in errors {
                            if let primerErr = err as? PrimerError {
                                var errLine: String = ""
                                if let errDescription = primerErr.plainDescription {
                                    errLine += "\n-\(errDescription)"
                                }

                                if let recoverySuggestion = primerErr.recoverySuggestion {
                                    if !errLine.isEmpty {
                                        errLine += " | "
                                    } else {
                                        errLine += "\n-"
                                    }

                                    errLine += recoverySuggestion
                                }
                                warningStr += errLine

                            } else {
                                warningStr += "\n-\(error.localizedDescription)"
                            }
                        }
                    } else {
                        var errLine: String = ""
                        if let errDescription = primerErr.plainDescription {
                            errLine += "\n-\(errDescription)"
                        }

                        if let recoverySuggestion = primerErr.recoverySuggestion {
                            if !errLine.isEmpty {
                                errLine += " | "
                            } else {
                                errLine += "\n-"
                            }

                            errLine += recoverySuggestion
                        }
                        warningStr += errLine
                    }

                } else {
                    warningStr += "\n-\(error.localizedDescription)"
                }

                logger.warn(message: warningStr)
            }
        }

        for (index, viewModel) in validViewModels.enumerated() where viewModel.config.type == PrimerPaymentMethodType.applePay.rawValue {
            validViewModels.swapAt(0, index)
        }

        for (index, viewModel) in validViewModels.enumerated() {
            viewModel.position = index
        }

        return validViewModels
    }
}
// swiftlint:enable file_length
