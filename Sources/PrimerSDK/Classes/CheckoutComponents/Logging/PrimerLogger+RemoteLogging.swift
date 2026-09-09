//
//  PrimerLogger+RemoteLogging.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

// NOTE: These overloads forward logs to the CheckoutComponents remote LoggingService,
// so they must live in the PrimerSDK target where DIContainer/LoggingService are visible.
public extension PrimerLogger {
    // NOTE: During CC payment flows, RawDataManager overwrites sdkIntegrationType to .headless.
    // This means DIContainer.current may be nil when called from the headless payment path.
    // The guard-and-return pattern below handles this gracefully.
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
            Task { [error, userInfo, message] in
                guard let container = await DIContainer.current else {
                    #if DEBUG
                    print("📊 [Logging] DIContainer not available for remote logging")
                    #endif
                    return
                }
                guard let service = try? await container.resolve(LoggingService.self) else {
                    #if DEBUG
                    print("📊 [Logging] LoggingService not resolved for remote logging")
                    #endif
                    return
                }
                await service.logErrorIfReportable(error, message: message, userInfo: userInfo)
            }
        }
    }

    @available(iOS 15.0, *)
    func info(
        message: String,
        event: String,
        userInfo: [String: Any]? = nil
    ) {
        Task { [message, event, userInfo] in
            guard let container = await DIContainer.current else {
                #if DEBUG
                print("📊 [Logging] DIContainer not available for remote logging")
                #endif
                return
            }
            guard let service = try? await container.resolve(LoggingService.self) else {
                #if DEBUG
                print("📊 [Logging] LoggingService not resolved for remote logging")
                #endif
                return
            }
            await service.logInfo(message: message, event: event, userInfo: userInfo)
        }
    }
}
