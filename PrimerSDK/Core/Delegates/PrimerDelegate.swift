import UIKit

public protocol PrimerDelegate: class {
    func clientTokenCallback(_ completion: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) -> Void
    func authorizePayment(_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
    func onCheckoutDismissed() -> Void
}

class MockPrimerDelegate: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) {
        
    }
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        
    }
    
    func onCheckoutDismissed() {
        
    }
}
