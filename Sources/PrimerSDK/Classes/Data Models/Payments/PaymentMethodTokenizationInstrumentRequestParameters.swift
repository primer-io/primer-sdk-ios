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
    
}

#endif
