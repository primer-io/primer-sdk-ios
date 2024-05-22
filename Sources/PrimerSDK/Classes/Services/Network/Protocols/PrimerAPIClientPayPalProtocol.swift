//
//  PrimerAPIClientPayPalProtocol.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 22/05/2024.
//

import Foundation

protocol PrimerAPIClientPayPalProtocol {
    
    func createPayPalOrderSession(
        clientToken: DecodedJWTToken,
        payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
        completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>)

    func createPayPalBillingAgreementSession(
        clientToken: DecodedJWTToken,
        payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
        completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>)

    func confirmPayPalBillingAgreement(
        clientToken: DecodedJWTToken,
        payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
        completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>)

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>)
}
