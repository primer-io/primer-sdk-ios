//
//  Redirect.swift
//  PrimerSDK
//
//  Created by Evangelos on 14/4/22.
//

#if canImport(UIKit)

import Foundation

extension PaymentMethod {
    
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
