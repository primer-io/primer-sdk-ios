#if canImport(UIKit)

import Foundation

extension Request.Body {
    
    struct ClientTokenValidation: Encodable {
        let clientToken: String
    }
}

struct DecodedJWTToken: Codable {
    
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
    var useThreeDsWeakValidation: Bool?
    var supportedThreeDsProtocolVersions: [String]?
    var qrCode: String?
    var accountNumber: String?
    
    // iPay88
    var backendCallbackUrl: String?
    var primerTransactionId: String?
    var iPay88PaymentMethodId: String?
    var iPay88ActionType: String?
    var supportedCurrencyCode: String?
    var supportedCountry: String?
    
    // Voucher info
    var expiresAt: Date?
    var entity: String?
    var reference: String?
    
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
        case useThreeDsWeakValidation
        case supportedThreeDsProtocolVersions
        case accountNumber
        // Expiration
        case exp
        case expiration
        // iPay88
        case backendCallbackUrl
        case primerTransactionId
        case iPay88PaymentMethodId
        case iPay88ActionType
        case supportedCurrencyCode
        case supportedCountry
        // QR Code
        case qrCode
        case qrCodeUrl
        // Voucher info
        case expiresAt
        case entity
        case reference
    }
    
    init(
        accessToken: String?,
        expDate: Date?,
        configurationUrl: String?,
        paymentFlow: String?,
        threeDSecureInitUrl: String?,
        threeDSecureToken: String?,
        supportedThreeDsProtocolVersions: [String]?,
        coreUrl: String?,
        pciUrl: String?,
        env: String?,
        intent: String?,
        statusUrl: String?,
        redirectUrl: String?,
        qrCode: String?,
        accountNumber: String?,
        backendCallbackUrl: String?,
        primerTransactionId: String?,
        iPay88PaymentMethodId: String?,
        iPay88ActionType: String?,
        supportedCurrencyCode: String?,
        supportedCountry: String?
    ) {
        self.accessToken = accessToken
        self.expDate = expDate
        self.configurationUrl = configurationUrl
        self.paymentFlow = paymentFlow
        self.threeDSecureInitUrl = threeDSecureInitUrl
        self.threeDSecureToken = threeDSecureToken
        self.supportedThreeDsProtocolVersions = supportedThreeDsProtocolVersions
        self.coreUrl = coreUrl
        self.pciUrl = pciUrl
        self.env = env
        self.intent = intent
        self.statusUrl = statusUrl
        self.redirectUrl = redirectUrl
        self.qrCode = qrCode
        self.accountNumber = accountNumber
        self.backendCallbackUrl = backendCallbackUrl
        self.primerTransactionId = primerTransactionId
        self.iPay88PaymentMethodId = iPay88PaymentMethodId
        self.iPay88ActionType = iPay88ActionType
        self.supportedCurrencyCode = supportedCurrencyCode
        self.supportedCountry = supportedCountry
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try? container.decode(String.self, forKey: .accessToken)
        self.analyticsUrl = try? container.decode(String.self, forKey: .analyticsUrl)
        self.analyticsUrlV2 = try? container.decode(String.self, forKey: .analyticsUrlV2)
        self.configurationUrl = try? container.decode(String.self, forKey: .configurationUrl)
        self.paymentFlow = try? container.decode(String.self, forKey: .paymentFlow)
        self.threeDSecureInitUrl = try? container.decode(String.self, forKey: .threeDSecureInitUrl)
        self.threeDSecureToken = try? container.decode(String.self, forKey: .threeDSecureToken)
        self.useThreeDsWeakValidation = try? container.decode(Bool.self, forKey: .useThreeDsWeakValidation)
        self.supportedThreeDsProtocolVersions = try container.decodeIfPresent([String].self, forKey: .supportedThreeDsProtocolVersions)
        self.coreUrl = try? container.decode(String.self, forKey: .coreUrl)
        self.pciUrl = try? container.decode(String.self, forKey: .pciUrl)
        self.env = try? container.decode(String.self, forKey: .env)
        self.intent = try? container.decode(String.self, forKey: .intent)
        self.statusUrl = try? container.decode(String.self, forKey: .statusUrl)
        self.redirectUrl = try? container.decode(String.self, forKey: .redirectUrl)
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
        
        // For some APMs we receive one more value out of the client token `qrCode`
        // They may have different values.
        // Either a URL or a Base64 string.
        // In case of `qrCode`, we get the Base64 String
        // In case of `qrCodeUrl`, we get the Image URL
        // We understand this should be changed in the future.
        // However, for now, we evaluate the `qrCode` variable with either URL or Base64
        if let qrCode = try? container.decode(String.self, forKey: .qrCode) {
            self.qrCode = qrCode
        } else if let qrCode = try? container.decode(String.self, forKey: .qrCodeUrl) {
            self.qrCode = qrCode
        }
        
        // iPay88
        self.backendCallbackUrl = try container.decodeIfPresent(String.self, forKey: .backendCallbackUrl)
        self.primerTransactionId = try container.decodeIfPresent(String.self, forKey: .primerTransactionId)
        self.iPay88PaymentMethodId = try container.decodeIfPresent(String.self, forKey: .iPay88PaymentMethodId)
        self.iPay88ActionType = try container.decodeIfPresent(String.self, forKey: .iPay88ActionType)
        self.supportedCurrencyCode = try container.decodeIfPresent(String.self, forKey: .supportedCurrencyCode)
        self.supportedCountry = try container.decodeIfPresent(String.self, forKey: .supportedCountry)
        
        // Voucher info
        if let dateString = try? container.decode(String.self, forKey: .expiresAt) {
            let dateFormatter = DateFormatter().withVoucherExpirationDateFormat()
            self.expiresAt = dateFormatter.date(from: dateString)
        }
        // Voucher info date returned in ISO8601
        if let dateString = try? container.decode(String.self, forKey: .expiresAt) {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = .withFullDate
            self.expiresAt = dateFormatter.date(from: dateString)
        }
        self.reference = try? container.decode(String.self, forKey: .reference)
        self.entity = try? container.decode(String.self, forKey: .entity)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(accessToken, forKey: .accessToken)
        try? container.encode(configurationUrl, forKey: .configurationUrl)
        try? container.encode(paymentFlow, forKey: .paymentFlow)
        try? container.encode(threeDSecureInitUrl, forKey: .threeDSecureInitUrl)
        try? container.encode(threeDSecureToken, forKey: .threeDSecureToken)
        try container.encodeIfPresent(useThreeDsWeakValidation, forKey: .useThreeDsWeakValidation)
        try container.encodeIfPresent(supportedThreeDsProtocolVersions, forKey: .supportedThreeDsProtocolVersions)
        try? container.encode(coreUrl, forKey: .coreUrl)
        try? container.encode(pciUrl, forKey: .pciUrl)
        try? container.encode(env, forKey: .env)
        try? container.encode(intent, forKey: .intent)
        try? container.encode(statusUrl, forKey: .statusUrl)
        try? container.encode(redirectUrl, forKey: .redirectUrl)
        try? container.encode(accountNumber, forKey: .accountNumber)
        try? container.encode(expDate?.timeIntervalSince1970, forKey: .expiration)
        try? container.encode(expDate?.timeIntervalSince1970, forKey: .exp)
        
        if qrCode?.isHttpOrHttpsURL == true {
            try? container.encode(qrCode, forKey: .qrCodeUrl)
        } else {
            try? container.encode(qrCode, forKey: .qrCode)
        }
        
        // iPay88
        try? container.encode(backendCallbackUrl, forKey: .backendCallbackUrl)
        try? container.encode(primerTransactionId, forKey: .primerTransactionId)
        try? container.encode(iPay88PaymentMethodId, forKey: .iPay88PaymentMethodId)
        try? container.encode(iPay88ActionType, forKey: .iPay88ActionType)
        try? container.encode(supportedCurrencyCode, forKey: .supportedCurrencyCode)
        try? container.encode(supportedCountry, forKey: .supportedCountry)
        
        // Voucher info
        try? container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(reference, forKey: .reference)
        try? container.encode(entity, forKey: .entity)
    }
}

extension DecodedJWTToken {
    
    func validate() throws {
        if accessToken == nil {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Access token is nil"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard let expDate = expDate else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Expiry date missing"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if expDate < Date() {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Expiry datetime has passed."], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
}

#endif
