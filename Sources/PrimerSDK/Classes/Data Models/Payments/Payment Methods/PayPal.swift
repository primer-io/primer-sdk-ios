#if canImport(UIKit)

extension PaymentMethod {
    
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
        
        class CreateOrder {
            struct Request: Codable {
                let paymentMethodConfigId: String
                let amount: Int
                let currencyCode: Currency
                var locale: CountryCode?
                let returnUrl: String
                let cancelUrl: String
            }
            
            struct Response: Codable {
                let orderId: String
                let approvalUrl: String
            }
        }
        
        class CreateBillingAgreement {
            struct Request: Codable {
                let paymentMethodConfigId: String
                let returnUrl: String
                let cancelUrl: String
            }
            
            struct Response: Codable {
                let tokenId: String
                let approvalUrl: String
            }
        }
        
        class ConfirmBillingAgreement {
            struct Request: Encodable {
                let paymentMethodConfigId, tokenId: String
            }
            
            struct Response: Codable {
                let billingAgreementId: String
                let externalPayerInfo: PaymentMethod.PayPal.ExternalPayerInfo
                let shippingAddress: PaymentMethod.PayPal.ShippingAddress
            }
        }
        
    }
    
}









#endif
