import UIKit

public protocol PrimerCheckoutDelegate {
    func clientTokenCallback(_ completion: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    func authorizePayment(_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}
