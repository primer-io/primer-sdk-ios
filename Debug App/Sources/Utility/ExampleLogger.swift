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

@available(iOS 14.0, *)
class ExampleOSLogger: PrimerLogger {
    
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

class ExampleLogger: PrimerLogger {
        
    func log(level: LogLevel, message: String, userInfo: Encodable?, metadata: PrimerLogMetadata) {
        print("💰" + format(level: level, message: message, metadata: metadata))
        if let userInfoMessage = try? userInfo?.asDictionary() {
            print("💰" + format(level: level, message: userInfoMessage.debugDescription, metadata: metadata))
        }
    }
    
    private func format(level: LogLevel, message: String, metadata: PrimerLogMetadata) -> String {
        let filename = metadata.file.split(separator: "/").last
        return "\(level.prefix) [\(filename != nil ? String(filename!) : metadata.file):\(metadata.line) → \(metadata.function)] \(message)"
    }
}
