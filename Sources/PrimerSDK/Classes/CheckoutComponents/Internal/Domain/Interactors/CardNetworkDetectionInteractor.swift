//
//  CardNetworkDetectionInteractor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol CardNetworkDetectionInteractor {
    var networkDetectionStream: AsyncStream<[CardNetwork]> { get }
    func detectNetworks(for cardNumber: String) async
    /// For co-badged cards with multiple networks
    func selectNetwork(_ network: CardNetwork) async
}

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
