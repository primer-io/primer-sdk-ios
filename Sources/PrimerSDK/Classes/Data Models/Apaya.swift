//
//  Apaya.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 27/07/2021.
//

#if canImport(UIKit)

import Foundation

extension Request.Body {
    class Apaya {}
}

extension Response.Body {
    class Apaya {}
}

extension Request.Body.Apaya {
    
    public struct CreateSession: Encodable {
        
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
}


extension Response.Body.Apaya {
    
    public struct CreateSession: Decodable {
        
        let url: String
        let token: String?
        let passthroughVariable: String?
    }
}

public struct Apaya {
    
    public struct WebViewResponse {
        
        let hashedIdentifier: String
        let mcc: String
        let mnc: String
        let mxNumber: String
        let productId: String
        let status: String
        let success: String
        
        
        init(url: URL) throws {
            guard
                url.queryParameterValue(for: "success") != nil,
                let status = url.queryParameterValue(for: "status")
            else {
                let err = PrimerError.generic(
                    message: "Failed to find query parameters: [status, success]",
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw PrimerError.failedOnWebViewFlow(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            }
            
            if status == "SETUP_ERROR" {
                let err = PrimerError.generic(
                    message: "Apaya status is SETUP_ERROR",
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw PrimerError.failedOnWebViewFlow(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                
            } else if status == "SETUP_ABANDONED" {
                let err = PrimerError.cancelled(
                    paymentMethodType: PrimerPaymentMethodType.apaya.rawValue,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            guard
                let mxNumber = url.queryParameterValue(for: "MX"),
                let hashedIdentifier = url.queryParameterValue(for: "HashedIdentifier"),
                let mcc = url.queryParameterValue(for: "MCC"),
                let mnc = url.queryParameterValue(for: "MNC"),
                let success = url.queryParameterValue(for: "success")
            else {
                let err = PrimerError.invalidValue(
                    key: "apaya-params", value: nil,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
                let err = PrimerError.invalidClientToken(
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            guard let merchantAccountId = PrimerAPIConfigurationModule.apiConfiguration?.getProductId(for: PrimerPaymentMethodType.apaya.rawValue) else {
                let err = PrimerError.invalidValue(
                    key: "apaya-merchantAccountId",
                    value: nil,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
    
            self.hashedIdentifier = hashedIdentifier
            self.mcc = mcc
            self.mnc = mnc
            self.mxNumber = mxNumber
            self.productId = merchantAccountId
            self.status = status
            self.success = success
        }
    }
    
    class ViewModel {
        var carrier: Apaya.Carrier
        var hashedIdentifier: String?
        
        init?(paymentMethod: PrimerPaymentMethodTokenData) {
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
