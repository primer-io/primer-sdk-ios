//
//  PaymentMethodTokenizationInstrumentParameters.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/4/22.
//

#if canImport(UIKit)

import Foundation

protocol PaymentMethodTokenizationInstrumentParameters: Codable {}

extension PaymentMethod.Tokenization {
    class InstrumentParameters {
        struct PaymentCard: PaymentMethodTokenizationInstrumentParameters {
            let number: String
            let cvv: String
            let expirationMonth: String
            let expirationYear: String
            let cardholderName: String?
        }
        
        struct PayPal: PaymentMethodTokenizationInstrumentParameters {
            let paypalOrderId: String?
            let paypalBillingAgreementId: String?
            let shippingAddress: ShippingAddress?
            let externalPayerInfo: ExternalPayerInfo?
        }
        
        struct ApplePay: PaymentMethodTokenizationInstrumentParameters {
            let paymentMethodConfigId: String
            let token: ApplePayPaymentResponseToken
            let sourceConfig: ApplePaySourceConfig
        }
        
        struct Redirect: PaymentMethodTokenizationInstrumentParameters {
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

        struct GoCardless: PaymentMethodTokenizationInstrumentParameters {
            let gocardlessMandateId: String
        }

        struct KlarnaAuth: PaymentMethodTokenizationInstrumentParameters {
            let klarnaAuthorizationToken: String
        }

        struct KlarnaCustomer: PaymentMethodTokenizationInstrumentParameters {
            let klarnaCustomerToken: String
            let sessionData: KlarnaSessionData
        }

        struct Apaya: PaymentMethodTokenizationInstrumentParameters {
            let currencyCode: String
            let hashedIdentifier: String
            let mcc: String
            let mnc: String
            let mx: String
            let productId: String
        }

        struct DotPay: PaymentMethodTokenizationInstrumentParameters {
            let sessionInfo: BankSelectorSessionInfo
            lazy var type: String = {
                "OFF_SESSION_PAYMENT"
            }()
            let paymentMethodType: String
        }
    }
}







#endif


