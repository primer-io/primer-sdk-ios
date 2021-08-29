//
//  Apaya.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 27/07/2021.
//

public struct Apaya {
    public struct CreateSessionAPIRequest: Encodable {
        let merchantId: String
        let merchantAccountId: String
        let reference: String = "scooter ride"
        let language: String? = "en"

        enum CodingKeys: String, CodingKey {
            case merchantId = "merchant_id"
            case merchantAccountId = "merchant_account_id"
            case reference = "reference"
            case language = "language"
        }
    }
    public struct CreateSessionAPIResponse: Decodable {
        let url: String?
        let token: String?
        let pt: String?
    }

    public struct WebViewResult {
        let ptNumber: String
        let mxNumber: String
        let hashedIdentifier: String
        let mcc: String
        let mnc: String
        let success: String
        let status: String
        let token: String
    }
}

// factory methods
extension Apaya.WebViewResult {
    static func create(from url: URL?) -> Result<Apaya.WebViewResult, ApayaException>? {
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
            return nil
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
            Apaya.WebViewResult(
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
