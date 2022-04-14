//
//  AdyenDotPay.swift
//  PrimerSDK
//
//  Created by Admin on 8/11/21.
//

#if canImport(UIKit)

import Foundation

extension PaymentMethod {
    
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
                public let sessionInfo: PaymentMethod.DotPay.SessionInfo
            }
        }
        
        struct SessionInfo: Codable {
            var issuer: String?
            var locale: String = "en_US"
            var platform: String = "IOS"
        }
    }
    
}

#endif
