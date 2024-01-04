//
//  NolPayPhoneMetadataService.swift
//  PrimerSDK
//
//  Created by Boris on 27.10.23..
//

import Foundation

typealias PhoneMetadataCompletion = (Result<(PrimerValidationStatus, String?, String?), PrimerError>) -> Void

protocol NolPayPhoneMetadataProviding {
    func getPhoneMetadata(mobileNumber: String, completion: @escaping PhoneMetadataCompletion)
}

struct NolPayPhoneMetadataService: NolPayPhoneMetadataProviding {
    var debouncer = Debouncer(delay: 0.275)

    func getPhoneMetadata(mobileNumber: String, completion: @escaping PhoneMetadataCompletion) {

        debouncer.debounce {
            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                    "class": "\(Self.self)",
                                                                    "function": #function,
                                                                    "line": "\(#line)"],
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            guard !mobileNumber.isEmpty else {
                let validationError = PrimerValidationError.invalidPhoneNumber(
                    message: "Phone number cannot be blank.",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: validationError)

                completion(.success((.invalid(errors: [validationError]), nil, nil)))
                return
            }

            let urlSessionConfiguration = URLSessionConfiguration.default
            urlSessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
            let urlSession = URLSession(configuration: urlSessionConfiguration)
            let networkService = URLSessionStack(session: urlSession)
            let client = PrimerAPIClient(networkService: networkService)

            let requestBody = Request.Body.PhoneMetadata.PhoneMetadataDataRequest(phoneNumber: mobileNumber)
            client.getPhoneMetadata(clientToken: clientToken, paymentRequestBody: requestBody) { result in

                switch result {
                case .success(let phoneMetadataResponse):
                    let countryCode = phoneMetadataResponse.countryCode
                    let mobileNumber = phoneMetadataResponse.nationalNumber
                    if phoneMetadataResponse.isValid {
                        completion(.success((.valid, countryCode, mobileNumber)))
                    } else {
                        let validationError = PrimerValidationError.invalidPhoneNumber(
                            message: "Phone number is not valid.",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: validationError)

                        completion(.success((.invalid(errors: [validationError]), nil, nil)))
                    }
                case .failure(let error):
                    let primerError = PrimerError.underlyingErrors(
                        errors: [error],
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: primerError)

                    completion(.failure(primerError))
                }
            }
        }
    }
}
