import PassKit

public enum MerchantCapability {
    case capability3DS
    case capabilityEMV
    case capabilityCredit
    case capabilityDebit
}

struct ApplePayRequest {
    var amount: Int?
    var paymentDescriptor: String?
    var currency: Currency
    var merchantIdentifier: String
    var countryCode: CountryCode
    var items: [ApplePayOrderItem]
    var shippingMethods: [PKShippingMethod]?
    var recurringPaymentRequest: ApplePayRecurringPaymentRequest?
    var deferredPaymentRequest: ApplePayDeferredPaymentRequest?
    var automaticReloadRequest: ApplePayAutomaticReloadRequest?
}

protocol ApplePayPaymentRequestBase: Codable {
    var paymentDescription: String? { get }
    var billingAgreement: String? { get }
    var managementUrl: String { get }
    var tokenManagementUrl: String? { get }
}

struct ApplePayPaymentResponse {
    let token: ApplePayPaymentInstrument.PaymentResponseToken
    let billingAddress: ClientSession.Address?
    let shippingAddress: ClientSession.Address?
    let mobileNumber: String?
    let emailAddress: String?
}

struct ApplePayPaymentResponsePaymentMethod: Codable {
    let displayName: String?
    let network: String?
    let type: String?
}

struct ApplePayPaymentResponseTokenPaymentData: Codable {
    let data: String
    let signature: String
    let version: String
    let header: ApplePayTokenPaymentDataHeader
}

struct ApplePayTokenPaymentDataHeader: Codable {
    let ephemeralPublicKey: String
    let publicKeyHash: String
    let transactionId: String
}

struct ApplePayTrialBillingOption: ApplePayBillingBase {
    let label: String
    let amount: Int?
    let recurringStartDate: Double?
    let recurringEndDate: Double?
    let recurringIntervalUnit: ApplePayRecurringInterval?
    let recurringIntervalCount: Int?
}

struct ApplePayDeferredBillingOption: Codable {
    let label: String
    let amount: Int?
    let deferredPaymentDate: Double
}

struct ApplePayAutomaticReloadBillingOption: Codable {
    let label: String
    let amount: Int?
    let automaticReloadThresholdAmount: Int
}

struct ApplePayRecurringPaymentRequest: ApplePayPaymentRequestBase {
    let paymentDescription: String?
    let billingAgreement: String?
    let managementUrl: String
    let regularBilling: ApplePayRegularBillingOption
    let trialBilling: ApplePayTrialBillingOption?
    let tokenManagementUrl: String?
}

struct ApplePayDeferredPaymentRequest: ApplePayPaymentRequestBase {
    let paymentDescription: String?
    let billingAgreement: String?
    let managementUrl: String
    let deferredBilling: ApplePayDeferredBillingOption
    let freeCancellationDate: Double?
    let freeCancellationTimeZone: String?
    let tokenManagementUrl: String?
}

struct ApplePayAutomaticReloadRequest: ApplePayPaymentRequestBase {
    let paymentDescription: String?
    let billingAgreement: String?
    let managementUrl: String
    let automaticReloadBilling: ApplePayAutomaticReloadBillingOption
    let tokenManagementUrl: String?
}

struct ApplePayOptions: PaymentMethodOptions {
    let merchantName: String?
    let recurringPaymentRequest: ApplePayRecurringPaymentRequest?
    let deferredPaymentRequest: ApplePayDeferredPaymentRequest?
    let automaticReloadRequest: ApplePayAutomaticReloadRequest?
}
