#if canImport(UIKit)

import Foundation

struct ClientTokenValidationRequest: Codable {
    let clientToken: String
}

struct DecodedClientToken: Codable {
    var accessToken: String?
    var analyticsUrl: String?
    var analyticsUrlV2: String?
    var configurationUrl: String?
    var coreUrl: String?
    var env: String?
    var exp: Int?
    var expDate: Date? {
        guard let _exp = exp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(_exp))
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
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Access token is nil"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard let _expDate = expDate else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Expiry date missing"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if _expDate < Date() {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Expiry datetime has passed."], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
}

#endif
