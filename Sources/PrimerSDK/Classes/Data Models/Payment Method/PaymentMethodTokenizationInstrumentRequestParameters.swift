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
    
    // MARK: - Apaya
    public class Apaya {
        
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
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
    
    // MARK: - ApplePay
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
                let sourceConfig: ApplePaySourceConfig
            }
        }
        
    }
    
    // MARK: - Blik
    class Blik {
        
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let paymentMethodConfigId: String
                let paymentMethodType: PaymentMethod.PaymentMethodType
                let sessionInfo: Blik.SessionInfo
                lazy var type: String = {
                    "OFF_SESSION_PAYMENT"
                }()
            }
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
    
    // MARK: - Dot Pay
    class DotPay {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let sessionInfo: PaymentMethod.DotPay.SessionInfo
                lazy var type: String = {
                    "OFF_SESSION_PAYMENT"
                }()
                let paymentMethodType: String
            }
        }
        
        struct SessionInfo: Codable {
            var issuer: String?
            var locale: String = "en_US"
            var platform: String = "IOS"
        }
    }
    
    // MARK: - GoCardless
    class GoCardless {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let gocardlessMandateId: String
            }
        }
    }
    
    // MARK: - Google Pay
    class GooglePay {
        
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let merchantId: String
                let merchantName: String
                let type: String
            }
        }
        
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paymentMethodConfigId: String
                let token: ApplePayPaymentResponseToken
                let sourceConfig: ApplePaySourceConfig
            }
        }
        
    }
    
    // MARK: - KlarnaAuth
    class KlarnaAuth {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let klarnaAuthorizationToken: String
            }
        }
    }
    
    // MARK: - KlarnaCustomer
    public class KlarnaCustomer {
        public class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let klarnaCustomerToken: String
                let sessionData: KlarnaSessionData
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let klarnaCustomerToken: String?
                public let sessionData: KlarnaSessionData?
            }
        }
    }
    
    // MARK: - Payment Card
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
                public let first6Digits: String
                public let last4Digits: String
                public let expirationMonth: String
                public let expirationYear: String
                public let cardholderName: String
                public let network: String
                public let isNetworkTokenized: Bool
                public let binData: PaymentMethod.PaymentCard.BinData?
                public let threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
            }
            
        }
        
        public struct BinData: Codable {
            public var network: String?
            public var issuerCountryCode: String?
            public var issuerName: String?
            public var issuerCurrencyCode: String?
            public var regionalRestriction: String?
            public var accountNumberType: String?
            public var accountFundingType: String?
            public var prepaidReloadableIndicator: String?
            public var productUsageType: String?
            public var productCode: String?
            public var productName: String?
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
    
    // MARK: - Pay Pal
    public class PayPal: PaymentMethodTokenizationInstrumentRequestParameters {
        
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let clientId: String
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
            public var externalPayerId, email, firstName, lastName: String?
        }
        
        public struct ShippingAddress: Codable {
            let firstName, lastName, addressLine1, addressLine2, city, state, countryCode, postalCode: String?
        }
    }
    
    // MARK: - Primer Test ECom
    public class PrimerTestECom: PaymentMethodTokenizationInstrumentRequestParameters {
        
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let merchantId: String
                let clientId: String
                let merchantAccountId: String
            }
        }
        
    }
    
    // MARK: - Redirect
    public class Redirect: PaymentMethodTokenizationInstrumentRequestParameters {
        
        class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let paymentMethodConfigId: String
                let paymentMethodType: PaymentMethod.PaymentMethodType
                let sessionInfo: PaymentMethod.Redirect.SessionInfo
                lazy var type: String = {
                    "OFF_SESSION_PAYMENT"
                }()
            }
        }

        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paymentMethodType: PaymentMethod.PaymentMethodType
                let paymentMethodConfigId: String
                lazy var type: String = {
                    "OFF_SESSION_PAYMENT"
                }()
                let sessionInfo: PaymentMethod.Redirect.SessionInfo
            }
            
            struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                let paymentMethodConfigId: String
                let paymentMethodType: PaymentMethod.PaymentMethodType
                let sessionInfo: PaymentMethod.Redirect.SessionInfo
            }
        }
        
        struct SessionInfo: Codable {
            var locale: String
            var platform: String = "IOS"
            var redirectionUrl: String? = PrimerSettings.current.urlScheme
        }
    }
    
}

#endif
