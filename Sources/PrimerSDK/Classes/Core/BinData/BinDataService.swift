//
//  BinDataService.swift
//  Pods-Debug App
//
//  Created by Jack Newcombe on 18/10/2023.
//

import Foundation
import Combine

protocol BinDataService {
    var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? { get }
    func validateCardNetworks(withCardNumber cardNumber: String)
}

class DefaultBinDataService: BinDataService {
    
    let delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
    
    weak var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    
    var cardNumberPublisher = PassthroughSubject<PrimerCardValidationState, Never>()
    
    var cancellables: Set<AnyCancellable> = .init()

    init(rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
         delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?) {
        self.rawDataManager = rawDataManager
        self.delegate = delegate
        
        cardNumberPublisher
            .debounce(for: .seconds(0.35), scheduler: RunLoop.current)
            .sink(receiveValue: { [self] in callAPI(withValidationState: $0) })
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func validateCardNetworks(withCardNumber cardNumber: String) {
        guard let rawDataManager = rawDataManager else {
            print("[DefaultBinDataService] ERROR: rawDataManager was nil")
            return
        }
        
        let cardValidationState = PrimerCardValidationState(cardNumber: cardNumber)
        // JN TODO: full local fallback validation
        guard cardNumber.count >= 6 else {
            delegate?.primerRawDataManager?(rawDataManager,
                                            willFetchCardMetadataForState: cardValidationState)
                        print("[DefaultBinDataService] WARNING: cardNumber length was zero, so didn't fetch card networks")
            print("[DefaultBinDataService] WARNING: ↳ falling back to local validation")
            useLocalValidation(withCardState: cardValidationState)
            return
        }
        
        cardNumberPublisher.send(cardValidationState)
    }
    
    private func callAPI(withValidationState cardValidationState: PrimerCardValidationState) {
        guard let rawDataManager = rawDataManager else {
            print("[DefaultBinDataService] ERROR: rawDataManager was nil")
            return
        }
        
        delegate?.primerRawDataManager?(rawDataManager,
                                        willFetchCardMetadataForState: cardValidationState)
        
        _ = listCardNetworks(cardValidationState.cardNumber).done { [weak self] result in
            guard result.networks.count > 0 else {
                self?.useLocalValidation(withCardState: cardValidationState)
                return
            }
            let cardMetadata = PrimerCardMetadata(availableCardNetworks: result.networks.map { network in
                PrimerCardNetwork(displayName: network.displayName, networkIdentifier: network.value)
            })
            
            self?.delegate?.primerRawDataManager?(rawDataManager,
                                                  didReceiveCardMetadata: cardMetadata,
                                                  forCardValidationState: cardValidationState)
        }.catch { error in
            // TODO
            print("[DefaultBinDataService] ERROR: \(error.localizedDescription)")
        }
        // TODO: catch: send local validation instead
    }
    
    func useLocalValidation(withCardState cardValidationState: PrimerCardValidationState) {
        guard let rawDataManager = rawDataManager else {
            print("[DefaultBinDataService] ERROR: rawDataManager was nil")
            return
        }

        let localValidationNetwork = CardNetwork(cardNumber: cardValidationState.cardNumber)
        // JN TODO: display name from where?
        let cardNetwork = PrimerCardNetwork(displayName: localValidationNetwork.rawValue, networkIdentifier: localValidationNetwork.rawValue)
        delegate?.primerRawDataManager?(rawDataManager,
                                        didReceiveCardMetadata: .init(availableCardNetworks: [cardNetwork]),
                                        forCardValidationState: cardValidationState)
    }
    
    // MARK: API Logic
    
    var validateCardNetworksCancellable: Cancellable?
    
    private func listCardNetworks(_ cardNumber: String) -> Promise<Response.Body.Bin.Networks> {

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return rejectedPromise(withError: PrimerError.invalidClientToken(userInfo: nil, diagnosticsId: ""))
        }
        
        return Promise { resolver in
            if let cancellable = validateCardNetworksCancellable {
                cancellable.cancel()
            }
            
            validateCardNetworksCancellable = PrimerAPIClient().listCardNetworks(clientToken: decodedJWTToken, bin: cardNumber) { result in
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
