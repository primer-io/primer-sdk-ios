//
//  GetPaymentMethodsInteractor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Protocol for retrieving available payment methods.
protocol GetPaymentMethodsInteractor {
    /// Fetches available payment methods for the current session.
    func execute() async throws -> [InternalPaymentMethod]
}

/// Default implementation of GetPaymentMethodsInteractor.
final class GetPaymentMethodsInteractorImpl: GetPaymentMethodsInteractor, LogReporter {

    private let repository: HeadlessRepository

    init(repository: HeadlessRepository) {
        self.repository = repository
    }

    func execute() async throws -> [InternalPaymentMethod] {
        logger.info(message: "Fetching available payment methods")
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let paymentMethods = try await repository.getPaymentMethods()
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            logger.info(message: "[PERF] Retrieved \(paymentMethods.count) payment methods in \(String(format: "%.0f", duration))ms")
            return paymentMethods
        } catch {
            logger.error(message: "Failed to fetch payment methods: \(error)")
            throw error
        }
    }
}
