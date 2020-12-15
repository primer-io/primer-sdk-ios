import UIKit

struct PaymentMethodVM {
    let id: String
    let last4: String
}

protocol UniversalCheckoutProtocol {
    
    var selectedPaymentMethod: String {get set}
    var orderId: String? { get set }
    var uxMode: UXMode {get set}
    var amount: Int {get set}
    var selectedCard: String? { get }
    var paymentMethods: [PaymentMethodVM]? { get }
    
    func showCardForm(_ controller: UIViewController, delegate: ReloadDelegate)
    func showScanner(_ controller: UIViewController & CreditCardDelegate)
    func showCheckout(_ delegate: PrimerCheckoutDelegate) -> Void
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) -> Void
    func reloadVault(_ completion: @escaping (Error?) -> Void) -> Void
    func authorizePayment(
        paymentInstrument: PaymentInstrument?,
        onAuthorizationSuccess: @escaping (Error?) -> Void
    ) -> Void
    func tokenizeCard(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void
    ) -> Void
    func addPaymentMethod(
        request: PaymentMethodTokenizationRequest,
        onSuccess: @escaping (Error?) -> Void
    )
    func deletePaymentMethod(id: String, _ oompletion: @escaping (Error?) -> Void)
    func payWithPayPal(_ completion: @escaping (Result<String, Error>) -> Void)
}
