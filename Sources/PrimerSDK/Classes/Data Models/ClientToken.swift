import Foundation

struct DecodedClientToken: Decodable {
    var accessToken: String
    var exp: Int
    var expDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(exp))
    }
    var configurationUrlStr: String?
    var configurationUrl: URL? {
        guard let configurationUrlStr = configurationUrlStr else { return nil }
        return URL(string: configurationUrlStr)
    }
    var coreUrlStr: String?
    var coreUrl: URL? {
        guard let coreUrlStr = coreUrlStr else { return nil }
        return URL(string: coreUrlStr)
    }
    var pciUrlStr: String?
    var pciUrl: URL? {
        guard let pciUrlStr = pciUrlStr else { return nil }
        return URL(string: pciUrlStr)
    }
    var threeDSecureInitUrlStr: String?
    var threeDSecureInitUrl: URL? {
        guard let threeDSecureInitUrlStr = threeDSecureInitUrlStr else { return nil }
        return URL(string: threeDSecureInitUrlStr)
    }
    var statusUrlStr: String?
    var statusUrl: URL? {
        guard let statusUrlStr = statusUrlStr else { return nil }
        return URL(string: statusUrlStr)
    }
    var redirectUrlStr: String?
    var redirectUrl: URL? {
        guard let redirectUrlStr = redirectUrlStr else { return nil }
        return URL(string: redirectUrlStr)
    }
    
    var paymentFlow: String?
    var threeDSecureToken: String?
    var env: String?
    var intent: String?
    
    
    enum CodingKeys: String, CodingKey {
        case accessToken
        case exp
        case configurationUrlStr = "configurationUrl"
        case coreUrlStr = "coreUrl"
        case pciUrlStr = "pciUrl"
        case threeDSecureInitUrlStr = "threeDSecureInitUrl"
        case statusUrlStr = "statusUrl"
        case redirectUrlStr = "redirect"
        case paymentFlow
        case threeDSecureToken
        case env
        case intent
    }
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    func validate() throws {
        guard !accessToken.isEmpty else {
            throw PrimerError.clientTokenNull
        }

        if expDate < Date() {
            throw PrimerError.clientTokenExpired
        }
        
    }
}
