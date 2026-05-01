//
//  ErrorExtension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

extension Error {

    var normalizedForSDK: Error {
        if let internalErr = self as? InternalError {
            return internalErr.exposedError
        } else if let primer3DSErr = self as? Primer3DSErrorContainer {
            return primer3DSErr
        } else if let primerErr = self as? PrimerError {
            // Handle empty underlyingErrors case
            if case let .underlyingErrors(errors, _) = primerErr, errors.isEmpty {
                return PrimerError.unknown(message: "Empty underlying errors")
            }
            // Return PrimerError as-is, including underlyingErrors
            return primerErr
        } else if let validationErr = self as? PrimerValidationError {
            return validationErr
        } else {
            // For unknown errors, wrap in unknown error (not underlyingErrors)
            return PrimerError.unknown(message: self.localizedDescription)
        }
    }

    /// Converts any error to a PrimerError, using the primerError computed property first
    /// and casting to PrimerError with a fallback to PrimerError.unknown
    var asPrimerError: PrimerError {
        let baseError = self.normalizedForSDK
        return (baseError as? PrimerError) ?? PrimerError.unknown(message: baseError.localizedDescription)
    }

    /// Converts any error to a PrimerErrorProtocol, using the primerError computed property first
    /// and casting to PrimerErrorProtocol with a fallback to PrimerError.unknown
    var asPrimerErrorProtocol: any PrimerErrorProtocol {
        let baseError = self.normalizedForSDK
        return (baseError as? PrimerErrorProtocol) ?? PrimerError.unknown(message: baseError.localizedDescription)
    }
}
