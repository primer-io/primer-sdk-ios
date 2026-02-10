//
//  Logger.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import OSLog

final class Logger: Sendable {
    func info(_ message: String) {
        guard #available(iOS 14, *) else { return print(message) }
        let logger = os.Logger(subsystem: "PrimerBDC", category: "Orchestrator")
        logger.info("\(message)")
    }
    
    func error(_ message: String) {
        guard #available(iOS 14, *) else { return print(message) }
        let logger = os.Logger(subsystem: "PrimerBDC", category: "Orchestrator")
        logger.error("\(message)")
    }
}
