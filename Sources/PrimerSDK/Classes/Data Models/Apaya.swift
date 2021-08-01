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
    let ptNumber: String
    let mxNumber: String
    let hashedIdentifier: String
    let mcc: String
    let mnc: String
    let success: String
    let status: String
    let token: String
}

// factory methods
extension ApayaWebViewResult {
    static func create(from url: URL?) -> Result<ApayaWebViewResult, ApayaException> {
        guard
            let url = url,
            let success = url.queryParameterValue(for: "success"),
            let status = url.queryParameterValue(for: "status")
        else {
            return .failure(ApayaException.invalidWebViewResult)
        }
        if (status == "SETUP_ERROR") {
            return .failure(ApayaException.webViewFlowError)
        }
        if (status == "SETUP_ABANDONED") {
            return .failure(ApayaException.webViewFlowCancelled)
        }
        guard
            let ptNumber = url.queryParameterValue(for: "pt"),
            let mxNumber = url.queryParameterValue(for: "MX"),
            let hashedIdentifier = url.queryParameterValue(for: "HashedIdentifier"),
            let mcc = url.queryParameterValue(for: "MCC"),
            let mnc = url.queryParameterValue(for: "MNC"),
            let token = url.queryParameterValue(for: "token"),
            success == "1"
        else {
            return .failure(ApayaException.invalidWebViewResult)
        }

        return .success(
            ApayaWebViewResult(
                ptNumber: ptNumber,
                mxNumber: mxNumber,
                hashedIdentifier: hashedIdentifier,
                mcc: mcc,
                mnc: mnc,
                success: success,
                status: status,
                token: token
            )
        )
    }
}
