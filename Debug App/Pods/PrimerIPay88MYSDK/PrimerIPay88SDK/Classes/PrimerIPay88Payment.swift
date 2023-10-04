//
//  PrimerIPay88Payment.swift
//  PrimerIPay88SDK
//
//  Created by Evangelos on 12/12/22.
//

#if canImport(UIKit)

import Foundation

public class PrimerIPay88Payment: NSObject {
    
    public internal(set) var merchantCode: String
    public internal(set) var paymentId: String
    public internal(set) var refNo: String
    public internal(set) var amount: String
    public internal(set) var currency: String
    public internal(set) var prodDesc: String
    public internal(set) var userName: String
    public internal(set) var userEmail: String
    public internal(set) var userContact: String
    public internal(set) var remark: String?
    public internal(set) var lang: String?
    public internal(set) var country: String
    public internal(set) var backendPostURL: String
    public internal(set) var appdeeplink: String?
    public internal(set) var actionType: String?
    public internal(set) var tokenId: String?
    public internal(set) var promoCode: String?
    public internal(set) var fixPaymentId: String?
    
    // Values provided by the delegates
    public internal(set) var transId: String?
    public internal(set) var authCode: String?
    
    public init(
        merchantCode: String,
        paymentId: String,
        refNo: String,
        amount: String,
        currency: String,
        prodDesc: String,
        userName: String,
        userEmail: String,
        userContact: String,
        remark: String?,
        lang: String?,
        country: String,
        backendPostURL: String,
        appdeeplink: String?,
        actionType: String?,
        tokenId: String?,
        promoCode: String?,
        fixPaymentId: String?,
        transId: String?,
        authCode: String?
    ) {
        self.merchantCode = merchantCode
        self.paymentId = paymentId
        self.refNo = refNo
        self.amount = amount
        self.currency = currency
        self.prodDesc = prodDesc
        self.userName = userName
        self.userEmail = userEmail
        self.userContact = userContact
        self.remark = remark
        self.lang = lang
        self.country = country
        self.backendPostURL = backendPostURL
        self.appdeeplink = appdeeplink
        self.actionType = actionType
        self.tokenId = tokenId
        self.promoCode = promoCode
        self.fixPaymentId = fixPaymentId
        
        self.transId = transId
        self.authCode = authCode
        
        super.init()
    }
    
    internal var iPay88Payment: IpayPayment {
        let iPay88Payment = IpayPayment()
        iPay88Payment.merchantCode = self.merchantCode
        iPay88Payment.paymentId = self.paymentId
        iPay88Payment.refNo = self.refNo
        iPay88Payment.amount = self.amount
        iPay88Payment.currency = self.currency
        iPay88Payment.prodDesc = self.prodDesc
        iPay88Payment.userName = self.userName
        iPay88Payment.userEmail = self.userEmail
        iPay88Payment.remark = self.remark
        iPay88Payment.lang = self.lang
        iPay88Payment.country = self.country
        iPay88Payment.backendPostURL = self.backendPostURL
        iPay88Payment.appdeeplink = self.appdeeplink
        iPay88Payment.actionType = self.actionType
        iPay88Payment.tokenId = ""
        iPay88Payment.promoCode = self.promoCode
        iPay88Payment.fixPaymentId = self.fixPaymentId
        
        return iPay88Payment
    }
}

#endif
