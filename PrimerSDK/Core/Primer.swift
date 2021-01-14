import UIKit

public class Primer {
    
    static var flow: PrimerSessionFlow = .completeDirectCheckout
    
    private var rootViewController: RootViewController {
        let vc = RootViewController.init(context)
        return vc
    }
    private let context: CheckoutContext
    
    public init(with settings: PrimerSettings) {
        
        let serviceLocator = ServiceLocator(settings: settings)
        let viewModelLocator = ViewModelLocator(with: serviceLocator, and: settings)
        
        self.context = CheckoutContext.init(with: settings, and: serviceLocator, and: viewModelLocator)
    }
    
    public func showCheckout(_ controller: UIViewController, flow: PrimerSessionFlow) {
        Primer.flow = flow
        controller.present(rootViewController, animated: true)
    }
    
    public func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        guard let clientToken = context.serviceLocator.clientTokenService.decodedClientToken else {
            return fetchClientToken(then: { [weak self] result in
                switch result {
                case .failure(let error): completion(.failure(error))
                case .success(let clientToken): self?.fetchVaultedPaymentMethods(with: clientToken, then: completion)
                }
            })
        }
        fetchVaultedPaymentMethods(with: clientToken, then: completion)
    }
    
    private func fetchClientToken(then completion: @escaping (Result<ClientToken, Error>) -> Void) {
        context.serviceLocator.clientTokenService.loadCheckoutConfig(with: { [weak self] error in
            if let error = error { completion(.failure(error)) }
            
            guard let clientToken = self?.context.serviceLocator.clientTokenService.decodedClientToken else { return }
            
            completion(.success(clientToken))
        })
    }
    
    private func fetchVaultedPaymentMethods(
        with clientToken: ClientToken,
        then completion: @escaping (Result<[PaymentMethodToken], Error>
    ) -> Void) {
        context.serviceLocator.vaultService.loadVaultedPaymentMethods(with: clientToken, and: { [weak self] error in
            if let error = error { completion(.failure(error)) }
            
            guard let paymentMethods = self?.context.serviceLocator.vaultService.paymentMethods else { return }
            
            completion(.success(paymentMethods))
        })
    }
    
}
