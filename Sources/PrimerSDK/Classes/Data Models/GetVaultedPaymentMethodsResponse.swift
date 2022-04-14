#if canImport(UIKit)

import Foundation

struct GetVaultedPaymentMethodsResponse: Decodable {
    var data: [PaymentMethod.Tokenization.Response]
}

#endif
