//
//  PrimerInternalError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

extension InternalError: PrimerErrorProtocol {
    public var exposedError: Error {
        switch self {
        case let .failedToPerform3dsButShouldContinue(error): error.normalizedForSDK
        case let .failedToPerform3dsAndShouldBreak(error): error.normalizedForSDK
        case .serverError: shouldExposeServerError ? self : PrimerError.unknown(diagnosticsId: diagnosticsId)
        default: PrimerError.unknown(diagnosticsId: diagnosticsId)
        }
    }
}

private extension InternalError {
    var shouldExposeServerError: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
