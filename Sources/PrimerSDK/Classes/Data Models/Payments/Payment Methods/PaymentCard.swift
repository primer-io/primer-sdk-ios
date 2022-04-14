//
//  PaymentCard.swift
//  PrimerSDK
//
//  Created by Evangelos on 14/4/22.
//


#if canImport(UIKit)

import Foundation

extension PaymentMethod {
    
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
    
}

#endif
