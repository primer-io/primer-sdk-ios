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
    var expDate: Date?
    var intent: String?
    var paymentFlow: String?
    var pciUrl: String?
    var redirectUrl: String?
    var statusUrl: String?
    var threeDSecureInitUrl: String?
    var threeDSecureToken: String?
    var qrCode: String?
    var accountNumber: String?
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken
        case analyticsUrl
        case analyticsUrlV2
        case configurationUrl
        case coreUrl
        case env
        case intent
        case paymentFlow
        case pciUrl
        case redirectUrl
        case statusUrl
        case threeDSecureInitUrl
        case threeDSecureToken
        case qrCode
        case accountNumber
        // Expiration
        case exp
        case expiration
    }
    
    init(
        accessToken: String?,
        expDate: Date?,
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
        qrCode: String?,
        accountNumber: String?
    ) {
        self.accessToken = accessToken
        self.expDate = expDate
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
        self.accountNumber = accountNumber
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try? container.decode(String.self, forKey: .accessToken)
        self.configurationUrl = try? container.decode(String.self, forKey: .configurationUrl)
        self.paymentFlow = try? container.decode(String.self, forKey: .paymentFlow)
        self.threeDSecureInitUrl = try? container.decode(String.self, forKey: .threeDSecureInitUrl)
        self.threeDSecureToken = try? container.decode(String.self, forKey: .threeDSecureToken)
        self.coreUrl = try? container.decode(String.self, forKey: .coreUrl)
        self.pciUrl = try? container.decode(String.self, forKey: .pciUrl)
        self.env = try? container.decode(String.self, forKey: .env)
        self.intent = try? container.decode(String.self, forKey: .intent)
        self.statusUrl = try? container.decode(String.self, forKey: .statusUrl)
        self.redirectUrl = try? container.decode(String.self, forKey: .redirectUrl)
        self.qrCode = try? container.decode(String.self, forKey: .qrCode)
        self.accountNumber = try? container.decode(String.self, forKey: .accountNumber)
        
        // For some APMs we receive another value out of the client token `expiration`
        // They may have different values.
        // We understand this should be changed in the future
        // In the meantime, in case of having both `exp` and `expiration`
        // we let `expiration` take the value of our parameter `expDate`
        // we use thorughout the codebase
        if let expDateInt = try? container.decode(Int.self, forKey: .exp) {
            self.expDate = Date(timeIntervalSince1970: TimeInterval(expDateInt))
        }
        if let expirationDateInt = try? container.decode(Int.self, forKey: .expiration) {
            self.expDate = Date(timeIntervalSince1970: TimeInterval(expirationDateInt))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(accessToken, forKey: .accessToken)
        try? container.encode(configurationUrl, forKey: .configurationUrl)
        try? container.encode(paymentFlow, forKey: .paymentFlow)
        try? container.encode(threeDSecureInitUrl, forKey: .threeDSecureInitUrl)
        try? container.encode(threeDSecureToken, forKey: .threeDSecureToken)
        try? container.encode(coreUrl, forKey: .coreUrl)
        try? container.encode(pciUrl, forKey: .pciUrl)
        try? container.encode(env, forKey: .env)
        try? container.encode(intent, forKey: .intent)
        try? container.encode(statusUrl, forKey: .statusUrl)
        try? container.encode(redirectUrl, forKey: .redirectUrl)
        try? container.encode(qrCode, forKey: .qrCode)
        try? container.encode(accountNumber, forKey: .accountNumber)
        try? container.encode(expDate?.timeIntervalSince1970, forKey: .expiration)
        try? container.encode(expDate?.timeIntervalSince1970, forKey: .exp)
    }
}

extension DecodedClientToken {
    
    func validate() throws {
        if accessToken == nil {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Access token is nil"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
            ErrorHandler.handle(error: err)
            throw err
        }
        
        token = try container.decode(PaymentMethodToken.self, forKey: .token)
        if let token = try? container.decode(String?.self, forKey: .resumeToken) {
            resumeToken = token
        } else {
            resumeToken = nil
        }
    }
}

#endif
