//
//  CardValidationService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol CardValidationService {
    func validateCardNetworks(withCardNumber cardNumber: String)
    func createValidationMetadata(networks: [CardNetwork], source: PrimerCardValidationSource) -> PrimerCardNumberEntryMetadata
}

final class DefaultCardValidationService: CardValidationService, LogReporter {
    static let maximumBinLength = 8

    private var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? {
        rawDataManager.delegate
    }

    private let apiClient: PrimerAPIClientBINDataProtocol

    private let debouncer: Debouncer

    private let rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager

    private let allowedCardNetworks: [CardNetwork]

    private var mostRecentCardNumber: String?
    private var lastAnalyticsEventTime: Date?
    private var lastValidatedCardNumber: String?

    // MARK: Thread‐safe metadata cache

    private let metadataCacheQueue = DispatchQueue(label: "com.primer.cardValidationService.metadataCacheQueue", attributes: .concurrent)
    private var metadataCacheBacking: [String: PrimerCardNumberEntryMetadata] = [:]

    private func getCachedMetadata(for key: String) -> PrimerCardNumberEntryMetadata? {
        metadataCacheQueue.sync {
            metadataCacheBacking[key]
        }
    }

    private func setCachedMetadata(_ metadata: PrimerCardNumberEntryMetadata, for key: String) {
        metadataCacheQueue.async(flags: .barrier) {
            self.metadataCacheBacking[key] = metadata
        }
    }

    private var binDataCacheBacking: [String: PrimerBinData] = [:]

    private func getCachedBinData(for key: String) -> PrimerBinData? {
        metadataCacheQueue.sync {
            binDataCacheBacking[key]
        }
    }

