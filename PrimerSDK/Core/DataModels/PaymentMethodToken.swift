struct GetVaultedPaymentMethodsResponse: Decodable {
    var data: [PaymentMethodToken]
}

public struct PaymentMethodToken: Codable {
    public var token: String?
    public var analyticsId: String?
    public var tokenType: String?
    public var paymentInstrumentType: PaymentInstrumentType
    public var paymentInstrumentData: PaymentInstrumentData?
    public var vaultData: VaultData
    public var threeDSecureAuthentication: ThreeDSecureAuthentication?
    
    var description: String {
        switch self.paymentInstrumentType {
        case .PAYMENT_CARD:
            let last4 = self.paymentInstrumentData?.last4Digits ?? "••••"
            return "•••• •••• •••• \(last4)"
        case .PAYPAL_ORDER: return "PayPal"
        case .PAYPAL_BILLING_AGREEMENT: return "PayPal"
        case .GOCARDLESS_MANDATE: return "Direct Debit"
        default: return "UNKNOWN"
        }
    }
    
    public var icon: ImageName {
        switch self.paymentInstrumentType {
        case .PAYMENT_CARD:
            guard let network = self.paymentInstrumentData?.network else { return .creditCard }
            switch network {
            case "Visa": return .visa
            default: return .creditCard
            }
        case .PAYPAL_ORDER: return .paypal2
        case .PAYPAL_BILLING_AGREEMENT: return .paypal2
        default: return .creditCard
        }
    }
}

extension PaymentMethodToken {
    var cardButtonViewModel: CardButtonViewModel? {
        switch self.paymentInstrumentType {
        case .PAYMENT_CARD:
            guard let ntwrk = self.paymentInstrumentData?.network else { return nil }
            guard let cardholder = self.paymentInstrumentData?.cardholderName else { return nil }
            guard let last4 = self.paymentInstrumentData?.last4Digits else { return nil }
            guard let expMonth = self.paymentInstrumentData?.expirationMonth else { return nil }
            guard let expYear = self.paymentInstrumentData?.expirationYear else { return nil }
            return CardButtonViewModel(
                network: ntwrk,
                cardholder: cardholder,
                last4: "•••• \(last4)",
                expiry: "Expires".localized() + "\(expMonth)/\(expYear)",
                imageName: self.icon
            )
        case .PAYPAL_BILLING_AGREEMENT:
            guard let cardholder = self.paymentInstrumentData?.externalPayerInfo?.email else { return nil }
            return CardButtonViewModel(network: "PayPal", cardholder: cardholder, last4: "", expiry: "", imageName: self.icon)
        case .GOCARDLESS_MANDATE:
            return CardButtonViewModel(network: "Bank account", cardholder: "", last4: "", expiry: "", imageName: self.icon)
        default:
            return nil
        }
    }
}

struct CardButtonViewModel {
    let network, cardholder, last4, expiry: String
    let imageName: ImageName
}

public enum PaymentInstrumentType: String {
    case PAYPAL_BILLING_AGREEMENT = "PAYPAL_BILLING_AGREEMENT"
    case PAYMENT_CARD = "PAYMENT_CARD"
    case PAYPAL_ORDER = "PAYPAL_ORDER"
    case GOCARDLESS_MANDATE = "GOCARDLESS_MANDATE"
    case UNKNOWN = "UNKNOWN"
}

extension PaymentInstrumentType: Codable {
    public init(from decoder: Decoder) throws {
        self = try PaymentInstrumentType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .UNKNOWN
    }
}

public struct PaymentInstrumentData: Codable {
    public var paypalBillingAgreementId: String?
    public var last4Digits: String?
    public var expirationMonth: String?
    public var expirationYear: String?
    public var cardholderName: String?
    public var network: String?
    public var isNetworkTokenized: Bool?
    public var externalPayerInfo: ExternalPayerInfo?
    public var shippingAddress: ShippingAddress?
    public var binData: BinData?
    public var threeDSecureAuthentication: ThreeDSecureAuthentication?
    public var gocardlessMandateId: String?
}

public struct ExternalPayerInfo: Codable {
    public var externalPayerId, email, firstName, lastName: String?
}

public struct BinData: Codable {
    public var network: String?
    public var issuerCountryCode: String?
    public var issuerName: String?
    public var issuerCurrencyCode: String?
    public var regionalRestriction: String?
    public var accountNumberType: String?
    public var accountFundingType: String?
    public var prepaidReloadableIndicator: String?
    public var productUsageType: String?
    public var productCode: String?
    public var productName: String?
}

public struct VaultData: Codable {
    public var customerId: String?
}

public struct ThreeDSecureAuthentication: Codable {
    public var responseCode, reasonCode, reasonText, protocolVersion, challengeIssued: String?
}
