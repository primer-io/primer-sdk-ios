//
//  PrimerLogging.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

private let silentLogger = DefaultLogger(logLevel: .none)

public final class PrimerLogging {
    public static let shared = PrimerLogging()

    private init() {}

    public var logger: PrimerLogger = silentLogger
}
