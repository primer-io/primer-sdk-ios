//
//  ErrorHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public protocol ErrorEventReporting: Sendable {
    func reportError(_ error: Error)
}

public final class ErrorHandler: LogReporter {

    public static var eventReporter: ErrorEventReporting?

    // Call this function to log any error to Analytics
    public static func handle(
        error: Error,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        ErrorHandler.shared.handle(error: error, file: file, line: line, function: function)
    }

    public static var shared = ErrorHandler()

    public func handle(
        error: Error,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        self.logger.error(message: error.localizedDescription, file: file, line: line, function: function)
        Self.eventReporter?.reportError(error)
    }
}
