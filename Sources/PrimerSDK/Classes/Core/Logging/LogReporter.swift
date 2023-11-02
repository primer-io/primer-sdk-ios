//
//  LogReporter.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 31/10/2023.
//

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


