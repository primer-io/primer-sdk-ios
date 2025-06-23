//
//  GetPaymentMethodsInteractor.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Protocol for retrieving available payment methods.
internal protocol GetPaymentMethodsInteractor {
    /// Fetches available payment methods for the current session.
    func execute() async throws -> [InternalPaymentMethod]
}

/// Default implementation of GetPaymentMethodsInteractor.
internal final class GetPaymentMethodsInteractorImpl: GetPaymentMethodsInteractor, LogReporter {
    
    private let repository: HeadlessRepository
    
    init(repository: HeadlessRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [InternalPaymentMethod] {
        logger.info(message: "Fetching available payment methods")
        
        do {
            let paymentMethods = try await repository.getPaymentMethods()
            logger.info(message: "Retrieved \(paymentMethods.count) payment methods")
            return paymentMethods
        } catch {
            logger.error(message: "Failed to fetch payment methods: \(error)")
            throw error
        }
    }
}