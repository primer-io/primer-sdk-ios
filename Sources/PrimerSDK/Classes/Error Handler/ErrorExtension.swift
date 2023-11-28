//
//  ErrorExtension.swift
//  PrimerSDK
//
//  Created by Boris on 19.9.23..
//

import Foundation

extension Array where Element == Error {

    var combinedDescription: String {
        var message: String = ""

        self.forEach { err in
            if let primerError = err as? PrimerErrorProtocol {
                message += "\(primerError.localizedDescription) | "
            } else {
                let nsErr = err as NSError
                message += "Domain: \(nsErr.domain), Code: \(nsErr.code), Description: \(nsErr.localizedDescription)  | "
            }
        }

        if message.hasSuffix(" | ") {
            message = String(message.dropLast(3))
        }

        return "[\(message)]"
    }
}

extension Error {

    var primerError: Error {
        if let internalErr = self as? InternalError {
            return internalErr.exposedError
        } else if let primer3DSErr = self as? Primer3DSErrorContainer {
            return primer3DSErr
        } else if let primerErr = self as? PrimerError {
            switch primerErr {
            case .underlyingErrors(let errors, _, _):
                if errors.isEmpty {
                    let unknownErr = PrimerError.unknown(
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    return unknownErr
                } else if errors.count == 1 {
                    return errors.first!.primerError
                } else {
                    return primerErr
                }
            default:
                return primerErr
            }
        } else if let validationErr = self as? PrimerValidationError {
            return validationErr
        } else {
            let primerErr = PrimerError.underlyingErrors(
                errors: [self],
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            return primerErr
        }
    }
}
