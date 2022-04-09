#if canImport(UIKit)

import Foundation

struct GetVaultedPaymentMethodsResponse: Decodable {
    var data: [PaymentMethod.Tokenization.Response]
}

public struct VaultData: Codable {
    public var customerId: String
}

#endif
