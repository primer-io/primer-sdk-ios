//
//  Apaya.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 27/07/2021.
//

public struct ApayaCreateSessionAPIRequest: Encodable {
    let locale: String
    let itemDescription: String
    
    init(locale: String, itemDescription: String) {
        self.locale = locale
        self.itemDescription = itemDescription
    }
}

public struct ApayaCreateSessionAPIResponse: Decodable {
    let redirectUrl: String
    let token: String
    let passthroughVariable: String
    
    init(
        redirectUrl: String,
        token: String,
        passthroughVariable: String
    ) {
        self.redirectUrl = redirectUrl
        self.token = token
        self.passthroughVariable = passthroughVariable
    }
}

struct ApayaWebViewResult {
    let pt: String?
    let mx: String?
    let hashedIdentifier: String?
    let mcc: String?
    let mnc: String?
    let success: String
    let status: String
    let token: String?
    
    init(from url: URL) throws {
        guard
            let success = url.queryParameterValue(for: "success"),
            let status = url.queryParameterValue(for: "status")
        else {
            throw ApayaException.invalidWebViewResult
        }
        self.success = success
        self.status = status
        pt = url.queryParameterValue(for: "pt")
        mx = url.queryParameterValue(for: "MX")
        hashedIdentifier = url.queryParameterValue(for: "HashedIdentifier")
        mcc = url.queryParameterValue(for: "MCC")
        mnc = url.queryParameterValue(for: "MNC")
        token = url.queryParameterValue(for: "token")
    }
}
