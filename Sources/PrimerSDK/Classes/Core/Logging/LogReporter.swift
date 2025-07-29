//
//  LogReporter.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

private let silentLogger = DefaultLogger(logLevel: .none)

protocol LogReporter {}
extension LogReporter {

    var logger: PrimerLogger {
        return PrimerLogging.shared.logger
    }

    static var logger: PrimerLogger {
        return PrimerLogging.shared.logger
    }
}