    private func setCachedBinData(_ binData: PrimerBinData, for key: String) {
        metadataCacheQueue.async(flags: .barrier) {
            self.binDataCacheBacking[key] = binData
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

        let bin = String(sanitizedCardNumber.prefix(Self.maximumBinLength))

        if let mostRecent = mostRecentCardNumber,
           mostRecent.prefix(Self.maximumBinLength) == bin {
            if let cached = getCachedMetadata(for: bin) {
                handle(cardMetadata: cached, forCardState: cardState)
            }
            if let cachedBin = getCachedBinData(for: bin) {
                delegate?.primerRawDataManager?(rawDataManager, didReceiveBinData: cachedBin)
            }
            return
        }

        mostRecentCardNumber = sanitizedCardNumber
        lastValidatedCardNumber = nil

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

        let cacheKey = cardState.cardNumber
        if let cached = getCachedMetadata(for: cacheKey) {
            handle(cardMetadata: cached, forCardState: cardState)
            if let cachedBin = getCachedBinData(for: cacheKey) {
                delegate?.primerRawDataManager?(rawDataManager, didReceiveBinData: cachedBin)
            }
            return
        }

        Task { @MainActor in
            do {
                let result = try await fetchBinData(cardState.cardNumber)
                guard !result.binData.isEmpty else {
                    useLocalValidation(withCardState: cardState, isFallback: true)
                    return
                }

                let enrichedNetworks = result.binData.compactMap { item -> PrimerCardNetwork? in
                    guard let networkStr = item.network else { return nil }
                    let cardNetwork = CardNetwork(cardNetworkStr: networkStr)
                    return PrimerCardNetwork(
                        displayName: item.displayName ?? cardNetwork.displayName,
                        network: cardNetwork,
                        issuerCountryCode: item.issuerCountryCode,
                        issuerName: item.issuerName,
                        accountFundingType: item.accountFundingType,
                        prepaidReloadableIndicator: item.prepaidReloadableIndicator,
                        productUsageType: item.productUsageType,
                        productCode: item.productCode,
                        productName: item.productName,
                        issuerCurrencyCode: item.issuerCurrencyCode,
                        regionalRestriction: item.regionalRestriction,
                        accountNumberType: item.accountNumberType
                    )
                }

                let networks = enrichedNetworks.map(\.network)
                let metadata = createValidationMetadata(networks: networks, source: .remote, enrichedNetworks: enrichedNetworks)

                handle(cardMetadata: metadata, forCardState: cardState)

                let binData = buildBinData(from: enrichedNetworks, firstDigits: result.firstDigits, status: .complete)
                setCachedBinData(binData, for: cardState.cardNumber)
                delegate?.primerRawDataManager?(rawDataManager, didReceiveBinData: binData)
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

        let localNetworks = networks.map { PrimerCardNetwork(network: $0) }
        let binData = buildBinData(from: localNetworks, firstDigits: nil, status: .partial)
        delegate?.primerRawDataManager?(rawDataManager, didReceiveBinData: binData)

        if isFallback {
            Task {
                try? await rawDataManager.validateRawData(withCardNetworksMetadata: metadata)
            }
        }
    }

    private func handle(cardMetadata: PrimerCardNumberEntryMetadata, forCardState cardState: PrimerCardNumberEntryState) {
        let cacheKey = cardState.cardNumber
        setCachedMetadata(cardMetadata, for: cacheKey)

        let trackable = cardMetadata.selectableCardNetworks ?? cardMetadata.detectedCardNetworks
        sendEvent(forNetworks: trackable.items, source: cardMetadata.source)

        delegate?.primerRawDataManager?(rawDataManager,
                                        didReceiveMetadata: cardMetadata,
                                        forState: cardState)

        guard lastValidatedCardNumber != cardState.cardNumber else {
            return
        }

        lastValidatedCardNumber = cardState.cardNumber
        Task {
            try? await self.rawDataManager.validateRawData(withCardNetworksMetadata: cardMetadata)
        }
    }

    private func buildBinData(from networks: [PrimerCardNetwork], firstDigits: String?, status: PrimerBinDataStatus) -> PrimerBinData {
        let preferred = networks.first { $0.allowed }
        let alternatives = networks.filter { $0 !== preferred }
        return PrimerBinData(
            preferred: preferred,
            alternatives: alternatives,
            status: status,
            firstDigits: firstDigits
        )
    }

    // MARK: Model generation

    func createValidationMetadata(networks: [CardNetwork],
                                  source: PrimerCardValidationSource) -> PrimerCardNumberEntryMetadata {
        createValidationMetadata(networks: networks, source: source, enrichedNetworks: nil)
    }

    private func createValidationMetadata(networks: [CardNetwork],
                                          source: PrimerCardValidationSource,
                                          enrichedNetworks: [PrimerCardNetwork]?) -> PrimerCardNumberEntryMetadata
    {
        let selectable: [PrimerCardNetwork]
        let detected: [PrimerCardNetwork]

        if let enrichedNetworks {
            selectable = allowedCardNetworks.compactMap { allowed in
                enrichedNetworks.first { $0.network == allowed }
            }
            let unallowed = enrichedNetworks.filter { !allowedCardNetworks.contains($0.network) }
            detected = selectable + unallowed
        } else {
            selectable = allowedCardNetworks
                .filter { networks.contains($0) }
                .map { PrimerCardNetwork(network: $0) }

            detected = selectable + networks.filter { !allowedCardNetworks.contains($0) }
                .map { PrimerCardNetwork(network: $0) }
        }

        let containsDisallowedNetwork = networks.contains(where: [CardNetwork].selectionDisallowedCardNetworks.contains)

        return .init(
            source: source,
            selectableCardNetworks: selectable.isEmpty ? nil : selectable,
            detectedCardNetworks: detected,
            autoSelectedCardNetwork: containsDisallowedNetwork && selectable.count > 1 ? selectable.first : nil
        )
    }

    // MARK: Analytics

    private func sendEvent(forNetworks networks: [PrimerCardNetwork], source: PrimerCardValidationSource) {
        // Throttle analytics events to prevent queue backup during rapid validation
        let now = Date()
        if let lastEventTime = lastAnalyticsEventTime,
           now.timeIntervalSince(lastEventTime) < 1.0 {
            return
        }
        lastAnalyticsEventTime = now

        let event = Analytics.Event.ui(
            action: .view,
            context: .init(cardNetworks: networks.map(\.network.rawValue)),
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

    private var fetchBinDataTask: CancellableTask<Response.Body.Bin.Data>?

    private func fetchBinData(_ cardNumber: String) async throws -> Response.Body.Bin.Data {
        let bin = String(cardNumber.prefix(Self.maximumBinLength))
        guard let token = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw PrimerError.invalidClientToken()
        }

        await fetchBinDataTask?.cancel(with: handled(primerError: .unknown()))
        let task = CancellableTask {
            try await self.apiClient.fetchBinData(clientToken: token, bin: bin)
        }
        fetchBinDataTask = task

        defer {
            fetchBinDataTask = nil
        }

        return try await task.wait()
    }
}
