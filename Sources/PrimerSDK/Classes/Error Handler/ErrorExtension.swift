//
//  ErrorExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension Array where Element == Error {

    var combinedDescription: String {
        var message: String = ""

        self.forEach { err in
            if let primerError = err as? (any PrimerErrorProtocol) {
                message += "\(primerError.localizedDescription) | "
            } else {
                let nsErr = err as NSError
                message += "Domain: \(nsErr.domain), Code: \(nsErr.code), Description: \(nsErr.localizedDescription) | "
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
            // Handle empty underlyingErrors case
            if case .underlyingErrors(let errors, _) = primerErr, errors.isEmpty {
                return PrimerError.unknown(message: "Empty underlying errors", diagnosticsId: .uuid)
            }
            // Return PrimerError as-is, including underlyingErrors
            return primerErr
        } else if let validationErr = self as? PrimerValidationError {
            return validationErr
        } else {
            // For unknown errors, wrap in unknown error (not underlyingErrors)
            return PrimerError.unknown(message: self.localizedDescription, diagnosticsId: .uuid)
        }
    }
}
