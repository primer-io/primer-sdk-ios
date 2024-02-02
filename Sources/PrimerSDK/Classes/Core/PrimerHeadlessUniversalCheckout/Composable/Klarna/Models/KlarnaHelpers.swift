//
//  KlarnaHelpers.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 01.02.2024.
//

import Foundation

struct KlarnaHelpers {
    static func getSessionType() -> KlarnaSessionType {
        if PrimerInternal.shared.intent == .vault {
            return .recurringPayment
        } else {
            return .oneOffPayment
        }
    }
    
    static func getKlarnaCustomerTokenBody(
        with paymentMethodConfigId: String,
        sessionId: String,
        authorizationToken: String,
        recurringPaymentDescription: String?
    ) -> Request.Body.Klarna.CreateCustomerToken {
        let sessionType = getSessionType()
        return Request.Body.Klarna.CreateCustomerToken(
            paymentMethodConfigId: paymentMethodConfigId,
            sessionId: sessionId,
            authorizationToken: sessionType == .oneOffPayment ? nil : authorizationToken,
            description: sessionType == .oneOffPayment ? nil : recurringPaymentDescription,
            localeData: sessionType == .oneOffPayment ? nil : PrimerSettings.current.localeData)
    }
    
    static func getKlarnaPaymentSessionBody(
        with attachment: Request.Body.Klarna.CreatePaymentSession.Attachment?,
        paymentMethodConfigId: String,
        clientSession: ClientSession.APIResponse?,
        recurringPaymentDescription: String?,
        redirectUrl: String?) -> Request.Body.Klarna.CreatePaymentSession {
            
            let sessionType = getSessionType()
            var description: String?
            var totalAmount: Int?
            var redUrl: String?
            var orderItems: [Request.Body.Klarna.OrderItem]?
            var billingAddress: Response.Body.Klarna.BillingAddress?
            var shippingAddress: Response.Body.Klarna.BillingAddress?
            
            switch sessionType {
            case .oneOffPayment:
                orderItems = clientSession?.order?.lineItems?.compactMap({ getOrderItem(from: $0) })
                let surcharge = getSurcharge(fees: clientSession?.order?.fees)
                orderItems = addedSurchargeItem(to: orderItems ?? [], surcharge: surcharge)
                totalAmount = clientSession?.order?.totalOrderAmount
                billingAddress = getCustomerAddress(of: .billing, clientSession: clientSession)
                shippingAddress = getCustomerAddress(of: .shipping, clientSession: clientSession)
            case .recurringPayment:
                description = recurringPaymentDescription
                redUrl = redirectUrl
            }
            
            let countryCode = clientSession?.order?.countryCode?.rawValue ?? ""
            let currencyCode = clientSession?.order?.currencyCode?.rawValue ?? ""
            let localeCode = PrimerSettings.current.localeData.localeCode
            let localeData = Request.Body.Klarna.KlarnaLocaleData(
                countryCode: countryCode,
                currencyCode: currencyCode,
                localeCode: localeCode)
            
            return Request.Body.Klarna.CreatePaymentSession(
                paymentMethodConfigId: paymentMethodConfigId,
                sessionType: sessionType,
                localeData: localeData,
                description: description,
                redirectUrl: redUrl,
                totalAmount: totalAmount,
                orderItems: orderItems,
                attachment: attachment,
                billingAddress: billingAddress,
                shippingAddress: shippingAddress)
        }
    
    static func getCustomerAddress(of type: AddressType, clientSession: ClientSession.APIResponse?) -> Response.Body.Klarna.BillingAddress {
        let billingAddress = clientSession?.customer?.billingAddress
        let shippingAddress = clientSession?.customer?.shippingAddress
        let customerEmail = clientSession?.customer?.emailAddress
        let customerPhone = clientSession?.customer?.mobileNumber
        
        return Response.Body.Klarna.BillingAddress(
            addressLine1: type == .billing ? billingAddress?.addressLine1 : shippingAddress?.addressLine1,
            addressLine2: type == .billing ? billingAddress?.addressLine2 : shippingAddress?.addressLine2,
            addressLine3: nil,
            city: type == .billing ? billingAddress?.city : shippingAddress?.city,
            countryCode: type == .billing ? billingAddress?.countryCode?.rawValue : shippingAddress?.countryCode?.rawValue,
            email: customerEmail,
            firstName: type == .billing ? billingAddress?.firstName : shippingAddress?.firstName,
            lastName: type == .billing ? billingAddress?.lastName : shippingAddress?.lastName,
            phoneNumber: customerPhone,
            postalCode: type == .billing ? billingAddress?.postalCode : shippingAddress?.postalCode,
            state: type == .billing ? billingAddress?.state : shippingAddress?.state,
            title: nil)
    }
    
    static func getOrderItem(from item: ClientSession.Order.LineItem) -> Request.Body.Klarna.OrderItem {
        Request.Body.Klarna.OrderItem(
            name: item.description ?? "",
            unitAmount: item.amount ?? 0,
            reference: item.itemId ?? "",
            quantity: item.quantity,
            discountAmount: item.discountAmount ?? 0,
            productType: item.productType,
            taxAmount: item.taxAmount ?? 0)
    }
    
    static func addedSurchargeItem(to list: [Request.Body.Klarna.OrderItem], surcharge: Int?) -> [Request.Body.Klarna.OrderItem] {
        var orderList = list
        guard let surcharge else { return orderList }
        
        let surchargeItem = Request.Body.Klarna.OrderItem(
            name: "surcharge",
            unitAmount: surcharge,
            reference: nil,
            quantity: 1,
            discountAmount: nil,
            productType: "surcharge",
            taxAmount: nil)
        orderList.append(surchargeItem)
        
        return orderList
    }
    
    static func getSurcharge(fees: [ClientSession.Order.Fee]?) -> Int? {
        if let fees { return fees.first(where:{ $0.type == .surcharge })?.amount }
        return nil
    }
    
}
