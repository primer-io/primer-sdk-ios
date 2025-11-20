//
//  CardValidationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol CardValidationService {
    func validateCardNetworks(withCardNumber cardNumber: String)
    func createValidationMetadata(networks: [CardNetwork], source: PrimerCardValidationSource) -> PrimerCardNumberEntryMetadata
}

final class DefaultCardValidationService: CardValidationService, LogReporter {

    static let maximumBinLength = 8

    private var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? {
        return self.rawDataManager.delegate
    }

    private let apiClient: PrimerAPIClientBINDataProtocol

    private let debouncer: Debouncer

    private let rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager

    private let allowedCardNetworks: [CardNetwork]

    private var mostRecentCardNumber: String?

    // MARK: Thread‐safe metadata cache

    private let metadataCacheQueue = DispatchQueue(label: "com.primer.cardValidationService.metadataCacheQueue", attributes: .concurrent)
    private var metadataCacheBacking: [String: PrimerCardNumberEntryMetadata] = [:]

    private func getCachedMetadata(for key: String) -> PrimerCardNumberEntryMetadata? {
        return metadataCacheQueue.sync { metadataCacheBacking[key] }
    }

    private func setCachedMetadata(_ metadata: PrimerCardNumberEntryMetadata, for key: String) {
        metadataCacheQueue.async(flags: .barrier) {
            self.metadataCacheBacking[key] = metadata
        }
    }

    init(rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
         allowedCardNetworks: [CardNetwork] = [CardNetwork].allowedCardNetworks,
         apiClient: PrimerAPIClientBINDataProtocol = PrimerAPIClient(),
         debouncer: Debouncer = .init(delay: 0.35)) {
        self.rawDataManager = rawDataManager
        self.allowedCardNetworks = allowedCardNetworks
        self.apiClient = apiClient
        self.debouncer = debouncer
    }

    // MARK: Core Validation

    func validateCardNetworks(withCardNumber cardNumber: String) {
        let sanitizedCardNumber = cardNumber.withoutWhiteSpace
        let cardState = PrimerCardNumberEntryState(cardNumber: sanitizedCardNumber)

        // Don't validate if the BIN (first eight digits) hasn't changed
        let bin = String(sanitizedCardNumber.prefix(Self.maximumBinLength))
        if let mostRecent = mostRecentCardNumber,
           mostRecent.prefix(Self.maximumBinLength) == bin {
            if let cached = getCachedMetadata(for: bin) {
                handle(cardMetadata: cached, forCardState: cardState)
            }
            return
        }

        mostRecentCardNumber = sanitizedCardNumber

        // Don't validate if incomplete BIN (less than eight digits)
        if sanitizedCardNumber.count < Self.maximumBinLength {
            useLocalValidation(withCardState: cardState, isFallback: false)
            return
        }

        debouncer.debounce { [weak self] in
            self?.useRemoteValidation(withCardState: cardState)
        }
    }

    private func useRemoteValidation(withCardState cardState: PrimerCardNumberEntryState) {
        delegate?.primerRawDataManager?(rawDataManager,
                                        willFetchMetadataForState: cardState)

        if let cached = getCachedMetadata(for: cardState.cardNumber) {
            return handle(cardMetadata: cached, forCardState: cardState)
        }

        Task { @MainActor in
            do {
                let result = try await listCardNetworks(cardState.cardNumber)
                guard !result.networks.isEmpty else {
                    useLocalValidation(withCardState: cardState, isFallback: true)
                    return
                }

                let networks = result.networks.map { CardNetwork(cardNetworkStr: $0.value) }
                let metadata = createValidationMetadata(networks: networks, source: .remote)

                handle(cardMetadata: metadata, forCardState: cardState)
            } catch {
                sendEvent(forError: error)
                logger.warn(message: "Remote card validation failed: \(error.localizedDescription)")
                useLocalValidation(withCardState: cardState, isFallback: true)
            }
        }
    }

