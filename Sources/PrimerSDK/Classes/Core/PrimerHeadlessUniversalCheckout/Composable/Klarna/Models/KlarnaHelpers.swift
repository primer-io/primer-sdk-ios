//
//  KlarnaHelpers.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 01.02.2024.
//

import Foundation

// KlarnaHelpers: A utility structure to facilitate various operations related to Klarna payment sessions.
struct KlarnaHelpers {
    
    struct KlarnaPaymentSessionParams {
        var paymentMethodConfigId: String
        var sessionId: String
        var decodedJWTToken: DecodedJWTToken
    }
    
    /// - Returns the session type based on the current payment intent (vault or checkout).
    static func getSessionType() -> KlarnaSessionType {
        if PrimerInternal.shared.intent == .vault {
            return .recurringPayment
        } else {
            return .oneOffPayment
        }
    }
    
    /// - Constructs the request body for finalize a Klarna payment session
    /// - Returns: An instance of Request.Body.Klarna.FinalizePaymentSession
    static func getKlarnaFinalizePaymentBody(
        with paymentMethodConfigId: String,
        sessionId: String
    ) -> Request.Body.Klarna.FinalizePaymentSession {
        return Request.Body.Klarna.FinalizePaymentSession(
            paymentMethodConfigId: paymentMethodConfigId,
            sessionId: sessionId)
    }
    
    /// - Constructs the request body for creating a Klarna customer token.
    /// - Returns: An instance of Request.Body.Klarna.CreateCustomerToken
    static func getKlarnaCustomerTokenBody(
        with paymentMethodConfigId: String,
        sessionId: String,
        authorizationToken: String,
        recurringPaymentDescription: String?
    ) -> Request.Body.Klarna.CreateCustomerToken {
        return Request.Body.Klarna.CreateCustomerToken(
            paymentMethodConfigId: paymentMethodConfigId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            description: recurringPaymentDescription,
            localeData: PrimerSettings.current.localeData)
    }
    
    /// - Prepares the request body for creating a Klarna payment session.
    /// - Returns: An instance of Request.Body.Klarna.CreatePaymentSession
    static func getKlarnaPaymentSessionBody(
        with paymentMethodConfigId: String,
        clientSession: ClientSession.APIResponse?,
        recurringPaymentDescription: String?,
        redirectUrl: String?) -> Request.Body.Klarna.CreatePaymentSession {
            
            let sessionType = getSessionType()
            let localeData = constructLocaleData(using: clientSession)
            var orderItems: [Request.Body.Klarna.OrderItem]? = nil
            var totalAmount: Int? = nil
            var billingAddress: Response.Body.Klarna.BillingAddress? = nil
            var shippingAddress: Response.Body.Klarna.BillingAddress? = nil
            var description: String? = nil
            var redUrl: String? = nil
            
            switch sessionType {
            case .oneOffPayment:
                // Configure fields specific to one-off payments.
                orderItems = clientSession?.order?.lineItems?.compactMap({ getOrderItem(from: $0) })
                let surcharge = getSurcharge(fees: clientSession?.order?.fees)
                orderItems = addedSurchargeItem(to: orderItems ?? [], surcharge: surcharge)
                totalAmount = clientSession?.order?.totalOrderAmount
                billingAddress = getCustomerAddress(of: .billing, clientSession: clientSession)
                shippingAddress = getCustomerAddress(of: .shipping, clientSession: clientSession)
            case .recurringPayment:
                // Configure fields specific to recurring payments.
                description = recurringPaymentDescription
                redUrl = redirectUrl
            }
            
            return Request.Body.Klarna.CreatePaymentSession(
                paymentMethodConfigId: paymentMethodConfigId,
                sessionType: sessionType,
                localeData: localeData,
                description: description,
                redirectUrl: redUrl,
                totalAmount: totalAmount,
                orderItems: orderItems,
                billingAddress: billingAddress,
                shippingAddress: shippingAddress)
        }
    
    /// - Returns a customer's address, either billing or shipping, based on the specified type.
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
    
    /// - Converts a 'ClientSession.Order.LineItem' from the client session into a 'Request.Body.Klarna.OrderItem'.
    /// - Returns: An instance of Request.Body.Klarna.OrderItem
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
    
    /// - Converts a 'Response.Body.Klarna.SessionData' from the tokenize session into a 'Response.Body.Klarna.AuthorizationSessionData'.
    /// - Returns: An instance of Response.Body.Klarna.AuthorizationSessionData
    static func getAuthorizationSessionData(from sessionData: Response.Body.Klarna.SessionData) -> Response.Body.Klarna.AuthorizationSessionData {
        Response.Body.Klarna.AuthorizationSessionData(
            purchaseCountry: sessionData.purchaseCountry,
            purchaseCurrency: sessionData.purchaseCurrency,
            locale: sessionData.locale,
            orderLines: sessionData.orderLines,
            billingAddress: sessionData.billingAddress,
            shippingAddress: sessionData.shippingAddress)
    }
    
    /// - Adds a surcharge item to the list of order items if applicable.
    /// - Returns an array of Request.Body.Klarna.OrderItem
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
    
    /// - Returns the surcharge value from the order fees if any
    static func getSurcharge(fees: [ClientSession.Order.Fee]?) -> Int? {
        if let fees { return fees.first(where:{ $0.type == .surcharge })?.amount }
        return nil
    }
    
    /// - Helper function to construct locale data.
    private static func constructLocaleData(using clientSession: ClientSession.APIResponse?) -> Request.Body.Klarna.KlarnaLocaleData {
        let countryCode = clientSession?.order?.countryCode?.rawValue ?? ""
        let currencyCode = clientSession?.order?.currencyCode?.code ?? ""
        let localeCode = PrimerSettings.current.localeData.localeCode
        
        return Request.Body.Klarna.KlarnaLocaleData(
            countryCode: countryCode,
            currencyCode: currencyCode,
            localeCode: localeCode)
    }
    
}
