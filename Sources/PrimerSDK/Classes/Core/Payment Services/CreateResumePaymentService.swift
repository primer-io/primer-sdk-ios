//
//  CreateResumePaymentService.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 24/02/22.
//

import Foundation

internal protocol CreateResumePaymentServiceProtocol {
    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment>
    func completePayment(clientToken: DecodedJWTToken, completeUrl: URL) -> Promise<Void>
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) -> Promise<Response.Body.Payment>
}

private enum CreateResumePaymentCallType: String {
    case create
    case resume
}

internal class CreateResumePaymentService: CreateResumePaymentServiceProtocol {

    let apiClient: PrimerAPIClientCreateResumePaymentProtocol

    let paymentMethodType: String

    init(paymentMethodType: String,
         apiClient: PrimerAPIClientCreateResumePaymentProtocol = PrimerAPIClient()) {
        self.paymentMethodType = paymentMethodType
        self.apiClient = apiClient
    }

    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment> {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return Promise(error: err)
        }

        return Promise { seal in
            self.apiClient.createPayment(clientToken: clientToken,
                                         paymentRequestBody: paymentRequest) { result in
                switch result {
                case .failure(let error):
                    seal.reject(error)
                case .success(let paymentResponse):
                    do {
                        try self.validateResponse(paymentResponse: paymentResponse, callType: .create)
                        seal.fulfill(paymentResponse)
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
    }

    private func validateResponse(paymentResponse: Response.Body.Payment, callType: CreateResumePaymentCallType) throws {

        if paymentResponse.id == nil || paymentResponse.status == .failed ||
            (callType == .resume && paymentResponse.status == .pending && paymentResponse.showSuccessCheckoutOnPendingPayment == false) {
            let err = PrimerError.paymentFailed(
                paymentMethodType: self.paymentMethodType,
                paymentId: paymentResponse.id ?? "unknown",
                orderId: paymentResponse.orderId ?? nil,
                status: paymentResponse.status.rawValue,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) -> Promise<Response.Body.Payment> {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return Promise(error: err)
        }

        return Promise { seal in
            self.apiClient.resumePayment(clientToken: clientToken,
                                         paymentId: paymentId,
                                         paymentResumeRequest: paymentResumeRequest) { result in
                switch result {
                case .failure(let error):
                    seal.reject(error)
                case .success(let paymentResponse):
                    do {
                        try self.validateResponse(paymentResponse: paymentResponse, callType: .resume)
                        seal.fulfill(paymentResponse)
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
    }

    /**
     * Completes a payment using the provided JWT token and URL.
     *
     * This private method performs an API call to complete a payment, using a decoded JWT token for authentication
     * and a URL indicating where the completion request should be sent.
     *
     * - Parameters:
     *   - clientToken: A `DecodedJWTToken` representing the client's authentication token.
     *   - completeUrl: An `URL` indicating the endpoint for completing the ACH payment.
     *
     * - Returns: A `Promise<Void>` that resolves if the payment is completed successfully, or rejects if there is
     *            an error during the API call.
     */
    func completePayment(clientToken: DecodedJWTToken, completeUrl: URL) -> Promise<Void> {
        return Promise { seal in
            let timeZone = TimeZone(abbreviation: "UTC")
            let timeStamp = Date().toString(timeZone: timeZone)

            let body = Request.Body.Payment.Complete(mandateSignatureTimestamp: timeStamp)
            self.apiClient.completePayment(clientToken: clientToken, url: completeUrl, paymentRequest: body) { result in
                switch result {
                case .success:
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}
