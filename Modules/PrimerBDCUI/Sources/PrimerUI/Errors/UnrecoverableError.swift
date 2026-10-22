//
//  UnrecoverableError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

enum UnrecoverableError: Error {
    case unexpectedNilComponentID

    var message: String {
        switch self {
        case .unexpectedNilComponentID: "Component is missing an 'id' — dropping the interaction"
        }
    }
}

func unrecoverableError(_ error: UnrecoverableError) {
    log(error.message, type: .error)
    assertionFailure(error.message)
}
