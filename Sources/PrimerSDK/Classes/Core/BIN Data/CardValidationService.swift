//
//  CardValidationService.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 30/10/2023.
//

import Foundation

protocol CardValidationService {
    static var apiClient: PrimerAPIClientProtocol? { get set }
    func validateCardNetworks(withCardNumber cardNumber: String)
}

class DefaultCardValidationService: CardValidationService, LogReporter {
    
    static let maximumBinLength = 8
    
    static var apiClient: PrimerAPIClientProtocol?

    var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? {
        return self.rawDataManager.delegate
    }
        
    let apiClient: PrimerAPIClientBINDataProtocol
    
    let debouncer: Debouncer
    
    let rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager
    
    let allowedCardNetworks: [CardNetwork]

    var mostRecentCardNumber: String?

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
        let sanitizedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        let cardState = PrimerCardNumberEntryState(cardNumber: sanitizedCardNumber)
                
        // Don't validate if the BIN (first eight digits) hasn't changed
        let bin = String(sanitizedCardNumber.prefix(Self.maximumBinLength))
        if let mostRecentCardNumber = mostRecentCardNumber,
            mostRecentCardNumber.prefix(Self.maximumBinLength) == bin {
            if let cachedMetadata = metadataCache[bin] {
                handle(cardMetadata: cachedMetadata, forCardState: cardState)
            }
            return
        }
        
        mostRecentCardNumber = sanitizedCardNumber
        
        // Don't validate if incomplete BIN (less than eight digits)
        if sanitizedCardNumber.count < Self.maximumBinLength {
            useLocalValidation(withCardState: cardState, isFallback: false)
            return
        }
        
        let isFirstTimeRemoteValidation = mostRecentCardNumber == nil
                
        if isFirstTimeRemoteValidation {
            useRemoteValidation(withCardState: cardState)
        } else {
            debouncer.debounce { [weak self] in
                self?.useRemoteValidation(withCardState: cardState)
            }
        }
    }
    
    var metadataCache: [String: PrimerCardNumberEntryMetadata] = [:]
    
    private func useRemoteValidation(withCardState cardState: PrimerCardNumberEntryState) {
        delegate?.primerRawDataManager?(rawDataManager,
                                        willFetchMetadataForState: cardState)
        
        let rawDataManager = rawDataManager
        
        if let cachedMetadata = metadataCache[cardState.cardNumber] {
            handle(cardMetadata: cachedMetadata, forCardState: cardState)
            return
        }
        
        _ = listCardNetworks(cardState.cardNumber).done { [weak self] result in
            guard let self = self else { return }
            
            guard result.networks.count > 0 else {
                self.useLocalValidation(withCardState: cardState, isFallback: true)
                return
            }
            
            let cardMetadata = self.createValidationMetadata(networks: result.networks.map { CardNetwork(cardNetworkStr: $0.value) },
                                                             source: .remote)
                    
            self.handle(cardMetadata: cardMetadata, forCardState: cardState)
        }.catch { error in
            self.sendEvent(forError: error)
            self.logger.warn(message: "Remote card validation failed: \(error.localizedDescription)")
            self.useLocalValidation(withCardState: cardState, isFallback: true)
        }
    }
    
    func useLocalValidation(withCardState cardState: PrimerCardNumberEntryState, isFallback: Bool) {
        let localValidationNetwork = CardNetwork(cardNumber: cardState.cardNumber)
        let metadata = createValidationMetadata(networks: cardState.cardNumber.isEmpty ? [] : [localValidationNetwork],
                                                source: isFallback ? .localFallback : .local)
        
        if cardState.cardNumber.count >= Self.maximumBinLength {
            let logMessage = "Local validation was used where remote validation would have been preferred (max BIN length exceeded)."

            logger.warn(message: logMessage)
            let event = Analytics.Event.message(
                message: logMessage,
                messageType: .other,
                severity: .warning
            )
            Analytics.Service.record(event: event)
        }
        
        delegate?.primerRawDataManager?(rawDataManager,
                                        didReceiveMetadata: metadata,
                                        forState: cardState)
        if isFallback {
            DispatchQueue.main.async {
                _ = self.rawDataManager.validateRawData(withCardNetworksMetadata: metadata)
            }
        }
    }
    
    func handle(cardMetadata: PrimerCardNumberEntryMetadata, forCardState cardState: PrimerCardNumberEntryState) {
        self.metadataCache[cardState.cardNumber] = cardMetadata

        let trackableNetworks = cardMetadata.selectableCardNetworks ?? cardMetadata.detectedCardNetworks
        self.sendEvent(forNetworks: trackableNetworks.items,
                       source: cardMetadata.source)
        
        delegate?.primerRawDataManager?(rawDataManager,
                                        didReceiveMetadata: cardMetadata,
                                        forState: cardState)
        
        DispatchQueue.main.async {
            _ = self.rawDataManager.validateRawData(withCardNetworksMetadata: cardMetadata)
        }
    }
    
    // MARK: Model generation
    
    private func createValidationMetadata(networks: [CardNetwork], 
                                          source: PrimerCardValidationSource) -> PrimerCardNumberEntryMetadata {
        let selectableNetworks: [PrimerCardNetwork] = allowedCardNetworks
            .filter { networks.contains($0) }
            .map { PrimerCardNetwork(network: $0) }

        let detectedNetworks = networks.map { PrimerCardNetwork(network: $0) }
        
        return .init(
            source: source,
            selectableCardNetworks: selectableNetworks,
            detectedCardNetworks: detectedNetworks
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
        Analytics.Service.record(event: event)
    }
    
    private func sendEvent(forError error: Error) {
        let event = Analytics.Event.message(
            message: "Failed to remotely validate card network: \(error.localizedDescription)",
            messageType: .error,
            severity: .error
        )
        Analytics.Service.record(event: event)
    }
    
    // MARK: API Logic
    
    var validateCardNetworksCancellable: PrimerCancellable?
    
    private func listCardNetworks(_ cardNumber: String) -> Promise<Response.Body.Bin.Networks> {
        
        // ⚠️ We must only ever send eight or less digits to the endpoint
        let cardNumber = String(cardNumber.prefix(Self.maximumBinLength))

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return rejectedPromise(withError: PrimerError.invalidClientToken(userInfo: nil, diagnosticsId: ""))
        }
        
        return Promise { resolver in
            if let cancellable = validateCardNetworksCancellable {
                cancellable.cancel()
            }
            
            validateCardNetworksCancellable = (Self.apiClient ?? apiClient).listCardNetworks(clientToken: decodedJWTToken, bin: cardNumber) { result in
                switch result {
                case .success(let networks):
                    resolver.fulfill(networks)
                case .failure(let error):
                    resolver.reject(error)
                }
            }
        }
    }
        
    // MARK: Helpers
        
    private func rejectedPromise<T>(withError error: PrimerError) -> Promise<T> {
        return Promise {
            $0.reject(error)
        }
    }
    
}
