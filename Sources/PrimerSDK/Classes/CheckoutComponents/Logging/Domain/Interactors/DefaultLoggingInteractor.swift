//
//  DefaultLoggingInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

final class DefaultLoggingInteractor {
    // MARK: - Constants

    private enum Constants {
        static let checkoutInitialized = "Checkout initialized"
    }

    // MARK: - Dependencies

    private let loggingService: LoggingService

    // MARK: - Initialization

    init(loggingService: LoggingService) {
        self.loggingService = loggingService
    }

    // MARK: - Public Methods

    func logInfo(event: String, initDurationMs: Int? = nil) {
        let message = initDurationMs.map { "\(Constants.checkoutInitialized) (\($0)ms)" } ?? Constants.checkoutInitialized

        Task { [self] in
            await loggingService.sendInfo(
                message: message,
                event: event,
                initDurationMs: initDurationMs
            )
        }
    }

    func logError(message: String, error: Error) {
        Task { [self] in
            await loggingService.sendError(
                message: message,
                error: error
            )
        }
    }
}
