//
//  MockCardNetworkSyncObserver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerSDK

@MainActor
final class MockCardNetworkSyncObserver: CardNetworkSyncObserver {

    private(set) var states: [Bool] = []

    func cardNetworkSyncDidChange(isSyncing: Bool) {
        states.append(isSyncing)
    }
}
