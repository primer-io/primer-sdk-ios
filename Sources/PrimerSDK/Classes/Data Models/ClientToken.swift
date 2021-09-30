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
    let orderDetails: ClientSession.Order?
    let customerDetails: ClientSession.Customer?
    
    
    public struct PaymentMethod: Codable {
        let vaultOnSuccess: Bool
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
    
    public struct Customer: Codable {
        let customerId: String?
        let firstName: String?
        let lastName: String?
        let emailAddress: String?
        let mobileNumber: String?
        let billingAddress: ClientSession.Address?
        let shippingAddress: ClientSession.Address?
        let taxId: String?
    }
    
    public struct Address: Codable {
        let firstName: String?
        let lastName: String?
        let addressLine1: String?
        let addressLine2: String?
        let city: String?
        let postalCode: String?
        let countryCode: CountryCode?
    }
}
