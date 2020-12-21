import UIKit

public struct ClientTokenResponse: Decodable {
    var clientToken: String?
    var expirationDate: String?
}

public class Primer {
    public static func showCheckout(
        _ controller: UIViewController,
        delegate: PrimerCheckoutDelegate,
        mode: UXMode,
        paymentMethod: PaymentMethodType,
        amount: Int,
        currency: Currency,
        merchantIdentifier: String,
        countryCode: CountryCode,
        applePayEnabled: Bool? = nil,
        customerId: String? = nil
    ) {
        let checkout = CheckoutContext(
            customerId: customerId,
            merchantIdentifier: merchantIdentifier,
            countryCode: countryCode,
            applePayEnabled: applePayEnabled ?? true,
            amount: amount,
            currency: currency,
            uxMode: mode,
            onTokenizeSuccess: delegate.authorizePayment,
            authTokenProvider: nil,
            clientTokenCallback: delegate.clientTokenCallback
        )

        checkout.showCheckout(controller)
    }
}
