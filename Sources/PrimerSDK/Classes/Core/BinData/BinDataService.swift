//
//  BinDataService.swift
//  Pods-Debug App
//
//  Created by Jack Newcombe on 18/10/2023.
//

import Foundation

protocol BinDataService {
    var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? { get }
    func validateCardNetworks(withCardNumber cardNumber: String)
}

class DefaultBinDataService: BinDataService {
    
    let delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
    
    weak var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    
    init(rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
         delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?) {
        self.rawDataManager = rawDataManager
        self.delegate = delegate
    }
    
    func validateCardNetworks(withCardNumber cardNumber: String) {
        guard let rawDataManager = rawDataManager else {
            print("[DefaultBinDataService] ERROR: rawDataManager was nil")
            return
        }
        
        // TODO: proper validation
        guard cardNumber.count > 0 else {
            print("[DefaultBinDataService] WARNING: cardNumber length was zero, so didn't fetch card networks")
            return
        }
        
        let cardValidationState = PrimerCardValidationState(cardNumber: cardNumber)
        delegate?.primerRawDataManager?(rawDataManager,
                                        willFetchCardMetadataForState: cardValidationState)
        
        _ = listCardNetworks(cardNumber).done { [weak self] result in
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
