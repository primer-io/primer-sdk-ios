//
//  PrimerLogger+RemoteLogging.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

public extension PrimerLogger {
    func error(
        message: String,
        error: Error,
        userInfo: [String: Any]? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        self.error(message: message, userInfo: nil, file: file, line: line, function: function)

        if #available(iOS 15.0, *) {
            let userInfo = RemoteLogContext.shared.merged(into: userInfo)
            Task { [error, userInfo, message] in
                await LoggingService.shared.logErrorIfReportable(error, message: message, userInfo: userInfo)
            }
        }
    }

    @available(iOS 15.0, *)
    func info(
        message: String,
        event: String,
        userInfo: [String: Any]? = nil
    ) {
        let userInfo = RemoteLogContext.shared.merged(into: userInfo)
        Task { [message, event, userInfo] in
            await LoggingService.shared.logInfo(message: message, event: event, userInfo: userInfo)
        }
    }
}

extension PrimerLogger {
    @available(iOS 15.0, *)
    func warn(
        message: String,
        event: String,
        userInfo: [String: Any]? = nil
    ) {
        let userInfo = RemoteLogContext.shared.merged(into: userInfo)
        Task { [message, event, userInfo] in
            await LoggingService.shared.logWarning(message: message, event: event, userInfo: userInfo)
        }
    }
}
