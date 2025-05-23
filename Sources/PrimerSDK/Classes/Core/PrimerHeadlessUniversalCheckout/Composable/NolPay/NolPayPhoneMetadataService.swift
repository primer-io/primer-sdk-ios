//
//  NolPayPhoneMetadataService.swift
//  PrimerSDK
//
//  Created by Boris on 27.10.23..
//

// swiftlint:disable function_body_length
// swiftlint:disable large_tuple

import Foundation

typealias PhoneMetadataCompletion = (Result<(PrimerValidationStatus, String?, String?), PrimerError>) -> Void

protocol NolPayPhoneMetadataServiceProtocol {
    func getPhoneMetadata(mobileNumber: String, completion: @escaping PhoneMetadataCompletion)
}

final class NolPayPhoneMetadataService: NolPayPhoneMetadataServiceProtocol {
    let apiClient: PrimerAPIClientProtocol
    private let debouncer = Debouncer(delay: 0.275)

    init(apiClient: PrimerAPIClientProtocol? = nil) {
        if let apiClient {
            self.apiClient = apiClient
        } else {
            let urlSessionConfiguration = URLSessionConfiguration.default
            urlSessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
            let urlSession = URLSession(configuration: urlSessionConfiguration)
            let networkService = DefaultNetworkService(withUrlSession: urlSession)
            self.apiClient = PrimerAPIClient(networkService: networkService)
        }
    }

    func getPhoneMetadata(mobileNumber: String, completion: @escaping PhoneMetadataCompletion) {
        debouncer.debounce {
            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }

            guard !mobileNumber.isEmpty else {
                let validationError = PrimerValidationError.invalidPhoneNumber(
                    message: "Phone number cannot be blank.",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: validationError)

                completion(.success((.invalid(errors: [validationError]), nil, nil)))
                return
            }

            let requestBody = Request.Body.PhoneMetadata.PhoneMetadataDataRequest(phoneNumber: mobileNumber)
            self.apiClient.getPhoneMetadata(clientToken: clientToken, paymentRequestBody: requestBody) { result in

                switch result {
                case .success(let phoneMetadataResponse):
                    let countryCode = phoneMetadataResponse.countryCode
                    let mobileNumber = phoneMetadataResponse.nationalNumber
                    if phoneMetadataResponse.isValid {
                        completion(.success((.valid, countryCode, mobileNumber)))
                    } else {
                        let validationError = PrimerValidationError.invalidPhoneNumber(
                            message: "Phone number is not valid.",
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString
                        )
                        ErrorHandler.handle(error: validationError)

                        completion(.success((.invalid(errors: [validationError]), nil, nil)))
                    }
                case .failure(let error):
                    let primerError = PrimerError.underlyingErrors(
                        errors: [error],
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: primerError)

                    completion(.failure(primerError))
                }
            }
        }
    }
}

// swiftlint:enable large_tuple
// swiftlint:enable function_body_length
