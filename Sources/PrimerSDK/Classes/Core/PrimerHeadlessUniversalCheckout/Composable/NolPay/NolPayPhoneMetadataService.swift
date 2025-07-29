//
//  NolPayPhoneMetadataService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
                return completion(.failure(handled(primerError: .invalidClientToken())))
            }

            guard !mobileNumber.isEmpty else {
                let validationError = handled(error: PrimerValidationError.invalidPhoneNumber(message: "Phone number cannot be blank."))
                return completion(.success((.invalid(errors: [validationError]), nil, nil)))
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
                        let error = handled(error: PrimerValidationError.invalidPhoneNumber(message: "Phone number is not valid."))
                        completion(.success((.invalid(errors: [error]), nil, nil)))
                    }
                case .failure(let error):
                    completion(.failure(handled(primerError: .underlyingErrors(errors: [error]))))
                }
            }
        }
    }
}

// swiftlint:enable large_tuple
// swiftlint:enable function_body_length
