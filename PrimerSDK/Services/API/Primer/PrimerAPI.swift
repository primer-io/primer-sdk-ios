//
//  PrimerAPI.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

enum PrimerAPI: Endpoint {
    case createAccount(createAccountRequestParams: CreateAccountRequestParams)
    case authorizeCheckout
    case listTransactions
}

extension PrimerAPI {
    var baseURL: String {
        switch self {
        case .createAccount,
             .authorizeCheckout,
             .listTransactions:
            #if DEVELOPMENT
            return "localhost"
            #elseif STAGING
            return ""
            #elseif PRODUCTION
            return "api.sandbox.primer.io"
            #else
            fatalError()
            #endif
        }
    }
    
    var scheme: String {
        #if DEVELOPMENT
        return "http"
        #else
        return "https"
        #endif
    }
    
    var port: Int? {
//        return nil
        #if DEVELOPMENT
        switch self {
        case .createAccount:
            return 8090
        case .authorizeCheckout,
             .listTransactions:
            return 8085
        }
        #else
        return nil
        #endif
    }
    
    var path: String {
        switch self {
        case .createAccount:
            return "/accounts"
        case .authorizeCheckout:
            return "/auth/client-token"
        case .listTransactions:
            return "/transactions"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .listTransactions:
            return .get
        case .createAccount,
             .authorizeCheckout:
            return .post
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .authorizeCheckout:
            return [
//                "X-Api-Key": apiKey
                :
            ]
        default:
            return nil
        }
    }
    
    var queryParameters: [String : String]? {
        switch self {
        default:
            return nil
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .createAccount(let createAccountRequestParams):
            var dic: [String: Any] = [
                "userFirstName": createAccountRequestParams.userFirstName,
                "userLastName": createAccountRequestParams.userLastName,
                "userEmail": createAccountRequestParams.userEmail,
                "userPassword": createAccountRequestParams.userPassword
            ]
            
            if let companyName = createAccountRequestParams.companyName {
                dic["companyName"] = companyName
            }
            
            return dic
            
        case .authorizeCheckout,
             .listTransactions:
            return nil
        }
    }
    
}
