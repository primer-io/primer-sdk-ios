//
//  APM.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/9/21.
//

import Foundation

protocol APMProtocol {
    var name: String { get }
    var apmRequest: APMRequest { get }
    var apmResponse: [String: Any]? { get set }
    var tokenizationRequest: GenericRequest { get }
    func tokenize() -> Promise<PaymentMethodToken>
    var tokenizationResponse: PaymentMethodToken? { get set }
}

protocol APMWebBasedProtocol: APMProtocol {
    
    var createSessionRequest: GenericRequest { get }
    var createSessionResponse: APMCreateSessionResponseProtocol? { get set }
    func createSession() -> Promise<APMCreateSessionResponseProtocol>
    
    var allowedHosts: [String] { get }
    var redirectUrlSchemePrefix: String? { get }
    
    var preTokenizationRequest: GenericRequest? { get }
    var preTokenizationResponse: Dictionary<String, Any?>? { get set }
    func preTokenize() -> Promise<Dictionary<String, Any?>?>

}

struct GenericRequest {
    var clientToken: String
    var baseUrl: String
    var endpoint: String
    var method: HTTPMethod
    var headers: [String: String]?
    var queryParameters: [String: String]?
    var bodyParameters: BodyParameters?
    var body: Data?
}


class APM {
    
    class WebBased: APMWebBasedProtocol {
        var apmRequest: APMRequest {
            var request = URLRequest(url: self.createSessionResponse!.webViewUrl!)
            request.timeoutInterval = 60
            request.allHTTPHeaderFields = [
                "Primer-SDK-Version": "1.0.0-beta.0",
                "Primer-SDK-Client": "IOS_NATIVE"
            ]
            return request as! APMRequest
        }
        

        var name: String
        var createSessionRequest: GenericRequest
        var createSessionResponse: APMCreateSessionResponseProtocol?
        var allowedHosts: [String]
        var apmResponse: [String: Any]?
        var redirectUrlSchemePrefix: String?
        var preTokenizationRequest: GenericRequest?
        var preTokenizationResponse: Dictionary<String, Any?>?
        var tokenizationRequest: GenericRequest
        var tokenizationResponse: PaymentMethodToken?
            
        init(name: String, createSessionRequest: GenericRequest, allowedHosts: [String], tokenizationRequest: GenericRequest) {
            self.name = name
            self.createSessionRequest = createSessionRequest
            self.allowedHosts = allowedHosts
            self.tokenizationRequest = tokenizationRequest
        }
        
