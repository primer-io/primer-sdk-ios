//
//  PrimerConfiguration.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length

import Foundation
import PrimerFoundation

// MARK: - Protocol

public protocol ConfigurationPaymentMethod: AnyObject, Codable {
    var id: String? { get }
    var type: String { get }
    var surcharge: Int? { get set }
    var hasUnknownSurcharge: Bool { get set }
}

// MARK: - Response.Body.Configuration

extension Response.Body {

    public struct Configuration<PM: ConfigurationPaymentMethod>: Codable {

        public let coreUrl: String?
        public let pciUrl: String?
        public let binDataUrl: String?
        public let assetsUrl: String?
        public var clientSession: ClientSession.APIResponse?
        public let paymentMethods: [PM]?
        public let primerAccountId: String?
        public let keys: ThreeDS.Keys?
        public var checkoutModules: [CheckoutModule]?

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.coreUrl = (try? container.decode(String?.self, forKey: .coreUrl)) ?? nil
            self.pciUrl = (try? container.decode(String?.self, forKey: .pciUrl)) ?? nil
            self.binDataUrl = (try? container.decode(String?.self, forKey: .binDataUrl)) ?? nil
            self.assetsUrl = (try? container.decode(String?.self, forKey: .assetsUrl)) ?? nil
            self.clientSession = (try? container.decode(ClientSession.APIResponse?.self, forKey: .clientSession)) ?? nil
            let throwables = try container.decode([Throwable<PM>].self, forKey: .paymentMethods)
            self.paymentMethods = throwables.compactMap(\.value)
            self.primerAccountId = (try? container.decode(String?.self, forKey: .primerAccountId)) ?? nil
            self.keys = (try? container.decode(ThreeDS.Keys?.self, forKey: .keys)) ?? nil
            let moduleThrowables = try container.decode([Throwable<CheckoutModule>].self, forKey: .checkoutModules)
            self.checkoutModules = moduleThrowables.compactMap(\.value)

            var hasCardSurcharge = false
            var paymentMethodSurcharges: [String: Int] = [:]
            if let options = clientSession?.paymentMethod?.options, !options.isEmpty {
                for paymentMethodOption in options {
                    if let type = paymentMethodOption["type"] as? String {
                        if type == PrimerPaymentMethodType.paymentCard.rawValue,
                           let networks = paymentMethodOption["networks"] as? [[String: Any]],
                           !networks.isEmpty {
                            for network in networks {
                                guard network["type"] is String,
                                      network["surcharge"] is Int,
                                    let surchargeValue = network["surcharge"] as? Int
                                else { continue }
                                hasCardSurcharge = surchargeValue > 0
                            }
                        } else {
                            if let surcharge = paymentMethodOption["surcharge"] as? Int {
                                paymentMethodSurcharges[type] = surcharge
                            }
                        }
                    }
                }

                if let paymentMethod = self.paymentMethods?.filter({ $0.type == PrimerPaymentMethodType.paymentCard.rawValue }).first {
                    paymentMethod.hasUnknownSurcharge = hasCardSurcharge
                    paymentMethod.surcharge = nil
                }

                // Process other payment method surcharges
                for (paymentMethodType, surchargeValue) in paymentMethodSurcharges {
                    if let paymentMethod = self.paymentMethods?.first(where: { $0.type == paymentMethodType }) {
                        paymentMethod.surcharge = surchargeValue
                    }
                }
            }
        }

        public init(
            coreUrl: String?,
            pciUrl: String?,
            binDataUrl: String?,
            assetsUrl: String?,
            clientSession: ClientSession.APIResponse?,
            paymentMethods: [PM]?,
            primerAccountId: String?,
            keys: ThreeDS.Keys?,
            checkoutModules: [CheckoutModule]?
        ) {
            self.coreUrl = coreUrl
            self.pciUrl = pciUrl
            self.binDataUrl = binDataUrl
            self.assetsUrl = assetsUrl
            self.clientSession = clientSession
            self.paymentMethods = paymentMethods
            self.primerAccountId = primerAccountId
            self.keys = keys
            self.checkoutModules = checkoutModules
        }

        public func getConfigId(for type: String) -> String? {
            guard let method = self.paymentMethods?.filter({ $0.type == type }).first else { return nil }
            return method.id
        }
    }
}

// MARK: - Request.URLParameters.Configuration

extension Request.URLParameters {

    public final class Configuration: Codable {

        public let skipPaymentMethodTypes: [String]?
        public let requestDisplayMetadata: Bool?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case skipPaymentMethodTypes = "skipPaymentMethods"
            case requestDisplayMetadata = "withDisplayMetadata"
        }

        public init(skipPaymentMethodTypes: [String]?, requestDisplayMetadata: Bool?) {
            self.skipPaymentMethodTypes = skipPaymentMethodTypes
            self.requestDisplayMetadata = requestDisplayMetadata
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.skipPaymentMethodTypes = (try? container.decode([String]?.self, forKey: .skipPaymentMethodTypes)) ?? nil
            self.requestDisplayMetadata = (try? container.decode(Bool?.self, forKey: .requestDisplayMetadata)) ?? nil

            if skipPaymentMethodTypes == nil, requestDisplayMetadata == nil {
                throw InternalError.failedToDecode(message: "All values are nil")
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            if skipPaymentMethodTypes == nil, requestDisplayMetadata == nil {
                throw InternalError.failedToDecode(message: "All values are nil")
            }

            if let skipPaymentMethodTypes = skipPaymentMethodTypes {
                try container.encode(skipPaymentMethodTypes, forKey: .skipPaymentMethodTypes)
            }

            if let requestDisplayMetadata = requestDisplayMetadata {
                try container.encode(requestDisplayMetadata, forKey: .requestDisplayMetadata)
            }
        }

        public func toDictionary() -> [String: String]? {
            var dict: [String: String] = [:]

            if let skipPaymentMethodTypes = skipPaymentMethodTypes, !skipPaymentMethodTypes.isEmpty {
                dict[CodingKeys.skipPaymentMethodTypes.rawValue] = skipPaymentMethodTypes.joined(separator: ",")

                if let requestDisplayMetadata = requestDisplayMetadata {
                    dict[CodingKeys.requestDisplayMetadata.rawValue] = requestDisplayMetadata ? "true" : "false"
                }
            } else {
                if let requestDisplayMetadata = requestDisplayMetadata {
                    dict[CodingKeys.requestDisplayMetadata.rawValue] = requestDisplayMetadata ? "true" : "false"
                }
            }

            return dict.keys.isEmpty ? nil : dict
        }
    }
}

// swiftlint:enable file_length
