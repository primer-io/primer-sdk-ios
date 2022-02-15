#if canImport(UIKit)

import Foundation

struct DecodedClientToken: Codable {
    var accessToken: String?
    var analyticsUrl: String?
    var analyticsUrlV2: String?
    var configurationUrl: String?
    var coreUrl: String?
    var env: String?
    var exp: Int?
    var expDate: Date? {
        guard let exp = exp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(exp))
    }
    var intent: String?
    var paymentFlow: String?
    var pciUrl: String?
    var redirectUrl: String?
    var statusUrl: String?
    var threeDSecureInitUrl: String?
    var threeDSecureToken: String?
    var qrCode: String?

    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    init(
        accessToken: String?,
        exp: Int?,
        configurationUrl: String?,
        paymentFlow: String?,
        threeDSecureInitUrl: String?,
        threeDSecureToken: String?,
        coreUrl: String?,
        pciUrl: String?,
        env: String?,
        intent: String?,
        statusUrl: String?,
        redirectUrl: String?,
        qrCode: String?
    ) {
        self.accessToken = accessToken
        self.exp = exp
        self.configurationUrl = configurationUrl
        self.paymentFlow = paymentFlow
        self.threeDSecureInitUrl = threeDSecureInitUrl
        self.threeDSecureToken = threeDSecureToken
        self.coreUrl = coreUrl
        self.pciUrl = pciUrl
        self.env = env
        self.intent = intent
        self.statusUrl = statusUrl
        self.redirectUrl = redirectUrl
        self.qrCode = qrCode
    }
    
    func validate() throws {
        if accessToken == nil {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard let expDate = expDate else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if expDate < Date() {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
    }
}

//public struct Customer: Codable {
//    var id: String?
//    var firstName: String?
//    var lastName: String?
//    var email: String?
//    var mobileNumber: String?
//    var billingAddress: Address?
//    var shippingAddress: Address?
//    var taxId: String?
//    
//    enum CodingKeys: String, CodingKey {
//        case id, firstName, lastName, email, mobileNumber, billingAddress, shippingAddress, taxId
//    }
//    
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = (try? container.decode(String?.self, forKey: .id)) ?? nil
//        self.firstName = (try? container.decode(String?.self, forKey: .firstName)) ?? nil
//        self.lastName = (try? container.decode(String?.self, forKey: .lastName)) ?? nil
//        self.email = (try? container.decode(String?.self, forKey: .email)) ?? nil
//        self.mobileNumber = (try? container.decode(String?.self, forKey: .mobileNumber)) ?? nil
//        self.billingAddress = (try? container.decode(Address?.self, forKey: .billingAddress)) ?? nil
//        self.shippingAddress = (try? container.decode(Address?.self, forKey: .shippingAddress)) ?? nil
//        self.taxId = (try? container.decode(String?.self, forKey: .taxId)) ?? nil
//    }
//    
//    public init(
//        id: String? = nil,
//        firstName: String? = nil,
//        lastName: String? = nil,
//        email: String? = nil,
//        mobileNumber: String? = nil,
//        billingAddress: Address? = nil,
//        shippingAddress: Address? = nil,
//        taxId: String? = nil
//    ) {
//        self.id = id
//        self.firstName = firstName
//        self.lastName = lastName
//        self.email = email
//        self.mobileNumber = mobileNumber
//        self.billingAddress = billingAddress
//        self.shippingAddress = shippingAddress
//        self.taxId = taxId
//    }
//    
//}

//public struct Address: Codable {
//    let firstName: String?
//    let lastName: String?
//    let addressLine1: String?
//    let addressLine2: String?
//    let city: String?
//    let postalCode: String?
//    let state: String?
//    let countryCode: CountryCode?
//    
//    enum CodingKeys: String, CodingKey {
//        case firstName = "first_name"
//        case lastName = "last_name"
//        case addressLine1 = "address_line_1"
//        case addressLine2 = "address_line_2"
//        case city
//        case postalCode = "postal_code"
//        case state
//        case countryCode = "country_code"
//    }
//    
//    public init(
//        firstName: String? = nil,
//        lastName: String? = nil,
//        addressLine1: String? = nil,
//        addressLine2: String? = nil,
//        city: String? = nil,
//        postalCode: String? = nil,
//        state: String? = nil,
//        countryCode: CountryCode? = nil
//    ) {
//        self.firstName = firstName
//        self.lastName = lastName
//        self.addressLine1 = addressLine1
//        self.addressLine2 = addressLine2
//        self.city = city
//        self.postalCode = postalCode
//        self.state = state
//        self.countryCode = countryCode
//    }
//    
//    public func toString() -> String {
//        return "\(addressLine1 ?? "")\(addressLine2?.withComma ?? "")\(city?.withComma ?? "")\(postalCode?.withComma ?? "")\(countryCode?.rawValue.withComma ?? "")"
//    }
//}

#endif
