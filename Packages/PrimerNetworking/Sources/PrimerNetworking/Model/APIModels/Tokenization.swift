//
//  Tokenization.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

extension Response.Body {

    public final class Tokenization: NSObject, Codable {

        public var analyticsId: String?
        public var id: String?
        public var isVaulted: Bool?
        public var paymentMethodType: String?
        public var paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData?
        public var paymentInstrumentType: PaymentInstrumentType
        public var threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
        public var token: String?
        public var tokenType: TokenType?
        public var vaultData: Response.Body.Tokenization.VaultData?

        init(
            analyticsId: String?,
            id: String?,
            isVaulted: Bool?,
            isAlreadyVaulted: Bool?,
            paymentInstrumentType: PaymentInstrumentType,
            paymentMethodType: String?,
            paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData?,
            threeDSecureAuthentication: ThreeDS.AuthenticationDetails?,
            token: String?,
            tokenType: TokenType?,
            vaultData: Response.Body.Tokenization.VaultData?
        ) {
            self.analyticsId = analyticsId
            self.id = id
            self.isVaulted = isVaulted
            self.paymentMethodType = paymentMethodType
            self.paymentInstrumentType = paymentInstrumentType
            self.paymentInstrumentData = paymentInstrumentData
            self.threeDSecureAuthentication = threeDSecureAuthentication
            self.token = token
            self.tokenType = tokenType
            self.vaultData = vaultData
        }
    }
}

extension Response.Body.Tokenization {

    public struct PaymentInstrumentData: Codable {

        public let paypalBillingAgreementId: String?
        public let first6Digits: String?
        public let last4Digits: String?
        public let expirationMonth: String?
        public let expirationYear: String?
        public let cardholderName: String?
        public let network: String?
        public let isNetworkTokenized: Bool?
        public let klarnaCustomerToken: String?
        public let sessionData: Response.Body.Klarna.SessionData?
        public let externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?
        public let shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress?
        public let binData: BinData?
        public let threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
        public let gocardlessMandateId: String?
        public let authorizationToken: String?

        // swiftlint:disable:next identifier_name
        public let mx: String?
        public let currencyCode: Currency?
        public let productId: String?

        public let paymentMethodConfigId: String?
        public let paymentMethodType: String?
        public let sessionInfo: SessionInfo?

        public let bankName: String?
        public let accountNumberLast4Digits: String?

        public let applePayMerchantTokenIdentifier: String?

        // swiftlint:disable:next nesting
        public struct SessionInfo: Codable {
            public let locale: String?
            public let platform: String?
            public let redirectionUrl: String?
        }

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case paypalBillingAgreementId
            case first6Digits
            case last4Digits
            case expirationMonth
            case expirationYear
            case cardholderName
            case network
            case isNetworkTokenized
            case klarnaCustomerToken
            case sessionData
            case externalPayerInfo
            case shippingAddress
            case binData
            case threeDSecureAuthentication
            case gocardlessMandateId
            case authorizationToken
            // swiftlint:disable:next identifier_name
            case mx
            case currencyCode
            case productId
            case paymentMethodConfigId
            case paymentMethodType
            case sessionInfo
            case bankName
            case accountNumberLast4Digits = "accountNumberLastFourDigits"
            case applePayMerchantTokenIdentifier
        }
    }
}

extension Response.Body.Tokenization {

    public struct VaultData: Codable {
        public var customerId: String
    }
}

extension Response.Body.Tokenization {

    public final class PayPal {

        // swiftlint:disable:next nesting
        public struct ShippingAddress: Codable {
            let firstName, lastName, addressLine1, addressLine2, city, state, countryCode, postalCode: String?
        }

        // swiftlint:disable:next nesting
        public struct ExternalPayerInfo: Codable {
            public var externalPayerId, externalPayerIdSnakeCase,
                       email,
                       firstName, firstNameSnakeCase,
                       lastName, lastNameSnakeCase: String?

            public init(
                externalPayerId: String,
                externalPayerIdSnakeCase: String? = nil,
                email: String,
                firstName: String?,
                firstNameSnakeCase: String? = nil,
                lastName: String,
                lastNameSnakeCase: String? = nil
            ) {
                self.externalPayerId = externalPayerId
                self.externalPayerIdSnakeCase = externalPayerIdSnakeCase ?? externalPayerId
                self.email = email
                self.firstName = firstName
                self.firstNameSnakeCase = firstNameSnakeCase ?? firstName
                self.lastName = lastName
                self.lastNameSnakeCase = lastNameSnakeCase ?? lastName
            }

            public init(from decoder: Decoder) throws {
                let container: KeyedDecodingContainer<Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys> =
                    try decoder.container(keyedBy: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.self)

                self.externalPayerId = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.externalPayerId
                )

                self.externalPayerIdSnakeCase = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.externalPayerIdSnakeCase
                )

                self.email = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.email
                )

                self.firstName = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.firstName
                )

                self.firstNameSnakeCase = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.firstNameSnakeCase
                )

                self.lastName = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.lastName
                )

                self.lastNameSnakeCase = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.lastNameSnakeCase
                )

                // This logic ensures we mirror externalPayerId to external_payer_id and vice versa
                if self.externalPayerId == nil, self.externalPayerIdSnakeCase != nil {
                    self.externalPayerId = self.externalPayerIdSnakeCase
                } else if self.externalPayerIdSnakeCase == nil, self.externalPayerId != nil {
                    self.externalPayerIdSnakeCase = self.externalPayerId
                }

                if firstName == nil, firstNameSnakeCase != nil {
                    firstName = firstNameSnakeCase
                } else if firstNameSnakeCase == nil, firstName != nil {
                    firstNameSnakeCase = firstName
                }

                if lastName == nil, lastNameSnakeCase != nil {
                    lastName = lastNameSnakeCase
                } else if lastNameSnakeCase == nil, lastName != nil {
                    lastNameSnakeCase = lastName
                }
            }

            // swiftlint:disable:next nesting
            enum CodingKeys: String, CodingKey {
                case externalPayerId
                case externalPayerIdSnakeCase = "external_payer_id"
                case firstNameSnakeCase = "first_name"
                case lastNameSnakeCase = "last_name"
                case email, firstName, lastName
            }
        }
    }
}
