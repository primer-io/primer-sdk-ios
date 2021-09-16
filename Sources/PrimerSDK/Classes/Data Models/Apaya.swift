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
        let reference: String = "recurring"
        let language: String?
        let currencyCode: String

        enum CodingKeys: String, CodingKey {
            case merchantId = "merchant_id"
            case merchantAccountId = "merchant_account_id"
            case reference = "reference"
            case language = "language"
            case currencyCode = "currency_code"
        }
    }
    public struct CreateSessionAPIResponse: Decodable {
        let url: String
        let token: String?
        let passthroughVariable: String?
    }
    
    public struct WebViewResult {
        
        let mxNumber: String
        let hashedIdentifier: String
        let mcc: String
        let mnc: String
        let success: String
        let status: String
        let productId: String
        
        static func create(from url: URL?) -> Result<Apaya.WebViewResult, ApayaException>? {
            guard
                let url = url,
                url.queryParameterValue(for: "success") != nil,
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
                let mxNumber = url.queryParameterValue(for: "MX"),
                let hashedIdentifier = url.queryParameterValue(for: "HashedIdentifier"),
                let mcc = url.queryParameterValue(for: "MCC"),
                let mnc = url.queryParameterValue(for: "MNC"),
                let success = url.queryParameterValue(for: "success")
            else {
                return .failure(ApayaException.invalidWebViewResult)
            }
            
            let state: AppStateProtocol = DependencyContainer.resolve()
            guard state.decodedClientToken != nil,
                  let merchantAccountId = state.paymentMethodConfig?.getProductId(for: .apaya)
            else {
                return .failure(ApayaException.invalidWebViewResult)
            }
    
            return .success(
                Apaya.WebViewResult(
                    mxNumber: mxNumber,
                    hashedIdentifier: hashedIdentifier,
                    mcc: mcc,
                    mnc: mnc,
                    success: success,
                    status: status,
                    productId: merchantAccountId)
            )
        }
    }
}
