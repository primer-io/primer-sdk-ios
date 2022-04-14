//
//  Blik.swift
//  PrimerSDK
//
//  Created by Evangelos on 14/4/22.
//

#if canImport(UIKit)

import Foundation

extension PaymentMethod {
    
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
    
}

#endif