    private func useLocalValidation(withCardState cardState: PrimerCardNumberEntryState, isFallback: Bool) {
        // Only build the network if there's actually a card number
        let networks: [CardNetwork] = cardState.cardNumber.isEmpty ? [] : [CardNetwork(cardNumber: cardState.cardNumber)]
        let metadata = createValidationMetadata(
            networks: networks,
            source: isFallback ? .localFallback : .local
        )

        if cardState.cardNumber.count >= Self.maximumBinLength {
            let logMessage = """
            Local validation was used where remote validation \
            would have been preferred (max BIN length exceeded).
            """
            logger.warn(message: logMessage)
            let event = Analytics.Event.message(
                message: logMessage,
                messageType: .other,
                severity: .warning
            )
            Analytics.Service.fire(event: event)
        }

        delegate?.primerRawDataManager?(rawDataManager,
                                        didReceiveMetadata: metadata,
                                        forState: cardState)
        if isFallback {
            Task {
                try? await rawDataManager.validateRawData(withCardNetworksMetadata: metadata)
            }
        }
    }

    private func handle(cardMetadata: PrimerCardNumberEntryMetadata, forCardState cardState: PrimerCardNumberEntryState) {
        setCachedMetadata(cardMetadata, for: cardState.cardNumber)

        let trackable = cardMetadata.selectableCardNetworks ?? cardMetadata.detectedCardNetworks
        sendEvent(forNetworks: trackable.items, source: cardMetadata.source)

        delegate?.primerRawDataManager?(rawDataManager,
                                        didReceiveMetadata: cardMetadata,
                                        forState: cardState)

        Task {
            try? await self.rawDataManager.validateRawData(withCardNetworksMetadata: cardMetadata)
        }
    }

    // MARK: Model generation

    func createValidationMetadata(networks: [CardNetwork],
                                  source: PrimerCardValidationSource) -> PrimerCardNumberEntryMetadata {
        let selectable = allowedCardNetworks
            .filter { networks.contains($0) }
            .map { PrimerCardNetwork(network: $0) }

        let detected = selectable + networks.filter { !allowedCardNetworks.contains($0) }
            .map { PrimerCardNetwork(network: $0) }

        let containsDisallowedNetwork = networks.contains(where: [CardNetwork].selectionDisallowedCardNetworks.contains)

        return .init(
            source: source,
            selectableCardNetworks: selectable.isEmpty ? nil : selectable,
            detectedCardNetworks: detected,
            autoSelectedCardNetwork: containsDisallowedNetwork ? selectable.first : nil
        )
    }

    // MARK: Analytics

    private func sendEvent(forNetworks networks: [PrimerCardNetwork], source: PrimerCardValidationSource) {
        let event = Analytics.Event.ui(
            action: .view,
            context: .init(cardNetworks: networks.map { $0.network.rawValue }),
            extra: "Source = \(source.rawValue)",
            objectType: .list,
            objectId: .cardNetwork,
            objectClass: String(describing: CardNetwork.self),
            place: .cardForm
        )
        Analytics.Service.fire(event: event)
    }

    private func sendEvent(forError error: Error) {
        let event = Analytics.Event.message(
            message: "Failed to remotely validate card network: \(error.localizedDescription)",
            messageType: .error,
            severity: .error
        )
        Analytics.Service.fire(event: event)
    }

    // MARK: API Logic

    private var listCardNetworksTask: CancellableTask<Response.Body.Bin.Networks>?

    private func listCardNetworks(_ cardNumber: String) async throws -> Response.Body.Bin.Networks {
        let bin = String(cardNumber.prefix(Self.maximumBinLength))
        guard let token = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw PrimerError.invalidClientToken()
        }

        await listCardNetworksTask?.cancel(with: handled(primerError: .unknown()))
        let task = CancellableTask {
            try await self.apiClient.listCardNetworks(clientToken: token, bin: bin)
        }
        listCardNetworksTask = task

        defer {
            listCardNetworksTask = nil
        }

        return try await task.wait()
    }
}
