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
    var statusUrl: String?
    var redirectUrl: String?
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    func validate() throws {
        guard !(accessToken ?? "").isEmpty else {
            throw PrimerError.clientTokenNull
        }
        
        guard let expDate = expDate else {
            throw PrimerError.invalidExpiryDate
        }
        
        if expDate < Date() {
            throw PrimerError.clientTokenExpired
        }
        
    }
}
