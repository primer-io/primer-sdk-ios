//
//  LogReporter.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

private let silentLogger = DefaultLogger(logLevel: .none)

public protocol LogReporter {}
extension LogReporter {

    public var logger: PrimerLogger {
        PrimerLogging.shared.logger
    }

    public static var logger: PrimerLogger {
        PrimerLogging.shared.logger
    }
}
