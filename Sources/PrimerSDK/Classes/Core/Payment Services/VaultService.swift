#if canImport(UIKit)

import UIKit

internal protocol VaultServiceProtocol {
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void)
    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void)
}

internal class VaultService: VaultServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.vaultFetchFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        firstly {
            api.vaultFetchPaymentMethods(clientToken: clientToken)
        }
        .done { paymentMethods in
            state.paymentMethods = paymentMethods.data

            let paymentMethods = state.paymentMethods

            if state.selectedPaymentMethod.isEmpty == true && paymentMethods.isEmpty == false {
                guard let id = paymentMethods.first?.token else { return }
                state.selectedPaymentMethod = id
            }
            
            switch Primer.shared.flow {
            case .default,
                 .defaultWithVault:
                let paymentMethodsCount = state.viewModels.count
                let paymentMethodsHeight = CGFloat((46 * paymentMethodsCount) + (16 * (paymentMethodsCount > 0 ? paymentMethodsCount-1 : 0)))
                let vaultCheckoutHeightOffset: CGFloat = Primer.shared.flow.internalSessionFlow.vaulted ? 140 : 320
                let height = vaultCheckoutHeightOffset+paymentMethodsHeight
                Primer.shared.root?.modifyBottomSheetHeight(to: height, animated: true)
                
                // Didn't find a better way
                if Primer.shared.root?.heights.first != nil {
                    Primer.shared.root?.heights[0] = height
                }
            default:
                break
            }
            
            completion(nil)
        }
        .catch { err in
            completion(PrimerError.vaultFetchFailed)
        }
    }

    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.vaultDeleteFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.vaultDeletePaymentMethod(clientToken: clientToken, id: id) { (result) in
            switch result {
            case .failure:
                completion(PrimerError.vaultDeleteFailed)
            case .success:
                completion(nil)
            }
        }
    }
}

#endif
