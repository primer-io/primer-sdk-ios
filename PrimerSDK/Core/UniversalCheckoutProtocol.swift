import UIKit

struct PaymentMethodVM {
    let id: String
    let last4: String
}

protocol UniversalCheckoutProtocol {
    
    var selectedPaymentMethod: String {get set}
    var paymentMethodVMs: [PaymentMethodVM] {get set}
    
    var amount: Int {get set}
    
    func showCardForm(_ controller: UIViewController, delegate: ReloadDelegate)
    func showScanner(_ controller: UIViewController)
    func loadPaymentMethods(_ completion: @escaping (Result<Bool, Error>) -> Void)
    func showCheckout(
        _ delegate: PrimerCheckoutDelegate,
        uxMode: UXMode,
        amount: Int,
        currency: String,
        customerId: String
    ) -> Void
    func loadCheckoutConfig(_ completion: @escaping () -> Void) -> Void
    func authorizePayment(_ completion: @escaping (Result<Bool, Error>) -> Void) -> Void
    func addPaymentMethod(_ oompletion: @escaping () -> Void) -> Void
    func deletePaymentMethod(id: String, _ oompletion: @escaping (Error?) -> Void)
}
