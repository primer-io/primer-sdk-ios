//
//  PaymentMethod.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/4/22.
//

#if canImport(UIKit)

import Foundation

public typealias PaymentInstrument2 = PaymentMethod.Tokenization.Response

public class PaymentMethod {
    
    public enum Flow: String, Codable {
        case vault = "VAULT"
        case checkout = "CHECKOUT"
    }
    
    public enum TokenType: String, Codable {
        case multiUse = "MULTI_USE"
        case singleUse = "SINGLE_USE"
    }
    
    public class Tokenization {
        struct Request: Codable {
            let paymentInstrument: PaymentMethodTokenizationInstrumentParameters
            let tokenType: PaymentMethod.TokenType
            let paymentFlow: PaymentMethod.Flow?
            let customerId: String?
            
            private enum CodingKeys: String, CodingKey {
                case paymentInstrument, tokenType, paymentFlow, customerId
            }
            
            init(
                paymentInstrument: PaymentMethodTokenizationInstrumentParameters,
                tokenType: PaymentMethod.TokenType,
                paymentFlow: PaymentMethod.Flow?,
                customerId: String?
            ) {
                self.paymentInstrument = paymentInstrument
                self.tokenType = tokenType
                self.paymentFlow = paymentFlow
                self.customerId = customerId
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                if let paymentCardTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.PaymentCard.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = paymentCardTokenizationInstrumentParameters
                } else if let payPalTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.PayPal.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = payPalTokenizationInstrumentParameters
                } else if let applePayTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.ApplePay.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = applePayTokenizationInstrumentParameters
                } else if let goCardlessTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.GoCardless.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = goCardlessTokenizationInstrumentParameters
                } else if let klarnaAuthTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.KlarnaAuth.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = klarnaAuthTokenizationInstrumentParameters
                } else if let klarnaCustomerTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.KlarnaCustomer.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = klarnaCustomerTokenizationInstrumentParameters
                } else if let apayaTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.Apaya.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = apayaTokenizationInstrumentParameters
                } else if let dotPayTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.DotPay.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = dotPayTokenizationInstrumentParameters
                } else if let redirectTokenizationInstrumentParameters = (try? container.decode(PaymentMethod.Tokenization.InstrumentParameters.Redirect.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = redirectTokenizationInstrumentParameters
                } else {
                    fatalError()
                }
                
                self.tokenType = try container.decode(PaymentMethod.TokenType.self, forKey: .tokenType)
                self.paymentFlow = try container.decode(PaymentMethod.Flow?.self, forKey: .paymentFlow)
                self.customerId = try container.decode(String?.self, forKey: .customerId)
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                
                if let paymentCardTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.PaymentCard {
                    try container.encode(paymentCardTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let payPalTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.PayPal {
                    try container.encode(payPalTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let applePayTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.ApplePay {
                    try container.encode(applePayTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let goCardlessTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.GoCardless {
                    try container.encode(goCardlessTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let klarnaAuthTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.KlarnaAuth {
                    try container.encode(klarnaAuthTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let klarnaCustomerTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.KlarnaCustomer {
                    try container.encode(klarnaCustomerTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let apayaTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.Apaya {
                    try container.encode(apayaTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let dotPayTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.DotPay {
                    try container.encode(dotPayTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let redirectTokenizationInstrumentParameters = paymentInstrument as? PaymentMethod.Tokenization.InstrumentParameters.Redirect {
                    try container.encode(redirectTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else {
                    fatalError()
                }
                
                try container.encode(self.tokenType, forKey: .tokenType)
                try? container.encode(self.paymentFlow, forKey: .paymentFlow)
                try? container.encode(self.customerId, forKey: .customerId)
            }
        }
        
        public class Response: NSObject, Codable {
            public var analyticsId: String?
            public var id: String?
            public var isVaulted: Bool?
            private var isAlreadyVaulted: Bool?
            public var paymentInstrumentType: PaymentInstrumentType
            public var paymentInstrumentData: PaymentInstrumentData?
            public var threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
            public var token: String?
            public var tokenType: TokenType?
            public var vaultData: VaultData?
            
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
                default: return .creditCard
                }
            }
            
            var cardButtonViewModel: CardButtonViewModel? {
                switch self.paymentInstrumentType {
                case .paymentCard:
                    guard let ntwrk = self.paymentInstrumentData?.network else { return nil }
                    guard let cardholder = self.paymentInstrumentData?.cardholderName else { return nil }
                    guard let last4 = self.paymentInstrumentData?.last4Digits else { return nil }
                    guard let expMonth = self.paymentInstrumentData?.expirationMonth else { return nil }
                    guard let expYear = self.paymentInstrumentData?.expirationYear else { return nil }
                    return CardButtonViewModel(
                        network: ntwrk,
                        cardholder: cardholder,
                        last4: "•••• \(last4)",
                        expiry: NSLocalizedString("primer-saved-card",
                                                  tableName: nil,
                                                  bundle: Bundle.primerResources,
                                                  value: "Expires",
                                                  comment: "Expires - Saved card")
                        + " \(expMonth) / \(expYear.suffix(2))",
                        imageName: self.icon,
                        paymentMethodType: self.paymentInstrumentType)
                case .payPalBillingAgreement:
                    guard let cardholder = self.paymentInstrumentData?.externalPayerInfo?.email else { return nil }
                    return CardButtonViewModel(network: "PayPal", cardholder: cardholder, last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
                case .goCardlessMandate:
                    return CardButtonViewModel(network: "Bank account", cardholder: "", last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
                case .klarnaCustomerToken:
                    return CardButtonViewModel(
                        network: paymentInstrumentData?.sessionData?.billingAddress?.email ?? "Klarna Customer Token",
                        cardholder: "",
                        last4: "",
                        expiry: "",
                        imageName: self.icon,
                        paymentMethodType: self.paymentInstrumentType)
                    
                case .apayaToken:
                    guard self.paymentInstrumentType == .apayaToken else { return nil }
                    guard let mcc = self.paymentInstrumentData?.mcc,
                          let mnc = self.paymentInstrumentData?.mnc,
                          let carrier = Apaya.Carrier(mcc: mcc, mnc: mnc)
                    else { return nil }
                    
                    return CardButtonViewModel(
                        network: "[\(carrier.name)] \(self.paymentInstrumentData?.hashedIdentifier ?? "")",
                        cardholder: "Apaya",
                        last4: "",
                        expiry: "",
                        imageName: self.icon,
                        paymentMethodType: self.paymentInstrumentType)
                    
                default:
                    return nil
                }
            }
        }
    }
}

#endif

