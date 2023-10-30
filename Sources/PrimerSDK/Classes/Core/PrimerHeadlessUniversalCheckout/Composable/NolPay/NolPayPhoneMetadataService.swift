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
    func getPhoneMetadata(mobileNumber: String, completion: @escaping PhoneMetadataCompletion) {
        
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

        let requestBody = Request.Body.PhoneMetadata.PhoneMetadataDataRequest(phoneNumber: mobileNumber)
        let client = PrimerAPIClient()
        client.getPhoneMetadata(clientToken: clientToken, paymentRequestBody: requestBody) { result in

            switch result {
            case .success(let phoneMedatadaResponse):
                let countryCode = phoneMedatadaResponse.countryCode
                let mobileNumber = phoneMedatadaResponse.nationalNumber
                if phoneMedatadaResponse.isValid {
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
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: primerError)

                completion(.failure(primerError))
            }
        }
    }
}
