//
//  UnifiedLoggingService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
actor UnifiedLoggingService: LogReporter {

    // MARK: - Singleton

    static let shared = UnifiedLoggingService()

    // MARK: - Private Properties

    private var loggingService: LoggingService?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func logErrorIfReportable(_ error: Error, message: String? = nil, userInfo: [String: Any]? = nil) async {
        // Check if error should be reported to Datadog
        guard error.shouldReportToDatadog else {
            Self.logger.debug(message: "📊 [Logging] Skipping non-reportable error: \(error)")
            return
        }

        // Resolve LoggingService if needed
        guard let service = await resolveLoggingService() else {
            Self.logger.debug(message: "📊 [Logging] LoggingService not available, skipping remote log")
            return
        }

        // Send error to Datadog
        await service.sendError(message: message, error: error, userInfo: userInfo)
    }

    func logInfo(message: String, event: String, userInfo: [String: Any]? = nil) async {
        // Resolve LoggingService if needed
        guard let service = await resolveLoggingService() else {
            Self.logger.debug(message: "📊 [Logging] LoggingService not available, skipping remote log")
            return
        }

        // Send info to Datadog
        await service.sendInfo(message: message, event: event, userInfo: userInfo)
    }

    // MARK: - Private Methods

    private func resolveLoggingService() async -> LoggingService? {
        // Return cached instance if available
        if let loggingService {
            return loggingService
        }

        // Try to resolve from DI container
        guard let container = await DIContainer.current else {
            return nil
        }

        do {
            let service = try await container.resolve(LoggingService.self)
            self.loggingService = service
            return service
        } catch {
            Self.logger.debug(message: "📊 [Logging] Failed to resolve LoggingService: \(error)")
            return nil
        }
    }

    // MARK: - Internal Methods (for testing)

    func resetForTesting() {
        loggingService = nil
    }
}