        func createSession() -> Promise<APMCreateSessionResponseProtocol> {
            return Promise { seal in
                createSessionRequest.body = try? JSONSerialization.data(withJSONObject: APM.createDictionary(for: self, with: createSessionRequest.bodyParameters), options: .fragmentsAllowed)
                                        
                let apiClient = PrimerAPIClient()
                apiClient.generic(req: createSessionRequest) { result in
                    switch result {
                    case .success(let data):
                        if let res = try? JSONParser().parse(KlarnaCreateSessionResponse.self, from: data) {
                            self.createSessionResponse = res
                            seal.fulfill(res)
                        } else if let res = try? JSONParser().parse(ApayaCreateSessionResponse.self, from: data) {
                            self.createSessionResponse = res
                            seal.fulfill(res)
                        } else {
                            seal.reject(PrimerError.generic)
                        }
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
        
        func preTokenize() -> Promise<Dictionary<String, Any?>?> {
            return Promise { seal in
                guard var preTokenizationRequest = preTokenizationRequest else {
                    seal.fulfill(nil)
                    return
                }
                
                preTokenizationRequest.body = try? JSONSerialization.data(withJSONObject: APM.createDictionary(for: self, with: preTokenizationRequest.bodyParameters), options: .fragmentsAllowed)
                                        
                let apiClient = PrimerAPIClient()
                apiClient.generic(req: preTokenizationRequest) { result in
                    switch result {
                    case .success(let data):
                        let res = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any?]
                        self.preTokenizationResponse = res
                        seal.fulfill(res)
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
        
        internal func tokenize() -> Promise<PaymentMethodToken> {
            return Promise { seal in
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                guard let clientToken = state.decodedClientToken else {
                    seal.reject(PrimerError.tokenizationPreRequestFailed)
                    return
                }
                

                tokenizationRequest.body = try? JSONSerialization.data(withJSONObject: APM.createDictionary(for: self, with: tokenizationRequest.bodyParameters), options: .fragmentsAllowed)
                
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.generic(req: tokenizationRequest) { result in
                    switch result {
                    case .success(let data):
                        do {
                            let res = try JSONParser().parse(PaymentMethodToken.self, from: data)
                            self.tokenizationResponse = res
                            seal.fulfill(res)
                        } catch {
                            seal.reject(error)
                        }
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
    }
    
    class SDKBased {
        
    }
    
}

extension APM.WebBased {
    
    static func createKlarnaVaultAPM() throws -> APM.WebBased {
        let allowedHosts: [String] = ["primer.io", "livedemostore.primer.io", "api.playground.klarna.com",  "api.sandbox.primer.io"]
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard
            let decodedClientToken = state.decodedClientToken,
            let accessToken = decodedClientToken.accessToken,
            let coreUrl = decodedClientToken.coreUrl,
            let pciUrl = decodedClientToken.pciUrl
        else {
            throw PrimerError.generic
        }
        
        // Klarna checkout
        //        sessionRequestBodyParameters = BodyParameters(
        //            requiredParameters: [
//                "totalAmount": nil,
//                "orderItems": nil,
//                "orderItems.unitAmount": nil,
//                "sessionType": "HOSTED_PAYMENT_PAGE",
//                "localeData": nil,
//                "redirectUrl": "https://primer.io/success",
//                "paymentMethodConfigId": nil
//            ],
//            optionalParameters: [
//                "description"
//            ])
        
        let createSessionBodyParameters = BodyParameters(
            requiredParameters: [
                "sessionType": "RECURRING_PAYMENT",
                "localeData": nil,
                "redirectUrl": "https://primer.io/success",
                "description": nil,
                "paymentMethodConfigId": nil
            ],
            optionalParameters: [
                "totalAmount",
                "orderItems"
            ])
        
        let createSessionRequest = GenericRequest(
            clientToken: accessToken,
            baseUrl: coreUrl,
            endpoint: "/klarna/payment-sessions",
            method: .post,
            headers: nil,
            queryParameters: nil,
            bodyParameters: createSessionBodyParameters,
            body: nil)
        
        let tokenizationRequestBodyParameters = BodyParameters(
            requiredParameters: [
                "instrument": [
                    "klarnaCustomerToken": nil,
                    "sessionData": nil
                ],
                "tokenType": nil,
                "paymentFlow": nil,
                "customerId": nil,
            ],
            optionalParameters: [])
        
        let tokenizationRequest = GenericRequest(
            clientToken: accessToken,
            baseUrl: pciUrl,
            endpoint: "/payment-instruments",
            method: .post,
            headers: nil,
            queryParameters: nil,
            bodyParameters: tokenizationRequestBodyParameters,
            body: nil)
        
        let apm = APM.WebBased(
            name: ConfigPaymentMethodType.klarna.rawValue,
            createSessionRequest: createSessionRequest,
            allowedHosts: allowedHosts,
            tokenizationRequest: tokenizationRequest)
        
        let preTokenizationRequestBodyParameters = BodyParameters(
            requiredParameters: [
                "paymentMethodConfigId": nil,
                "sessionId": nil,
                "authorizationToken": nil,
                "description": nil,
                "localeData": nil,
            ],
            optionalParameters: [])
        
        let preTokenizationRequest = GenericRequest(
            clientToken: accessToken,
            baseUrl: coreUrl,
            endpoint: "/klarna/customer-tokens",
            method: .post,
            headers: nil,
            queryParameters: nil,
            bodyParameters: preTokenizationRequestBodyParameters,
            body: nil)
        
        apm.preTokenizationRequest = preTokenizationRequest
        return apm
    }
    
    static func createKlarnaCheckoutAPM() throws -> APM.WebBased {
        let allowedHosts: [String] = ["primer.io", "livedemostore.primer.io", "api.playground.klarna.com",  "api.sandbox.primer.io"]
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard
            let decodedClientToken = state.decodedClientToken,
            let accessToken = decodedClientToken.accessToken,
            let coreUrl = decodedClientToken.coreUrl,
            let pciUrl = decodedClientToken.pciUrl
        else {
            throw PrimerError.generic
        }
        
        let createSessionBodyParameters = BodyParameters(
            requiredParameters: [
                "totalAmount": nil,
                "orderItems": nil,
                "orderItems.unitAmount": nil,
                "sessionType": "HOSTED_PAYMENT_PAGE",
                "localeData": nil,
                "redirectUrl": "https://primer.io/success",
                "paymentMethodConfigId": nil
            ],
            optionalParameters: [
                "description"
            ])
        
        let createSessionRequest = GenericRequest(
            clientToken: accessToken,
            baseUrl: coreUrl,
            endpoint: "/klarna/payment-sessions",
            method: .post,
            headers: nil,
            queryParameters: nil,
            bodyParameters: createSessionBodyParameters,
            body: nil)
        
        let tokenizationRequestBodyParameters = BodyParameters(
            requiredParameters: [
                "instrument": [
                    "klarnaCustomerToken": nil,
                    "sessionData": nil
                ],
                "tokenType": nil,
                "paymentFlow": nil,
                "customerId": nil,
            ],
            optionalParameters: [])
        
        let tokenizationRequest = GenericRequest(
            clientToken: accessToken,
            baseUrl: pciUrl,
            endpoint: "/payment-instruments",
            method: .post,
            headers: nil,
            queryParameters: nil,
            bodyParameters: tokenizationRequestBodyParameters,
            body: nil)
        
        let apm = APM.WebBased(
            name: ConfigPaymentMethodType.klarna.rawValue,
            createSessionRequest: createSessionRequest,
            allowedHosts: allowedHosts,
            tokenizationRequest: tokenizationRequest)
        
        let preTokenizationRequestBodyParameters = BodyParameters(
            requiredParameters: [
                "paymentMethodConfigId": nil,
                "sessionId": nil,
                "authorizationToken": nil,
                "description": nil,
                "localeData": nil,
            ],
            optionalParameters: [])
        
        let preTokenizationRequest = GenericRequest(
            clientToken: accessToken,
            baseUrl: coreUrl,
            endpoint: "/klarna/customer-tokens",
            method: .post,
            headers: nil,
            queryParameters: nil,
            bodyParameters: preTokenizationRequestBodyParameters,
            body: nil)
        
        apm.preTokenizationRequest = preTokenizationRequest
        return apm
    }
    
    static func createApayaVaultAPM() throws -> APM.WebBased {
        let allowedHosts: [String] = ["primer.io", "livedemostore.primer.io", "api.playground.klarna.com",  "api.sandbox.primer.io"]
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard
            let decodedClientToken = state.decodedClientToken,
            let accessToken = decodedClientToken.accessToken,
            let coreUrl = decodedClientToken.coreUrl,
            let pciUrl = decodedClientToken.pciUrl
        else {
            throw PrimerError.generic
        }
        
        
        let createSessionRequest = GenericRequest(
            clientToken: accessToken,
            baseUrl: coreUrl,
            endpoint: "/session-token",
            method: .post,
            headers: nil,
            queryParameters: nil,
            bodyParameters: BodyParameters(
                requiredParameters: [
                    "merchantId": nil,
                    "merchantAccountId": nil,
                    "reference": nil,
                    "language": nil,
                    "currencyCode": nil
                ],
                optionalParameters: []),
            body: nil)
                
        let tokenizationRequest = GenericRequest(
            clientToken: accessToken,
            baseUrl: pciUrl,
            endpoint: "/payment-instruments",
            method: .post,
            headers: nil,
            queryParameters: nil,
            bodyParameters: BodyParameters(
                requiredParameters: [
                    "instrument": [
                        "mx": nil,
                        "mcc": nil,
                        "mnc": nil,
                        "hashedIdentifier": nil,
                        "currencyCode": nil,
                    ],
                    "tokenType": nil,
                    "paymentFlow": nil,
                    "customerId": nil,
                ],
                optionalParameters: []),
            body: nil)
        
        let apm = APM.WebBased(
            name: ConfigPaymentMethodType.apaya.rawValue,
            createSessionRequest: createSessionRequest,
            allowedHosts: allowedHosts,
            tokenizationRequest: tokenizationRequest)
        
        return apm
    }
}

class SDKBasedAPM {
    var name: String
    
    var apmRequest: APMRequest
    
    var apmResponse: [String : Any]?
    
    init(name: String, apmRequest: APMRequest) {
        self.name = name
        self.apmRequest = apmRequest
    }
    
//    func tokenize() -> Promise<PaymentMethodToken> {
//        return Promise { seal
//            seal
//        }
//    }
}




extension APM {
    // swiftlint:disable cyclomatic_complexity function_body_length
    static func createDictionary(for apm: APMWebBasedProtocol, with bodyParameters: BodyParameters?) -> [String: Any]? {
        guard let bodyParameters = bodyParameters else { return nil }
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        var storedVals: [String: Any] = [:]
        
        if let createSessionResponse = apm.createSessionResponse as? ApayaCreateSessionResponse,
                let data = try? JSONEncoder().encode(createSessionResponse),
                let dic = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
            storedVals.merge(dic) { (_, new) in new }
        } else if let createSessionResponse = apm.createSessionResponse as? KlarnaCreateSessionResponse,
                  let data = try? JSONEncoder().encode(createSessionResponse),
                  let dic = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
            storedVals.merge(dic) { (_, new) in new }
        }
        
        if let url = apm.createSessionResponse?.webViewUrl,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            let dic = queryItems.reduce(into: [String: String]()) { (result, item) in
                result[item.name] = item.value
            }
            storedVals.merge(dic) { (_, new) in new }
        }
        
        if let dic = apm.apmResponse {
            storedVals.merge(dic) { (_, new) in new }
        }
        
        if let dic = apm.preTokenizationResponse {
            storedVals.merge(dic) { (_, new) in new }
        }
        
        var bodyDic: [String: Any] = [:]
        
        for (param, val) in bodyParameters.requiredParameters {
            switch param {
            case "merchantId":
                if let merchantId = state.paymentMethodConfig?.getConfigId(forName: apm.name) {
                    bodyDic["merchant_id"] = merchantId
                }
                
            case "merchantAccountId":
                if let merchantAccountId = state.paymentMethodConfig?.getProductId(forName: apm.name) {
                    bodyDic["merchant_account_id"] = merchantAccountId
                }
                
            case "productId":
                if let merchantAccountId = state.paymentMethodConfig?.getProductId(forName: apm.name) {
                    bodyDic["productId"] = merchantAccountId
                }
                
            case "reference":
                bodyDic["reference"] = "recurring"
                
            case "language":
                bodyDic["language"] = settings.localeData.languageCode ?? "en"
                
            case "currencyCode":
                if let currency = settings.currency {
                    bodyDic["currency_code"] = currency.rawValue
                }
                
            case "sessionType":
                if let val = val {
                    bodyDic["sessionType"] = val
                }
                
            case "localeData":
                var localeDataDic: [String: Any] = [:]
                
                if let languageCode = settings.localeData.languageCode {
                    localeDataDic["languageCode"] = languageCode
                }
                
                if let localeCode = settings.localeData.localeCode {
                    localeDataDic["localeCode"] = localeCode
                }
                
                if let regionCode = settings.localeData.regionCode {
                    localeDataDic["regionCode"] = regionCode
                }
                
                bodyDic["localeData"] = localeDataDic
                
            case "redirectUrl":
                if let val = val {
                    bodyDic["redirectUrl"] = val
                }
                
            case "description":
                if let val = val {
                    bodyDic["description"] = val
                }
                
            case "paymentMethodConfigId":
                if let paymentMethodConfigId = state.paymentMethodConfig?.getConfigId(forName: apm.name) {
                    bodyDic["paymentMethodConfigId"] = paymentMethodConfigId
                }
                
            case "success":
                if let storedVal = storedVals["success"] {
                    bodyDic["success"] = storedVal
                }
                
            case "mx":
                if let storedVal = storedVals["MX"] {
                    bodyDic["mx"] = storedVal
                }
                
            case "hashedIdentifier":
                if let storedVal = storedVals["HashedIdentifier"] {
                    bodyDic["hashedIdentifier"] = storedVal
                }
                
            case "mcc":
                if let storedVal = storedVals["MCC"] {
                    bodyDic["mcc"] = storedVal
                }
                
            case "mnc":
                if let storedVal = storedVals["MNC"] {
                    bodyDic["mnc"] = storedVal
                }
                
            case "paymentMethodConfigId":
                if let storedVal = state.paymentMethodConfig?.getConfigId(forName: apm.name) {
                    bodyDic["paymentMethodConfigId"] = storedVal
                }
                
            case "sessionId":
                if let sessionId = storedVals["sessionId"] {
                    bodyDic["sessionId"] = sessionId
                }
                
            case "authorizationToken":
                if let token = storedVals["token"] {
                    bodyDic["authorizationToken"] = token
                } else if let token = storedVals["clientToken"] {
                    bodyDic["authorizationToken"] = token
                } else if let token = storedVals["authorizationToken"] {
                    bodyDic["authorizationToken"] = token
                }
                
            case "description":
                if let storedVal = storedVals["description"] {
                    bodyDic["description"] = storedVal
                }
                
            case "instrument":
                guard let instrumentRequiredParametersDic = val as? [String: Any] else {
                    break
                }
                
                var instrumentDic: [String: Any?] = [:]
                for (instrumentKey, _) in instrumentRequiredParametersDic {
                    switch instrumentKey {
                    case "klarnaCustomerToken":
                        if let customerTokenId = apm.preTokenizationResponse?["customerTokenId"] as? String {
                            instrumentDic["klarnaCustomerToken"] = customerTokenId
                        }
                        
                    case "sessionData":
                        if let sessionData = apm.preTokenizationResponse?["sessionData"] {
                            instrumentDic["sessionData"] = sessionData
                        }
                        
                    case "mx":
                        if let storedVal = storedVals["mx"] {
                            instrumentDic["mx"] = storedVal
                        }
                        
                    case "mcc":
                        if let storedVal = storedVals["mcc"] {
                            instrumentDic["mcc"] = storedVal
                        }
                        
                    case "mnc":
                        if let storedVal = storedVals["mnc"] {
                            instrumentDic["mnc"] = storedVal
                        }
                        
                    case "hashedIdentifier":
                        if let storedVal = storedVals["hashedIdentifier"] {
                            instrumentDic["hashedIdentifier"] = storedVal
                        }
                        
                    case "productId":
                        if let merchantAccountId = state.paymentMethodConfig?.getProductId(forName: apm.name) {
                            instrumentDic["productId"] = merchantAccountId
                        }
                        
                    case "currencyCode":
                        if let currency = settings.currency {
                            instrumentDic["currencyCode"] = currency.rawValue
                        }
                        
                    default:
                        break
                    }
                }
                
                if !instrumentDic.keys.isEmpty {
                    bodyDic["paymentInstrument"] = instrumentDic
                }
                
            case "tokenType":
                bodyDic["tokenType"] = Primer.shared.flow.internalSessionFlow.vaulted ? TokenType.multiUse.rawValue : TokenType.singleUse.rawValue
                
            case "paymentFlow":
                if Primer.shared.flow.internalSessionFlow.vaulted {
                    bodyDic["paymentFlow"] = PaymentFlow.vault.rawValue
                }
                
            case "customerId":
                if Primer.shared.flow.internalSessionFlow.vaulted, let customerId = settings.customerId {
                    bodyDic["customerId"] = customerId
                }
                
            default:
                break
            }
        }
        
        for param in bodyParameters.optionalParameters {
            switch param {
            case "totalAmount":
                bodyDic["totalAmount"] = settings.amount
                
            default:
                break
            }
        }
        
        return bodyDic
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}
