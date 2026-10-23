//
//  ClientSessionCardNetworkSync.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

actor ClientSessionCardNetworkSync: LogReporter {

    static let shared = ClientSessionCardNetworkSync()

    private let actionsFactory: () -> ClientSessionActionsProtocol
    private let isSurchargeSession: @Sendable () -> Bool
    private let currentSession: @Sendable () -> ClientSession.APIResponse?
    private var syncedNetwork: CardNetwork?
    private weak var syncedSession: ClientSession.APIResponse?
    private var requestedNetwork: CardNetwork?
    private var inFlight: Task<Void, Never>?
    private var sentNetwork = false
    private var paymentStarted = false
    private var epoch = 0

    nonisolated var isEnabled: Bool {
        PrimerInternal.shared.intent == .checkout
            && PrimerInternal.shared.sdkIntegrationType != .dropIn
            && isSurchargeSession()
    }

    init(
        actionsFactory: @escaping () -> ClientSessionActionsProtocol = { ClientSessionActionsModule() },
        isSurchargeSession: @escaping @Sendable () -> Bool = { PrimerAPIConfiguration.current?.hasSurchargeEnabled == true },
        currentSession: @escaping @Sendable () -> ClientSession.APIResponse? = { PrimerAPIConfigurationModule.apiConfiguration?.clientSession }
    ) {
        self.actionsFactory = actionsFactory
        self.isSurchargeSession = isSurchargeSession
        self.currentSession = currentSession
    }

    func needsSync(_ network: CardNetwork?) -> Bool {
        resetIfSessionChanged()
        return inFlight != nil || network != syncedNetwork
    }

    func sync(_ network: CardNetwork?) async {
        resetIfSessionChanged()
        requestedNetwork = network
        let previous = inFlight
        let task = Task {
            await previous?.value
            guard requestedNetwork == network, network != syncedNetwork else { return }
            await send(network)
        }
        inFlight = task
        await task.value
        if inFlight == task { inFlight = nil }
    }

    func markSynced(_ network: CardNetwork) {
        resetIfSessionChanged()
        sentNetwork = true
        record(network)
    }

    func reset() {
        epoch += 1
        syncedNetwork = nil
        syncedSession = nil
        requestedNetwork = nil
        sentNetwork = false
        paymentStarted = false
    }

    func startPayment() {
        paymentStarted = true
    }

    func awaitPendingUpdate() async {
        await inFlight?.value
    }

    func endPayment() {
        paymentStarted = false
    }

    func release() async {
        guard !paymentStarted else { return }
        epoch += 1
        requestedNetwork = nil
        guard sentNetwork else { return }
        sentNetwork = false
        let task = Task { await send(nil) }
        inFlight = task
        await task.value
        if inFlight == task { inFlight = nil }
    }

    private func send(_ network: CardNetwork?) async {
        let epoch = epoch
        sentNetwork = network != nil
        let actions = actionsFactory()
        do {
            if let network {
                try await actions.selectPaymentMethodIfNeeded(
                    PrimerPaymentMethodType.paymentCard.rawValue,
                    cardNetwork: network.rawValue
                )
            } else {
                try await actions.unselectPaymentMethodIfNeeded()
            }
            guard epoch == self.epoch else { return }
            record(network)
        } catch {
            sentNetwork = true
            logger.error(message: "Failed to update the client session's card network: \(error)")
        }
    }

    private func record(_ network: CardNetwork?) {
        syncedNetwork = network
        syncedSession = currentSession()
    }

    private func resetIfSessionChanged() {
        guard currentSession() !== syncedSession else { return }
        syncedNetwork = nil
        syncedSession = nil
    }
}
