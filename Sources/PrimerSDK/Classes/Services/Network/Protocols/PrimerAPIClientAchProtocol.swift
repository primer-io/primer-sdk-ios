//
//  PrimerAPIClientAchProtocol.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 23.07.2024.
//

import Foundation

protocol PrimerAPIClientAchProtocol {

    // MARK: ACH SDK Complete Payment

    func completePayment(
        clientToken: DecodedJWTToken,
        url: URL,
        paymentRequest: Request.Body.Payment.Complete,
        completion: @escaping APICompletion<Response.Body.Complete>)
}
