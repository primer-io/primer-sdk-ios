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

    var mostRecentCardNumber: String?

    init(rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
         apiClient: PrimerAPIClientBINDataProtocol = PrimerAPIClient(),
         debouncer: Debouncer = .init(delay: 0.35)) {
        self.rawDataManager = rawDataManager
        self.apiClient = apiClient
        self.debouncer = debouncer
    }
        
    func validateCardNetworks(withCardNumber cardNumber: String) {
        let sanitizedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        let cardState = PrimerCardNumberEntryState(cardNumber: sanitizedCardNumber)

        // Don't validate empty string
        guard !sanitizedCardNumber.isEmpty else {
            return
        }
        // Don't validate if the BIN (first eight digits) hasn't changed
        if let mostRecentCardNumber = mostRecentCardNumber, 
            mostRecentCardNumber.prefix(Self.maximumBinLength) == sanitizedCardNumber.prefix(Self.maximumBinLength) {
            return
        }
        
        mostRecentCardNumber = sanitizedCardNumber
        
        // Don't validate if incomplete BIN (less than eight digits)
        if sanitizedCardNumber.count < Self.maximumBinLength {
            useLocalValidation(withCardState: cardState)
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
    
    private func useRemoteValidation(withCardState cardState: PrimerCardNumberEntryState) {
        delegate?.primerRawDataManager?(rawDataManager,
                                        willFetchMetadataForState: cardState)
        
        let rawDataManager = rawDataManager
        
        _ = listCardNetworks(cardState.cardNumber).done { [weak self] result in
            guard result.networks.count > 0 else {
                self?.useLocalValidation(withCardState: cardState)
                return
            }
            let cardMetadata = PrimerCardNumberEntryMetadata(source: .remote,
                                                             availableCardNetworks: result.networks.map { network in
                PrimerCardNetwork(displayName: network.displayName,
                                  network: CardNetwork(cardNetworkStr: network.value))
            })
            
            self?.delegate?.primerRawDataManager?(rawDataManager,
                                                  didReceiveMetadata: cardMetadata,
                                                  forState: cardState)
            self?.sendEvent(forNetworks: cardMetadata.availableCardNetworks)
        }.catch { error in
            self.sendEvent(forError: error)
            self.logger.warn(message: "Remote card validation failed: \(error.localizedDescription)")
            self.useLocalValidation(withCardState: cardState)
        }
    }
    
    func useLocalValidation(withCardState cardState: PrimerCardNumberEntryState) {
        let localValidationNetwork = CardNetwork(cardNumber: cardState.cardNumber)
        let displayName = localValidationNetwork.validation?.niceType ?? localValidationNetwork.rawValue.lowercased().capitalized
        let cardNetwork = PrimerCardNetwork(displayName: displayName,
                                            network: CardNetwork(cardNetworkStr: localValidationNetwork.rawValue))
        
        let metadata = PrimerCardNumberEntryMetadata(source: .local,
                                                     availableCardNetworks: [cardNetwork])
        
        if cardState.cardNumber.count >= Self.maximumBinLength {
            let logMessage = "Local validation was used where remote validation would have been preferred (max BIN length exceeded)."

            logger.warn(message: logMessage)
            let event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: logMessage,
                    messageType: .other,
                    severity: .warning)
            )
            Analytics.Service.record(event: event)
        }
        
        delegate?.primerRawDataManager?(rawDataManager,
                                        didReceiveMetadata: metadata,
                                        forState: cardState)
    }
    
    // MARK: Analytics
    
    private func sendEvent(forNetworks networks: [PrimerCardNetwork]) {
        let event = Analytics.Event(
            eventType: .ui, 
            properties: UIEventProperties(
                action: .view,
                context: nil,
                extra: nil,
                objectType: .list,
                objectId: .cardNetwork,
                objectClass: String(describing: CardNetwork.self),
                place: .cardForm
            )
        )
        Analytics.Service.record(event: event)
    }
    
    private func sendEvent(forError error: Error) {
        let event = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "Failed to remotely validate card network: \(error.localizedDescription)",
                messageType: .error,
                severity: .error
            )
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
