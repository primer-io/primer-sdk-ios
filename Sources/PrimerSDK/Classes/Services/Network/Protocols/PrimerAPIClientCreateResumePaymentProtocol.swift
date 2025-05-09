//
//  PrimerAPIClientCreateResumePaymentProtocol.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 05/08/24.
//

import Foundation

protocol PrimerAPIClientCreateResumePaymentProtocol {
    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create,
        completion: @escaping APICompletion<Response.Body.Payment>
    )

    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create
    ) async throws -> Response.Body.Payment

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume,
        completion: @escaping APICompletion<Response.Body.Payment>
    )

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume
    ) async throws -> Response.Body.Payment

    func completePayment(
        clientToken: DecodedJWTToken,
        url: URL,
        paymentRequest: Request.Body.Payment.Complete,
        completion: @escaping APICompletion<Response.Body.Complete>
    )

    func completePayment(
        clientToken: DecodedJWTToken,
        url: URL,
        paymentRequest: Request.Body.Payment.Complete
    ) async throws -> Response.Body.Complete
}
