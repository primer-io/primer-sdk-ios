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

    let apiClient: PrimerAPIClientProtocol

    let paymentMethodType: String

    init(paymentMethodType: String,
         apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
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
                    seal.reject(self.error(forCallType: .create, withError: error as? (any PrimerErrorProtocol)))
                case .success(let paymentResponse):
                    do {
                        try self.validateResponse(paymentResponse: paymentResponse, callType: "create")
                        seal.fulfill(paymentResponse)
                    } catch {
                        seal.reject(error)
                    }
                }
            }
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
                    seal.reject(self.error(forCallType: .resume, withError: error as? (any PrimerErrorProtocol)))
                case .success(let paymentResponse):
                    do {
                        try self.validateResponse(paymentResponse: paymentResponse, callType: "resume")
                        seal.fulfill(paymentResponse)
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
    }

    // MARK: Helpers

    private func error(forCallType callType: CreateResumePaymentCallType, 
                       withError error: (any PrimerErrorProtocol)?) -> Error {
        switch callType {
        case .create:
            return PrimerError.failedToCreatePayment(paymentMethodType: paymentMethodType,
                                                     description: error?.errorDescription ?? "Failed to create payment",
                                                     userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
        case .resume:
            return PrimerError.failedToResumePayment(paymentMethodType: paymentMethodType,
                                                     description: error?.errorDescription ?? "Failed to resume payment",
                                                     userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
        }
    }

    private func validateResponse(paymentResponse: Response.Body.Payment, callType: String) throws {
        if paymentResponse.id == nil || paymentResponse.status == .failed {
            let err = PrimerError.paymentFailed(
                paymentMethodType: self.paymentMethodType,
                paymentId: paymentResponse.id ?? "unknown",
                status: paymentResponse.status.rawValue,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err

        }
    }
}
