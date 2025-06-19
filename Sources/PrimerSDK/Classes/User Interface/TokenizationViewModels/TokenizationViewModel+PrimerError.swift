extension PrimerError {
    static let applePayTimeout: Self = .applePayTimedOut(userInfo: .errorUserInfoDictionary())
    static let invalidClientToken: Self = .invalidClientToken(userInfo: .errorUserInfoDictionary())
    static let invalidClientSession: Self = .invalidValue(key: "ClientSession", userInfo: .errorUserInfoDictionary())
    static let invalidPCIURL: Self = .invalidValue(key: "decodedClientToken.pciUrl", userInfo: .errorUserInfoDictionary())
    static let invalidConfigID: Self = .invalidValue(key: "configuration.id", userInfo: .errorUserInfoDictionary())
    static let invalidCountryCode: Self = .invalidValue(key: "countryCode", userInfo: .errorUserInfoDictionary())
    static let invalidAppStateCurrency: Self = .invalidValue(key: "currency", userInfo: .errorUserInfoDictionary())
    static let invalidShippingContact: Self = .invalidValue(key: "shippingContact", userInfo: .errorUserInfoDictionary())
    static let invalidShippingMethod: Self = .invalidValue(key: "shippingMethod.identifier", userInfo: .errorUserInfoDictionary())
    static let invalidMerchantID: Self = .invalidMerchantIdentifier(merchantIdentifier: "nil", userInfo: .errorUserInfoDictionary())
    static let vaultNotSupported: Self = .unsupportedIntent(intent: .vault, userInfo: .errorUserInfoDictionary())

    static let applePayCancelled: Self = .cancelled(
        paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
        userInfo: .errorUserInfoDictionary()
    )

    static let emptyLineItems: Self = .invalidValue(
        key: "clientSession.order.lineItems",
        value: "[]",
        userInfo: .errorUserInfoDictionary()
    )

    static let orderOrLineItems: Self = .invalidValue(
        key: "clientSession.order.lineItems or clientSession.order.amount",
        userInfo: .errorUserInfoDictionary()
    )
}
