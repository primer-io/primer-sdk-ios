//
//  Logger.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import OSLog

func log(_ message: String, type: OSLogType = .debug) {
    switch type {
    case .debug: Logger.debug(message)
    case .error: Logger.error(message)
    case .info: Logger.info(message)
    default: fatalError("Not implemented")
    }
}

private final class Logger: Sendable {
    static func debug(_ message: String) {
        guard #available(iOS 14, *) else { return print(message) }
        let logger = os.Logger(subsystem: "PrimerBDC", category: "UI")
        logger.debug("\(message)")
    }
	
    static func error(_ message: String) {
        guard #available(iOS 14, *) else { return print(message) }
        let logger = os.Logger(subsystem: "PrimerBDC", category: "UI")
        logger.error("\(message)")
    }
    
    static func info(_ message: String ) {
        guard #available(iOS 14, *) else { return print(message) }
        let logger = os.Logger(subsystem: "PrimerBDC", category: "UI")
        logger.info("\(message)")
    }
}
