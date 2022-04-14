//
//  PaymentMethodTokenizationInstrumentParameters.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/4/22.
//

#if canImport(UIKit)

import Foundation

protocol PaymentMethodTokenizationInstrumentRequestParameters: Codable {}
public protocol PaymentMethodTokenizationInstrumentResponseData: Codable {}

extension PaymentMethod {
    
    // MARK: - Apaya ✅
    public class Apaya {
        
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let merchantId: String
                let merchantAccountId: String
            }
        }
        
        public class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let currencyCode: String
                let hashedIdentifier: String
                let mcc: String
                let mnc: String
                let mx: String
                let productId: String
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let hashedIdentifier: String?
                public let mnc: Int
                public let mcc: Int
                public let mx: String
                public let currencyCode: Currency?
                public let productId: String?
            }
        }
        
    }
    
    // MARK: - ApplePay ✅
    class ApplePay {
        
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let certificates: [PaymentMethod.ApplePay.Configuration.Options.Certificate]
                
                struct Certificate: Codable {
                    let certificateId: String?
                    let createdAt: String?
                    let expirationTimestamp: String?
                    let merchantId: String?
                    let status: String?
                    let validFromTimestamp: String?
                }
            }
        }
        
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paymentMethodConfigId: String
                let token: ApplePayPaymentResponseToken
                let sourceConfig: PaymentMethod.ApplePay.SourceConfig
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let last4Digits: String?
                public let expirationYear: String?
                public let expirationMonth: String?
                public let isNetworkTokenized: Bool?
                public let binData: PaymentMethod.PaymentCard.BinData?
                public let network: String?
            }
        }
        
        
        struct SourceConfig: Codable {
            let source: String
            let merchantId: String
        }
    }
    
    // MARK: - Blik ✅
    class Blik {
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let merchantId: String
                let merchantAccountId: String
            }
        }
        
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paymentMethodConfigId: String
                let paymentMethodType: String
                let sessionInfo: PaymentMethod.Blik.SessionInfo
            }
            
//            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
//
//            }
        }
        
        struct SessionInfo: Codable {
            let blikCode: String
            let locale: String
            lazy var platform: String = {
                "IOS"
            }()
            lazy var redirectionUrl: String? = {
                PrimerSettings.current.urlScheme
            }()
        }
    }
    
    // MARK: - Dot Pay ✅
    class DotPay {
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let merchantId: String
                let merchantAccountId: String
            }
        }
        
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paymentMethodConfigId: String
                let paymentMethodType: String
                let sessionInfo: PaymentMethod.DotPay.SessionInfo
                lazy var type: String = {
                    "OFF_SESSION_PAYMENT"
                }()
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let paymentMethodConfigId: String
                public let paymentMethodType: String
                public let sessionInfo: PaymentMethod.Blik.SessionInfo
            }
        }
        
        struct SessionInfo: Codable {
            var issuer: String?
            var locale: String = "en_US"
            var platform: String = "IOS"
        }
    }
    
//    // MARK: - GoCardless (not used yet)
//    class GoCardless {
//        public class Configuration {
//            struct Options: PaymentMethodConfigurationOptions {
//                let merchantId: String
//                let merchantAccountId: String
//                let clientId: String
//            }
//        }
//
//        class Tokenization {
//            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
//                let gocardlessMandateId: String
//            }
//        }
//    }
    
//    // MARK: - Google Pay (not used)
//    class GooglePay {
//        public class Configuration {
//            struct Options: PaymentMethodConfigurationOptions {
//                let merchantId: String
//                let merchantName: String
//                let type: String
//            }
//        }
//
//        class Tokenization {
//            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
//                let paymentMethodConfigId: String
//                let token: ApplePayPaymentResponseToken
//                let sourceConfig: ApplePaySourceConfig
//            }
//        }
//
//    }
    
