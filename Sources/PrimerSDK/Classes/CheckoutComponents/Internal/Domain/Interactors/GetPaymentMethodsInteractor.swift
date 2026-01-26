//
//  GetPaymentMethodsInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol GetPaymentMethodsInteractor {
    func execute() async throws -> [InternalPaymentMethod]
}

final class GetPaymentMethodsInteractorImpl: GetPaymentMethodsInteractor, LogReporter {

    private let repository: HeadlessRepository
    private let loggingInteractor: (any LoggingInteractor)?

    init(repository: HeadlessRepository, loggingInteractor: (any LoggingInteractor)? = nil) {
        self.repository = repository
        self.loggingInteractor = loggingInteractor
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
            loggingInteractor?.logError(message: "Failed to load payment methods", error: error)
            throw error
        }
    }
}
