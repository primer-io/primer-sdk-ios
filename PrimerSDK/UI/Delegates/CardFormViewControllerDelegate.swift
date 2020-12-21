import UIKit

protocol AddPaymentMethodDelegate {
    func addPaymentMethod(
        instrument: PaymentInstrument,
        completion: @escaping (Error?) -> Void
    )
}
