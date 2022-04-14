#if canImport(UIKit)

extension PaymentMethod {
    
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
                let token: PaymentMethod.ApplePay.PKPaymentResponseToken
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
        
        struct PKPaymentsRequest {
            var currency: Currency
            var merchantIdentifier: String
            var countryCode: CountryCode
            var items: [OrderItem]
        }
        
        struct PKPaymentsResponse {
            let token: PaymentMethod.ApplePay.PKPaymentResponseToken
        }
        
        struct PKPaymentResponseToken: Codable {
            let paymentMethod: PaymentMethod.ApplePay.PKPaymentResponsePaymentMethod
            let transactionIdentifier: String
            let paymentData: PaymentMethod.ApplePay.PKPaymentResponseTokenPaymentData
        }
        
        struct PKPaymentResponsePaymentMethod: Codable {
            let displayName: String?
            let network: String?
            let type: String?
        }
        
        struct PKPaymentResponseTokenPaymentData: Codable {
            let data: String
            let signature: String
            let version: String
            let header: PaymentMethod.ApplePay.PKTokenPaymentDataHeader
        }
        
        struct PKTokenPaymentDataHeader: Codable {
            let ephemeralPublicKey: String
            let publicKeyHash: String
            let transactionId: String
        }
    }
    
}

#endif
