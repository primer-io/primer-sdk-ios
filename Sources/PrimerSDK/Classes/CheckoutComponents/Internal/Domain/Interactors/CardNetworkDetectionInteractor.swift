//
//  CardNetworkDetectionInteractor.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Protocol for card network detection business logic
protocol CardNetworkDetectionInteractor {
    /// Stream of detected card networks for real-time updates
    var networkDetectionStream: AsyncStream<[CardNetwork]> { get }
    
    /// Trigger network detection for a given card number
    func detectNetworks(for cardNumber: String) async
    
    /// Handle user selection of a specific network for co-badged cards
    func selectNetwork(_ network: CardNetwork) async
}

/// Implementation of card network detection interactor
@available(iOS 15.0, *)
internal final class CardNetworkDetectionInteractorImpl: CardNetworkDetectionInteractor, LogReporter {
    
    private let repository: HeadlessRepository
    
    var networkDetectionStream: AsyncStream<[CardNetwork]> {
        repository.getNetworkDetectionStream()
    }
    
    init(repository: HeadlessRepository) {
        self.repository = repository
        logger.debug(message: "CardNetworkDetectionInteractor initialized")
    }
    
    func detectNetworks(for cardNumber: String) async {
        logger.debug(message: "🌐 [NetworkDetection] Triggering detection for card number")
        
        // Only trigger if we have enough digits (BIN range)
        guard cardNumber.replacingOccurrences(of: " ", with: "").count >= 6 else {
            logger.debug(message: "🌐 [NetworkDetection] Card number too short for network detection")
            return
        }
        
        await repository.updateCardNumberInRawDataManager(cardNumber)
    }
    
    func selectNetwork(_ network: CardNetwork) async {
        logger.info(message: "🌐 [NetworkDetection] User selected network: \(network.displayName)")
        await repository.selectCardNetwork(network)
    }
}