//    // MARK: - KlarnaAuth (not used yet)
//    class KlarnaAuth {
//        class Tokenization {
//            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
//                let klarnaAuthorizationToken: String
//            }
//        }
//    }
    
    // MARK: - KlarnaCustomer ✅
    public class KlarnaCustomer {
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let clientId: String
                let merchantAccountId: String
                let merchantId: String
            }
        }
        
        public class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let klarnaCustomerToken: String
                let sessionData: KlarnaSessionData
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let klarnaCustomerToken: String
                public let sessionData: PaymentMethod.KlarnaCustomer.SessionData?
            }
        }
        
        public struct SessionData: Codable {
            public let recurringDescription: String?
            public let purchaseCountry: String?
            public let purchaseCurrency: String?
            public let locale: String?
            public let orderAmount: Int?
            public let orderLines: [KlarnaSessionOrderLines]
            public let billingAddress: KlarnaBillingAddress?
            public let tokenDetails: KlarnaSessionDataTokenDetails?
        }
    }
    
    // MARK: - Payment Card ✅
    public class PaymentCard {
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let threeDSecureEnabled: Bool
                let threeDSecureToken: String?
                let threeDSecureInitUrl: String?
                let threeDSecureProvider: String
                let processorConfigId: String?
            }
        }
        
        public class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let number: String
                let cvv: String
                let expirationMonth: String
                let expirationYear: String
                let cardholderName: String?
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let first6Digits: String?
                public let last4Digits: String
                public let expirationMonth: String
                public let expirationYear: String
                public let cardholderName: String?
                public let network: String
                public let isNetworkTokenized: Bool
                public let binData: PaymentMethod.PaymentCard.BinData?
            }
        }
        
        public struct BinData: Codable {
            public var accountFundingType: String?
            public var accountNumberType: String?
            public var network: String?
            public var issuerCountryCode: String?
            public var issuerCurrencyCode: String?
            public var issuerName: String?
            public var prepaidReloadableIndicator: String?
            public var productCode: String?
            public var productName: String?
            public var productUsageType: String?
            public var regionalRestriction: String?
        }
        
        struct ButtonViewModel {
            let network, cardholder, last4, expiry: String
            let imageName: ImageName
            let paymentMethodType: PaymentMethod.Tokenization.Response.InstrumentType
            var surCharge: Int? {
                let state: AppStateProtocol = DependencyContainer.resolve()
                guard let options = state.primerConfiguration?.clientSession?.paymentMethod?.options else { return nil }
                guard let paymentCardOption = options.filter({ $0["type"] as? String == "PAYMENT_CARD" }).first else { return nil }
                guard let networks = paymentCardOption["networks"] as? [[String: Any]] else { return nil }
                guard let tmpNetwork = networks.filter({ ($0["type"] as? String)?.lowercased() == network.lowercased() }).first else { return nil }
                return tmpNetwork["surcharge"] as? Int
            }
        }
    }
    
    // MARK: - Pay Pal ✅
    public class PayPal: PaymentMethodTokenizationInstrumentRequestParameters {
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let clientId: String
                let merchantAccountId: String
                let merchantId: String
            }
        }
        
        public class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paypalOrderId: String?
                let paypalBillingAgreementId: String?
                let shippingAddress: PaymentMethod.PayPal.ShippingAddress?
                let externalPayerInfo: PaymentMethod.PayPal.ExternalPayerInfo?
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let paypalOrderId: PaymentMethod.PayPal.ShippingAddress
                public let externalPayerInfo: PaymentMethod.PayPal.ExternalPayerInfo
            }
        }
        
        public struct ExternalPayerInfo: Codable {
            public var email: String
            public var externalPayerId, firstName, lastName: String?
        }
        
        public struct ShippingAddress: Codable {
            let firstName, lastName, addressLine1, addressLine2, city, state, countryCode, postalCode: String?
        }
        
        class PayerInfo {
            struct Request: Codable {
                let paymentMethodConfigId: String
                let orderId: String
            }
            
            struct Response: Codable {
                let orderId: String
                let externalPayerInfo: PaymentMethod.PayPal.ExternalPayerInfo
            }
        }
    }
    
//    // MARK: - Primer Test ECom
//    public class PrimerTestECom: PaymentMethodTokenizationInstrumentRequestParameters {
//        
//        public class Configuration {
//            struct Options: PaymentMethodConfigurationOptions {
//                let merchantId: String
//                let clientId: String
//                let merchantAccountId: String
//            }
//        }
//        
//    }
    
    // MARK: - Redirect ✅
    public class Redirect: PaymentMethodTokenizationInstrumentRequestParameters {
        class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let merchantAccountId: String
                let merchantId: String
            }
        }

        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paymentMethodConfigId: String
                let paymentMethodType: String
                let sessionInfo: PaymentMethod.Redirect.SessionInfo
                let type: String = "OFF_SESSION_PAYMENT"
            }
            
            struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                let paymentMethodConfigId: String
                let paymentMethodType: String
                let sessionInfo: PaymentMethod.Redirect.SessionInfo
            }
        }
        
        struct SessionInfo: Codable {
            var locale: String?
            var platform: String = "IOS"
            var redirectionUrl: String? = PrimerSettings.current.urlScheme
        }
    }
    
}

#endif
