//
//  Apaya.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 27/07/2021.
//

#if canImport(UIKit)

import Foundation

public struct Apaya {
    public struct CreateSessionAPIRequest: Encodable {
        let merchantAccountId: String
        let reference: String = "recurring"
        let language: String?
        let currencyCode: String
        let phoneNumber: String?

        enum CodingKeys: String, CodingKey {
            case merchantAccountId = "merchant_account_id"
            case reference = "reference"
            case language = "language"
            case currencyCode = "currency_code"
            case phoneNumber = "phone_number"
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
        
        static func create(from url: URL?) -> Result<Apaya.WebViewResult, Error> {
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
                return .failure(ApayaException.webViewFlowCancelled)
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
    
    class ViewModel {
        
        var carrier: Apaya.Carrier
        var hashedIdentifier: String?
        
        init?(paymentMethod: PaymentMethodToken) {
            guard paymentMethod.paymentInstrumentType == .apayaToken else { return nil }
            guard let mcc = paymentMethod.paymentInstrumentData?.mcc,
                  let mnc = paymentMethod.paymentInstrumentData?.mnc,
                  let carrier = Apaya.Carrier(mcc: mcc, mnc: mnc)
            else { return nil }
            
            self.carrier = carrier
            self.hashedIdentifier = paymentMethod.paymentInstrumentData?.hashedIdentifier
        }
        
    }

    enum Carrier: String, Codable {
        // swiftlint:disable identifier_name
        case EE_UK, O2_UK, Vodafone_UK, Three_UK, Strex_Norway
        // swiftlint:enable identifier_name
        
        var name: String {
            switch self {
            case .EE_UK:
                return "EE UK"
            case .O2_UK:
                return "O2 UK"
            case .Vodafone_UK:
                return "Vodafone UK"
            case .Three_UK:
                return "Three UK"
            case .Strex_Norway:
                return "Strex Norway"
            }
        }
        
        var mcc: Int {
            switch self {
            case .EE_UK:
                return 234
            case .O2_UK:
                return 234
            case .Vodafone_UK:
                return 234
            case .Three_UK:
                return 234
            case .Strex_Norway:
                return 242
            }
        }
        
        var mnc: Int {
            switch self {
            case .EE_UK:
                return 99
            case .O2_UK:
                return 11
            case .Vodafone_UK:
                return 15
            case .Three_UK:
                return 20
            case .Strex_Norway:
                return 99
            }
        }
        
        init?(mcc: Int, mnc: Int) {
            switch (mcc, mnc) {
            case (234, 99):
                self = .EE_UK
            case (234, 11):
                self = .O2_UK
            case (234, 15):
                self = .Vodafone_UK
            case (234, 20):
                self = .Three_UK
            case (242, 99):
                self = .Strex_Norway
            default:
                return nil
            }
        }
        
    }
}

#endif
