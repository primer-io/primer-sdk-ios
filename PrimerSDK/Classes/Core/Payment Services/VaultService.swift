import Foundation

protocol VaultServiceProtocol {
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void)
    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void)
}

class VaultService: VaultServiceProtocol {
    
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var api: PrimerAPIClientProtocol
        
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.VaultFetchFailed)
        }
        
        api.vaultFetchPaymentMethods(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure:
                completion(PrimerError.VaultFetchFailed)
            case .success(let paymentMethods):
                print("Response: \(paymentMethods)")
                self?.state.paymentMethods = paymentMethods.data
                
                guard let paymentMethods = self?.state.paymentMethods else { return }
                
                if (self?.state.selectedPaymentMethod.isEmpty == true && paymentMethods.isEmpty == false) {
                    guard let id = paymentMethods[0].token else { return }
                    self?.state.selectedPaymentMethod = id
                }
                
                completion(nil)
            }
        }
    }
    
    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.VaultDeleteFailed)
        }
        
        api.vaultDeletePaymentMethod(clientToken: clientToken, id: id) { (result) in
            switch result {
            case .failure:
                completion(PrimerError.VaultDeleteFailed)
            case .success:
                completion(nil)
            }
        }
    }
}
