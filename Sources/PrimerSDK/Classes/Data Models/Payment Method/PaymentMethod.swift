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
    
    public enum `Type`: Codable {
        case applePay
        
        var logo: UIImage? {
            return nil
        }
        
        var icon: UIImage? {
            return nil
        }
    }
    
    public enum Flow: String, Codable {
        case vault = "VAULT"
        case checkout = "CHECKOUT"
    }
    
    public enum TokenType: String, Codable {
        case multiUse = "MULTI_USE"
        case singleUse = "SINGLE_USE"
    }
    
    internal class Configuration {
        
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
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                if let paymentCardTokenizationInstrumentParameters = (try? container.decode(PaymentCardTokenizationInstrumentParameters.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = paymentCardTokenizationInstrumentParameters
                } else if let payPalTokenizationInstrumentParameters = (try? container.decode(PayPalTokenizationInstrumentParameters.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = payPalTokenizationInstrumentParameters
                } else if let applePayTokenizationInstrumentParameters = (try? container.decode(ApplePayTokenizationInstrumentParameters.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = applePayTokenizationInstrumentParameters
                } else if let goCardlessTokenizationInstrumentParameters = (try? container.decode(GoCardlessTokenizationInstrumentParameters.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = goCardlessTokenizationInstrumentParameters
                } else if let klarnaAuthTokenizationInstrumentParameters = (try? container.decode(KlarnaAuthTokenizationInstrumentParameters.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = klarnaAuthTokenizationInstrumentParameters
                } else if let klarnaCustomerTokenizationInstrumentParameters = (try? container.decode(KlarnaCustomerTokenizationInstrumentParameters.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = klarnaCustomerTokenizationInstrumentParameters
                } else if let apayaTokenizationInstrumentParameters = (try? container.decode(ApayaTokenizationInstrumentParameters.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = apayaTokenizationInstrumentParameters
                } else if let dotPayTokenizationInstrumentParameters = (try? container.decode(DotPayTokenizationInstrumentParameters.self, forKey: .paymentInstrument)) {
                    self.paymentInstrument = dotPayTokenizationInstrumentParameters
                } else {
                    fatalError()
                }
                
                self.tokenType = try container.decode(PaymentMethod.TokenType.self, forKey: .tokenType)
                self.paymentFlow = try container.decode(PaymentMethod.Flow?.self, forKey: .paymentFlow)
                self.customerId = try container.decode(String?.self, forKey: .customerId)
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                
                if let paymentCardTokenizationInstrumentParameters = paymentInstrument as? PaymentCardTokenizationInstrumentParameters {
                    try container.encode(paymentCardTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let payPalTokenizationInstrumentParameters = paymentInstrument as? PayPalTokenizationInstrumentParameters {
                    try container.encode(payPalTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let applePayTokenizationInstrumentParameters = paymentInstrument as? ApplePayTokenizationInstrumentParameters {
                    try container.encode(applePayTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let goCardlessTokenizationInstrumentParameters = paymentInstrument as? GoCardlessTokenizationInstrumentParameters {
                    try container.encode(goCardlessTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let klarnaAuthTokenizationInstrumentParameters = paymentInstrument as? KlarnaAuthTokenizationInstrumentParameters {
                    try container.encode(klarnaAuthTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let klarnaCustomerTokenizationInstrumentParameters = paymentInstrument as? KlarnaCustomerTokenizationInstrumentParameters {
                    try container.encode(klarnaCustomerTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let apayaTokenizationInstrumentParameters = paymentInstrument as? ApayaTokenizationInstrumentParameters {
                    try container.encode(apayaTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else if let dotPayTokenizationInstrumentParameters = paymentInstrument as? DotPayTokenizationInstrumentParameters {
                    try container.encode(dotPayTokenizationInstrumentParameters, forKey: .paymentInstrument)
                } else {
                    fatalError()
                }
                
                try container.encode(self.tokenType, forKey: .tokenType)
                try? container.encode(self.paymentFlow, forKey: .paymentFlow)
                try? container.encode(self.customerId, forKey: .customerId)
            }
        }
        
        public struct Response: Codable {
            public var analyticsId: String?
            public var id: String?
            public var isVaulted: Bool?
            private var isAlreadyVaulted: Bool?
            public var paymentInstrumentType: PaymentInstrumentType
            public var paymentInstrumentData: PaymentInstrumentData?
            public var threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
            public var token: String?
            public var tokenType: PaymentMethod.TokenType?
            public var vaultData: VaultData?
        }
    }
}

#endif

