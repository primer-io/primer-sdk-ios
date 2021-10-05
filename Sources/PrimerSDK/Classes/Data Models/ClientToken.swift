import Foundation

struct DecodedClientToken: Decodable {
    var accessToken: String?
    var exp: Int?
    var expDate: Date? {
        guard let exp = exp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(exp))
    }
    var configurationUrl: String?
    var paymentFlow: String?
    var threeDSecureInitUrl: String?
    var threeDSecureToken: String?
    var coreUrl: String?
    var pciUrl: String?
    var env: String?
    var intent: String?
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    func validate() throws {
        if accessToken == nil {
            throw PrimerError.clientTokenNull
        }
        
        guard let expDate = expDate else {
            throw PrimerError.clientTokenExpirationMissing
        }
        
        if expDate < Date() {
            throw PrimerError.clientTokenExpired
        }
    }
}

public struct ClientSession: Codable {
    let metadata: [String: AnyCodable]
    let paymentMethod: ClientSession.PaymentMethod?
    let orderDetails: Order?
    let customerDetails: Customer?
    
    
    public struct PaymentMethod: Codable {
        let vaultOnSuccess: Bool
    }
}

public struct Customer: Codable {
    let customerId: String?
    let firstName: String?
    let lastName: String?
    let emailAddress: String?
    let mobileNumber: String?
    let billingAddress: Address?
    let shippingAddress: Address?
    let taxId: String?
    
    public init(
        customerId: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        emailAddress: String? = nil,
        mobileNumber: String? = nil,
        billingAddress: Address? = nil,
        shippingAddress: Address? = nil,
        taxId: String? = nil
    ) {
        self.customerId = customerId
        self.firstName = firstName
        self.lastName = lastName
        self.emailAddress = emailAddress
        self.mobileNumber = mobileNumber
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
        self.taxId = taxId
    }
}

public struct Address: Codable {
    let firstName: String?
    let lastName: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let postalCode: String?
    let state: String?
    let countryCode: CountryCode?
    
    public init(
        firstName: String? = nil,
        lastName: String? = nil,
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        city: String? = nil,
        postalCode: String? = nil,
        state: String? = nil,
        countryCode: CountryCode? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.postalCode = postalCode
        self.state = state
        self.countryCode = countryCode
    }
    
    public func toString() -> String {
        return "\(addressLine1 ?? "")\(addressLine2?.withComma ?? "")\(city?.withComma ?? "")\(postalCode?.withComma ?? "")\(countryCode?.rawValue.withComma ?? "")"
    }
}

internal extension String {
    var withComma: String {
        if self.isEmpty { return "" }
        return ", " + self
    }
}

public struct Order: Codable {
    let totalAmount: UInt?
    let totalTaxAmount: UInt?
    let countryCode: CountryCode?
    let currencyCode: Currency?

    let items: [LineItem]
    let shippingAmount: UInt?
    
    public struct LineItem: Codable {
        let quantity: Int?
        let unitAmount: UInt?
        let reference: String?
        let name: String?
    }
}
