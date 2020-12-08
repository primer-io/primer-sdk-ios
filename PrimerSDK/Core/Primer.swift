import UIKit

public struct ClientTokenResponse: Decodable {
    var clientToken: String?
    var expirationDate: String?
}

public struct PrimerTokenizationError: Error {
    let description: String
}

public protocol PrimerCheckoutDelegate {
    func clientTokenCallback(_ completion: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    func authorizePayment(_ result: PaymentMethodToken, _ completion:  @escaping (Result<Bool, Error>) -> Void) -> Void
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

public enum Currency: String {
    case USD
    case GBP
    case EUR
    case SEK
    case NOK
    case DKK
    case CAD
    case JPY
}

public class Primer: NSObject {
    
    public static var authorizePayment: ((_ result: PaymentMethodToken, _ completion:  @escaping (Result<Bool, Error>) -> Void) -> Void)?
    
    // Call this when you want to start a checkout session.
    // This will display a bottom modal sheet with the checkout.
    public static func showCheckout(
        delegate: PrimerCheckoutDelegate,
        paymentMethod: PaymentMethodType,
        amount: Int,
        currency: Currency,
        customerId: String
    ) {
        let context = Context()

        let checkout = UniversalCheckout.init(
            context: context,
            customerId: customerId,
            authPay: delegate.authorizePayment,
            authTokenProvider: nil,
            clientTokenCallback: delegate.clientTokenCallback
        )

        checkout.showCheckout(delegate, uxMode: UXMode.CHECKOUT, amount: amount, currency: currency.rawValue, customerId: customerId)
    }
    
}
