//
//  Klarna.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 24/3/21.
//



import Foundation

extension Request.Body {
    public class Klarna {}
}

extension Response.Body {
    public class Klarna {}
}

public enum KlarnaSessionType: String, Codable {
    case hostedPaymentPage = "HOSTED_PAYMENT_PAGE"
    case recurringPayment = "RECURRING_PAYMENT"
}

// MARK: KLARNA API DATA MODELS

extension Request.Body.Klarna {
    
    struct CreateCustomerToken: Codable {
        
        let paymentMethodConfigId: String
        let sessionId: String
        let authorizationToken: String
        let description: String?
        let localeData: PrimerLocaleData
    }
    
    struct CreatePaymentSession: Codable {
        
        struct Attachment: Codable {
            let body: AttachmentBody
            let contentType: String
            
            init(body: AttachmentBody) {
                self.body = body
                self.contentType = "application/vnd.klarna.internal.emd-v2+json"
            }
            
            func encode(to encoder: Encoder) throws {
                guard let body = try self.body.toString() else {
                    return
                }
                var container = encoder.container(keyedBy: Request.Body.Klarna.CreatePaymentSession.Attachment.CodingKeys.self)
                try container.encode(body, forKey: Request.Body.Klarna.CreatePaymentSession.Attachment.CodingKeys.body)
                try container.encode(self.contentType, forKey: Request.Body.Klarna.CreatePaymentSession.Attachment.CodingKeys.contentType)
            }
        }
        
        struct AttachmentBody: Codable {
            let customerAccountInfo: [CustomerAccountInfo]
            
            func toString() throws -> String? {
                let jsonData = try JSONEncoder().encode(self)
                let jsonString = String(data: jsonData, encoding: .utf8)
                return jsonString
            }
        }
        
        struct CustomerAccountInfo: Codable {
            let uniqueAccountIdenitfier: String
            let acountRegistrationDate: String
            let accountLastModified: String
            let appId: String?
        }
        
        let paymentMethodConfigId: String
        let sessionType: KlarnaSessionType
        let localeData: PrimerLocaleData?
        let description: String?
        let redirectUrl: String?
        let totalAmount: Int?
        let orderItems: [OrderItem]?
        let attachment: Attachment?
    }
    
    struct FinalizePaymentSession: Codable {
        
        let paymentMethodConfigId: String
        let sessionId: String
    }
}

extension Response.Body.Klarna {
    
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
    
    struct CreatePaymentSession: Codable {
        
        var sessionType: KlarnaSessionType {
            return hppSessionId == nil ? .recurringPayment : .hostedPaymentPage
        }
        let clientToken: String
        let sessionId: String
        let categories: [Response.Body.Klarna.SessionCategory]
        let hppSessionId: String?
        let hppRedirectUrl: String?
    }
    
    struct CustomerToken: Codable {
        
        let customerTokenId: String?
        let sessionData: Response.Body.Klarna.SessionData
    }
    
    struct SessionCategory: Codable {
        
        let identifier: String
        let name: String
        let descriptiveAssetUrl: String
        let standardAssetUrl: String
    }
    
    public struct SessionData: Codable {
        
        public let recurringDescription: String?
        public let purchaseCountry: String?
        public let purchaseCurrency: String?
        public let locale: String?
        public let orderAmount: Int?
        public let orderLines: [Response.Body.Klarna.SessionOrderLines]
        public let billingAddress: Response.Body.Klarna.BillingAddress?
        public let tokenDetails: Response.Body.Klarna.TokenDetails?
    }
    
    public struct SessionOrderLines: Codable {
        
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


