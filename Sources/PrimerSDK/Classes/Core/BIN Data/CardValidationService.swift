//
//  CardValidationService.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 30/10/2023.
//

import Foundation

protocol CardValidationService {
    func validateCardNetworks(withCardNumber cardNumber: String)
}

class DefaultCardValidationService: CardValidationService, LogReporter {
    
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
        guard !sanitizedCardNumber.isEmpty, sanitizedCardNumber != mostRecentCardNumber else {
            return
        }
        mostRecentCardNumber = sanitizedCardNumber
        
        let cardState = PrimerCardNumberEntryState(cardNumber: sanitizedCardNumber)
        guard sanitizedCardNumber.count >= 6 else {
            useLocalValidation(withCardState: cardState)
            return
        }
        
        debouncer.debounce { [weak self] in
            self?.useRemoteValidation(withCardState: cardState)
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
            let cardMetadata = PrimerCardMetadata(availableCardNetworks: result.networks.map { network in
                PrimerCardNetwork(displayName: network.displayName, networkIdentifier: network.value)
            })
            
            self?.delegate?.primerRawDataManager?(rawDataManager,
                                                  didReceiveCardMetadata: cardMetadata,
                                                  forCardState: cardState)
        }.catch { error in
            // JN TODO: CHKT-1772 - send event
            self.logger.error(message: "Error occurred while remotely validation '\(cardState.cardNumber)': \(error.localizedDescription)")
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
            
            validateCardNetworksCancellable = apiClient.listCardNetworks(clientToken: decodedJWTToken, bin: cardNumber) { result in
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
