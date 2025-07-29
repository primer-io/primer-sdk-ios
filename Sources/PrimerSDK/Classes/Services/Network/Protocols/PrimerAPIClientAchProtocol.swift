//
//  PrimerAPIClientAchProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol PrimerAPIClientAchProtocol {

    // MARK: ACH SDK Complete Payment

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
