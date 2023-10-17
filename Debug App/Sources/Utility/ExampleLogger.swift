//
//  ExampleLogger.swift
//  Debug App
//
//  Created by Jack Newcombe on 13/09/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK
import OSLog

class ExampleLogger: PrimerLogger {
    
    private let defaultLogger = os.Logger()
    
    private var categoryLoggers = [String: Logger]()
    
    func log(level: PrimerSDK.LogLevel, message: String, userInfo: Encodable?, metadata: PrimerSDK.PrimerLogMetadata) {
        let logger: Logger
        
        if let userInfoDict = userInfo as? [String: Any?],
            let category = userInfoDict["category"] as? String {
            logger = self.logger(for: category)
        } else {
            logger = defaultLogger
        }
        
        switch level {
        case .debug:
            logger.debug("💰\(message)")
        case .info:
            logger.info("💰\(message)")
        case .warning:
            logger.warning("💰\(message)")
        case .error:
            logger.error("💰\(message)")
        }
    }
    
    private func logger(for category: String) -> Logger {
        if let existingLogger = categoryLoggers[category] {
            return existingLogger
        }
        
        let subsystem = Bundle.main.bundleIdentifier ?? "PrimerSDK"
        let logger = Logger.init(subsystem: subsystem, category: category)
        categoryLoggers[category] = logger
        return logger
    }
}
