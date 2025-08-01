//
//  TokenizationResponse.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

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

// Should be removed
extension Response.Body.Tokenization {

    public var icon: ImageName {
        switch self.paymentInstrumentType {
        case .paymentCard:
            guard let network = self.paymentInstrumentData?.network else { return .genericCard }
            switch network {
            case "Visa": return .visa
            case "Mastercard": return .masterCard
            default: return .genericCard
            }
        case .payPalOrder: return .paypal2
        case .payPalBillingAgreement: return .paypal2
        case .goCardlessMandate: return .bank
        case .klarnaCustomerToken: return .klarna
        case .stripeAch: return .achBank
        default: return .creditCard
        }
    }

    var cardButtonViewModel: CardButtonViewModel? {
        switch self.paymentInstrumentType {
        case .paymentCard:
            guard let ntwrk = self.paymentInstrumentData?.binData?.network else { return nil }
            guard let last4 = self.paymentInstrumentData?.last4Digits else { return nil }
            guard let expMonth = self.paymentInstrumentData?.expirationMonth else { return nil }
            guard let expYear = self.paymentInstrumentData?.expirationYear else { return nil }
            return CardButtonViewModel(
                network: ntwrk,
                cardholder: self.paymentInstrumentData?.cardholderName ?? "",
                last4: "•••• \(last4)",
                expiry: Strings.PrimerCardFormView.savedCardTitle + " \(expMonth) / \(expYear.suffix(2))",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType)
        case .payPalBillingAgreement:
            guard let cardholder = self.paymentInstrumentData?.externalPayerInfo?.email else { return nil }
            return CardButtonViewModel(network: "PayPal",
                                       cardholder: cardholder,
                                       last4: "",
                                       expiry: "",
                                       imageName: self.icon,
                                       paymentMethodType: self.paymentInstrumentType)
        case .goCardlessMandate:
            return CardButtonViewModel(network: "Bank account",
                                       cardholder: "",
                                       last4: "",
                                       expiry: "",
                                       imageName: self.icon,
                                       paymentMethodType: self.paymentInstrumentType)
        case .klarnaCustomerToken:
            return CardButtonViewModel(
                network: paymentInstrumentData?.sessionData?.billingAddress?.email ?? "Klarna Customer Token",
                cardholder: "",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType)
        case .stripeAch:
            return CardButtonViewModel(
                network: self.paymentInstrumentData?.bankName ?? "Bank account",
                cardholder: "•••• \(self.paymentInstrumentData?.accountNumberLast4Digits ?? "")",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType)
        default:
            return nil
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
