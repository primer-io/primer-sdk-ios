//
//  PrimerAPIClientPayPalProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

protocol PrimerAPIClientPayPalProtocol {

    func createPayPalOrderSession(
        clientToken: DecodedJWTToken,
        payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
        completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>)

    func createPayPalOrderSession(
        clientToken: DecodedJWTToken,
        payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder
    ) async throws -> Response.Body.PayPal.CreateOrder

    func createPayPalBillingAgreementSession(
        clientToken: DecodedJWTToken,
        payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
        completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>)

    func createPayPalBillingAgreementSession(
        clientToken: DecodedJWTToken,
        payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement
    ) async throws -> Response.Body.PayPal.CreateBillingAgreement

    func confirmPayPalBillingAgreement(
        clientToken: DecodedJWTToken,
        payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
        completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>)

    func confirmPayPalBillingAgreement(
        clientToken: DecodedJWTToken,
        payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement
    ) async throws -> Response.Body.PayPal.ConfirmBillingAgreement

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>)

    func fetchPayPalExternalPayerInfo(
        clientToken: DecodedJWTToken,
        payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo
    ) async throws -> Response.Body.PayPal.PayerInfo

}
