//
//  Klarna.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 24/3/21.
//

#if canImport(UIKit)

import Foundation

extension PaymentMethod {
    
    // MARK: - KlarnaCustomer ✅
    public class KlarnaCustomer {
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let clientId: String
                let merchantAccountId: String
                let merchantId: String
            }
        }
        
        public class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let klarnaCustomerToken: String
                let sessionData: PaymentMethod.Klarna.Session.Data
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let klarnaCustomerToken: String
                public let sessionData: PaymentMethod.Klarna.Session.Data?
            }
        }
    }
    
}

extension PaymentMethod {
    
    public class Klarna {
        public struct BillingAddress: Codable {
            public let addressLine1: String?
            public let addressLine2: String?
            public let addressLine3: String?
            public let city: String?
            public let countryCode: String?
            public let email: String?
            public let firstName: String?
            public let lastName: String?
            public let phoneNumber: String?
            public let postalCode: String?
            public let state: String?
            public let title: String?
        }
        
        public class Session {
            public enum SessionType: String, Codable {
                case hostedPaymentPage = "HOSTED_PAYMENT_PAGE"
                case recurringPayment = "RECURRING_PAYMENT"
            }
            
            public struct Data: Codable {
                public let recurringDescription: String?
                public let purchaseCountry: String?
                public let purchaseCurrency: String?
                public let locale: String?
                public let orderAmount: Int?
                public let orderLines: [PaymentMethod.Klarna.Session.OrderLines]
                public let billingAddress: PaymentMethod.Klarna.BillingAddress?
                public let tokenDetails: PaymentMethod.Klarna.Session.Data.TokenDetails?
                
                public struct TokenDetails: Codable {
                    public let brand: String?
                    public let maskedNumber: String?
                    public let type: String
                    public let expiryDate: String?
                    
                    enum CodingKeys: String, CodingKey {
                        case brand = "brand"
                        case maskedNumber = "masked_number"
                        case type = "type"
                        case expiryDate = "expiry_date"
                    }
                }
            }
            
            struct Category: Codable {
                let identifier: String
                let name: String
                let descriptiveAssetUrl: String
                let standardAssetUrl: String
            }
            
            public struct OrderLines: Codable {
                public let type: String?
                public let name: String?
                public let quantity: Int?
                public let unitPrice: Int?
                public let totalAmount: Int?
                public let totalDiscountAmount: Int?

                enum CodingKeys: String, CodingKey {
                    case type = "type"
                    case name = "name"
                    case quantity = "quantity"
                    case unitPrice = "unit_price"
                    case totalAmount = "total_amount"
                    case totalDiscountAmount = "total_discount_amount"
                }
            }
        }
        
        class CreatePaymentSession {
            struct Request: Codable {
                let paymentMethodConfigId: String
                let sessionType: PaymentMethod.Klarna.Session.SessionType
                var localeData: LocaleData?
                let description: String?
                let redirectUrl: String?
                let totalAmount: Int?
                let orderItems: [OrderItem]?
            }
            
            struct Response: Codable {
                var sessionType: PaymentMethod.Klarna.Session.SessionType {
                    return hppSessionId == nil ? .recurringPayment : .hostedPaymentPage
                }
                let clientToken: String
                let sessionId: String
                let categories: [PaymentMethod.Klarna.Session.Category]
                let hppSessionId: String?
                let hppRedirectUrl: String
            }
        }
        
        class FinalizePaymentSession {
            struct Request: Codable {
                let paymentMethodConfigId: String
                let sessionId: String
            }
        }
        
        class CreateCustomerToken {
            struct Request: Codable {
                let paymentMethodConfigId: String
                let sessionId: String
                let authorizationToken: String
                let description: String?
                let localeData: LocaleData
            }
            
            struct Response: Codable {
                let customerTokenId: String?
                let sessionData: PaymentMethod.Klarna.Session.Data
            }
        }
    }
    
}

#endif
