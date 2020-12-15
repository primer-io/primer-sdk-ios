import UIKit

public struct ClientTokenResponse: Decodable {
    var clientToken: String?
    var expirationDate: String?
}

public class Primer: NSObject {
    public static func showCheckout(
        delegate: PrimerCheckoutDelegate,
        mode: UXMode,
        paymentMethod: PaymentMethodType,
        amount: Int,
        currency: Currency,
        customerId: String? = nil
    ) {
        let checkout = UniversalCheckout.init(
            customerId: customerId,
            amount: amount,
            currency: currency,
            uxMode: mode,
            onTokenizeSuccess: delegate.authorizePayment,
            authTokenProvider: nil,
            clientTokenCallback: delegate.clientTokenCallback
        )

        checkout.showCheckout(delegate)
    }
}
