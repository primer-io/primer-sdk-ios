//
//  CardNetworkDetectionInteractor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
final class CardNetworkDetectionInteractorImpl: CardNetworkDetectionInteractor, LogReporter {
    private let repository: HeadlessRepository

    var networkDetectionStream: AsyncStream<[CardNetwork]> {
        repository.getNetworkDetectionStream()
    }

    init(repository: HeadlessRepository) {
        self.repository = repository
        logger.debug(message: "CardNetworkDetectionInteractor initialized")
    }

    func detectNetworks(for cardNumber: String) async {
        // Always call repository to allow cache clearing logic to run
        // The repository will handle the < 8 digit case by clearing networks
        await repository.updateCardNumberInRawDataManager(cardNumber)
    }

    func selectNetwork(_ network: CardNetwork) async {
        await repository.selectCardNetwork(network)
    }
}
