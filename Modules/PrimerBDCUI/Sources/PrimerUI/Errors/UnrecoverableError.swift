//
//  UnrecoverableError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

enum UnrecoverableError: Error {
    case unexpectedNilComponentID
}

func unrecoverableError(_ error: UnrecoverableError) -> Never {
    fatalError(String(describing: error))
}
