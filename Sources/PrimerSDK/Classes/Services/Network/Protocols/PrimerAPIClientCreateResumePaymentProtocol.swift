//
//  PrimerAPIClientCreateResumePaymentProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

protocol PrimerAPIClientCreateResumePaymentProtocol {
    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create,
        completion: @escaping APICompletion<Response.Body.Payment>)

    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create
    ) async throws -> Response.Body.Payment

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume,
        completion: @escaping APICompletion<Response.Body.Payment>)

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume
    ) async throws -> Response.Body.Payment

    func completePayment(
        clientToken: DecodedJWTToken,
        url: URL,
        paymentRequest: Request.Body.Payment.Complete,
        completion: @escaping APICompletion<Response.Body.Complete>)

    func completePayment(
        clientToken: DecodedJWTToken,
        url: URL,
        paymentRequest: Request.Body.Payment.Complete
    ) async throws -> Response.Body.Complete
}
