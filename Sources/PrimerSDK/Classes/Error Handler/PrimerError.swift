//
//  PrimerError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

func handled<E: Error>(
    error: E,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) -> E {
    ErrorHandler.handle(error: error, file: file, line: line, function: function)
    return error
}

func handled(
    primerError: PrimerError,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) -> PrimerError {
    handled(error: primerError, file: file, line: line, function: function)
}

func handled(
    internalError: InternalError,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) -> InternalError {
    handled(error: internalError, file: file, line: line, function: function)
}

func handled(
    primerValidationError: PrimerValidationError,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) -> PrimerValidationError {
    handled(error: primerValidationError, file: file, line: line, function: function)
}
