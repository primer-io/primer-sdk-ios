//
//  CreateResumePaymentService.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 24/02/22.
//

import Foundation

internal protocol CreateResumePaymentServiceProtocol {
    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment>
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
}
