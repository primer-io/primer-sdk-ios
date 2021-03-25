//
//  ErrorHandler.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

#if canImport(UIKit)

import Foundation

class ErrorHandler {

    static var shared = ErrorHandler()

    func handle(error: Error) -> Bool {
        log(logLevel: .error, title: "ERROR!", message: error.localizedDescription, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)

        if let networkServiceError = error as? NetworkServiceError {
            switch networkServiceError {
            case .invalidURL:
                // Internal error, the URL wasn't formed correctly.
                // Present generic error
                break
            case .unauthorised(let info):
                break
            case .clientError(let statusCode, let info):
                break
            case .serverError(let statusCode, let info):
                break
            case .noData:
                break
            case .parsing(let error, let data):
                break
            case .underlyingError(let error):
                break
            }

        } else if let primerError = error as? PrimerError {
            switch primerError {
            case .ClientTokenNull:
                break
            case .CustomerIDNull:
                break
            case .PayPalSessionFailed:
                break
            case .VaultFetchFailed:
                break
            case .VaultDeleteFailed:
                break
            case .VaultCreateFailed:
                break
            case .DirectDebitSessionFailed:
                break
            case .ConfigFetchFailed:
                break
            case .TokenizationPreRequestFailed:
                break
            case .TokenizationRequestFailed:
                break
            }

        } else if let klarnaException = error as? KlarnaException {
            switch klarnaException {
            case .invalidUrl:
                break
            case .noToken:
                break
            case .noCoreUrl:
                break
            case .failedApiCall:
                break
            case .noAmount:
                break
            case .noCurrency:
                break
            case .noPaymentMethodConfigId:
                break
            }

        } else {
            let nsError = error as NSError
        }

        return false
    }

}

#endif
