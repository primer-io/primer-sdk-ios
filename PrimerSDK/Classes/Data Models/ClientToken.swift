struct DecodedClientToken: Decodable {
    var accessToken: String?
    var configurationUrl: String?
    var paymentFlow: String?
    var threeDSecureInitUrl: String?
    var threeDSecureToken: String?
    var coreUrl: String?
    var pciUrl: String?
    var env: String?
}

public struct CreateClientTokenResponse: Decodable {
    var clientToken: String?
    var expirationDate: String?
}
