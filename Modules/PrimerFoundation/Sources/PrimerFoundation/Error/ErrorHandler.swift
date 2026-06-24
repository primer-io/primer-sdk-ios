//
//  ErrorHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@_spi(PrimerInternal) public final class ErrorHandler: LogReporter {
    
    public static var fire: ((Error) -> Void)?

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

        // Check if error should be filtered from server reporting
        if shouldFilterError(error) {
            logger.warn(message: "Integration issue: \(error.localizedDescription)")
            return
        }

        Self.fire?(error)
    }

    private func shouldFilterError(_ error: Error) -> Bool {
        guard let primerError = error as? PrimerError else {
            return false
        }

        // Filter out non-actionable errors (merchant integration issues, not SDK bugs)
        switch primerError {
        case .applePayNoCardsInWallet,
             .applePayDeviceNotSupported,
             .unableToPresentPaymentMethod:
            return true
        default:
            return false
        }
    }
}
