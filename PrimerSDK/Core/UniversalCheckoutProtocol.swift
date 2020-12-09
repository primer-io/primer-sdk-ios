import UIKit

struct PaymentMethodVM {
    let id: String
    let last4: String
}

protocol UniversalCheckoutProtocol {
    
    var selectedPaymentMethod: String {get set}
    var paymentMethodVMs: [PaymentMethodVM] {get set}
    
    var uxMode: UXMode {get set}
    var amount: Int {get set}
    
    func showCardForm(_ controller: UIViewController, delegate: ReloadDelegate)
    func showScanner(_ controller: UIViewController & CreditCardDelegate)
    func loadPaymentMethods(_ onTokenizeSuccess: @escaping (Error?) -> Void)
    func showCheckout(
        _ delegate: PrimerCheckoutDelegate,
        uxMode: UXMode,
        amount: Int,
        currency: String,
        customerId: String?
    ) -> Void
    func loadCheckoutConfig(_ completion: @escaping (Result<ClientToken, Error>) -> Void) -> Void
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
}
