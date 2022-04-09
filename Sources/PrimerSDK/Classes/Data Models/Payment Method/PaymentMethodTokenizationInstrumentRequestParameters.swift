//
//  PaymentMethodTokenizationInstrumentParameters.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/4/22.
//

#if canImport(UIKit)

import Foundation

protocol PaymentMethodTokenizationInstrumentRequestParameters: Codable {}
protocol PaymentMethodTokenizationInstrumentResponseData: Codable {}

extension PaymentMethod {
    
    // MARK: - Payment Card
    class PaymentCard {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let number: String
                let cvv: String
                let expirationMonth: String
                let expirationYear: String
                let cardholderName: String?
            }
            
            struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let paypalBillingAgreementId: String?
                public let first6Digits: String?
                public let last4Digits: String?
                public let expirationMonth: String?
                public let expirationYear: String?
                public let cardholderName: String?
                public let network: String?
                public let isNetworkTokenized: Bool?
                public let binData: BinData?
                public let threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
            }
        }
    }
    
    // MARK: - Pay Pal
    class PayPal: PaymentMethodTokenizationInstrumentRequestParameters {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paypalOrderId: String?
                let paypalBillingAgreementId: String?
                let shippingAddress: ShippingAddress?
                let externalPayerInfo: ExternalPayerInfo?
            }
        }
    }
    
    // MARK: - ApplePay
    class ApplePay {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paymentMethodConfigId: String
                let token: ApplePayPaymentResponseToken
                let sourceConfig: ApplePaySourceConfig
            }
        }
    }
    
    // MARK: - Redirect
    class Redirect {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let paymentMethodType: PaymentMethod.PaymentMethodType
                let paymentMethodConfigId: String
                lazy var type: String = {
                    "OFF_SESSION_PAYMENT"
                }()
                let sessionInfo: SessionInfo
                
                struct SessionInfo: Codable {
                    var locale: String
                    var platform: String = "IOS"
                    var redirectionUrl: String? = PrimerSettings.current.urlScheme
                }
                
            }
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
    
    // MARK: - KlarnaAuth
    class KlarnaAuth {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let klarnaAuthorizationToken: String
            }
        }
    }
    
    // MARK: - KlarnaCustomer
    class KlarnaCustomer {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let klarnaCustomerToken: String
                let sessionData: KlarnaSessionData
            }
        }
    }
    
    // MARK: - Apaya
    class Apaya {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let currencyCode: String
                let hashedIdentifier: String
                let mcc: String
                let mnc: String
                let mx: String
                let productId: String
            }
        }
    }
    
    class DotPay {
        class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let sessionInfo: BankSelectorSessionInfo
                lazy var type: String = {
                    "OFF_SESSION_PAYMENT"
                }()
                let paymentMethodType: String
            }
        }
    }
}

#endif
