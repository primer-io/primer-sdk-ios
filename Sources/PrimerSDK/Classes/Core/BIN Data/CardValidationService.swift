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
        // Don't validate empty string
        guard !sanitizedCardNumber.isEmpty else {
            return
        }
        // Don't validate if the BIN (first eight digits) hasn't changed
        if let mostRecentCardNumber = mostRecentCardNumber, mostRecentCardNumber.prefix(8) == cardNumber.prefix(8) {
            return
        }
        let isFirstTimeRemoteValidation = mostRecentCardNumber == nil
        mostRecentCardNumber = sanitizedCardNumber
        
        let cardState = PrimerCardNumberEntryState(cardNumber: sanitizedCardNumber)
        guard sanitizedCardNumber.count >= 8 else {
            useLocalValidation(withCardState: cardState)
            return
        }
        
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
                                        willFetchCardMetadataForState: cardState)
        
        let rawDataManager = rawDataManager
        
        _ = listCardNetworks(cardState.cardNumber).done { [weak self] result in
            guard result.networks.count > 0 else {
                self?.useLocalValidation(withCardState: cardState)
                return
            }
            let cardMetadata = PrimerCardNumberEntryMetadata(availableCardNetworks: result.networks.map { network in
                PrimerCardNetwork(displayName: network.displayName, networkIdentifier: network.value)
            })
            
            self?.delegate?.primerRawDataManager?(rawDataManager,
                                                  didReceiveCardMetadata: cardMetadata,
                                                  forCardState: cardState)
        }.catch { error in
            // JN TODO: CHKT-1772 - send event
            self.logger.warn(message: "Remote card validation failed: \(error.localizedDescription)")
            self.useLocalValidation(withCardState: cardState)
        }
    }
    
    func useLocalValidation(withCardState cardState: PrimerCardNumberEntryState) {
        let localValidationNetwork = CardNetwork(cardNumber: cardState.cardNumber)
        let displayName = localValidationNetwork.validation?.niceType ?? localValidationNetwork.rawValue.lowercased().capitalized
        let cardNetwork = PrimerCardNetwork(displayName: displayName,
                                            networkIdentifier: localValidationNetwork.rawValue)
        delegate?.primerRawDataManager?(rawDataManager,
                                        didReceiveCardMetadata: .init(availableCardNetworks: [cardNetwork]),
                                        forCardState: cardState)
    }
    
    // MARK: API Logic
    
    var validateCardNetworksCancellable: PrimerCancellable?
    
    private func listCardNetworks(_ cardNumber: String) -> Promise<Response.Body.Bin.Networks> {
        
        // ⚠️ We must only ever send eight or less digits to the endpoint
        let cardNumber = String(cardNumber.prefix(8))

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
