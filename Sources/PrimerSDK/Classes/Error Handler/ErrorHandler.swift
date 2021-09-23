//
//  ErrorHandler.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

#if canImport(UIKit)

import Foundation

internal class ErrorHandler {

    static var shared = ErrorHandler()

    // swiftlint:disable cyclomatic_complexity
    func handle(error: Error) -> Bool {
        log(logLevel: .error, title: "ERROR!", message: error.localizedDescription, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)

        if let networkServiceError = error as? NetworkServiceError {
            switch networkServiceError {
            default:
                break
            }

        } else if let primerError = error as? PrimerError {
            switch primerError {
            default:
                break
            }

        } else if let klarnaException = error as? KlarnaException {
            switch klarnaException {
            default:
                break
            }

        } else {
            let nsError = error as NSError
        }

        return false
    }

}

#endif
