//
//  URLSessionStack.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//



import Foundation

internal class URLSessionStack: NetworkService, LogReporter {
    
    private let session: URLSession
    private let parser: Parser
    
    // MARK: - Object lifecycle
    
    init(session: URLSession = .shared, parser: Parser = JSONParser()) {
        self.session = session
        self.parser = parser
    }
    
    // MARK: - Network Stack logic
    
    // swiftlint:disable function_body_length
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResultCallback<T>) {
        
        let urlStr: String = (endpoint.baseURL ?? "") + endpoint.path
        let id = String.randomString(length: 32)
        
        if let primerAPI = endpoint as? PrimerAPI, shouldReportNetworkEvents(for: primerAPI) {
            let reqEvent = Analytics.Event(
                eventType: .networkCall,
                properties: NetworkCallEventProperties(
                    callType: .requestStart,
                    id: id,
                    url: urlStr,
                    method: endpoint.method,
                    errorBody: nil,
                    responseCode: nil))
            Analytics.Service.record(event: reqEvent)
            
            let connectivityEvent = Analytics.Event(
                eventType: .networkConnectivity,
                properties: NetworkConnectivityEventProperties(
                    networkType: Connectivity.networkType))
            Analytics.Service.record(event: connectivityEvent)
        }
        
        guard let url = url(for: endpoint) else {
            let err = InternalError.invalidUrl(url: "Base URL: \(endpoint.baseURL ?? "nil") | Endpoint: \(endpoint.path)", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let headers = endpoint.headers {
            request.allHTTPHeaderFields = headers
        }
        
        if let data = endpoint.body {
            request.httpBody = data
        }
        
#if DEBUG
        if let queryParams = endpoint.queryParameters {            
            var urlQueryItems: [URLQueryItem] = []
            
            for (key, val) in queryParams {
                let urlQueryItem = URLQueryItem(name: key, value: val)
                urlQueryItems.append(urlQueryItem)
            }
            
            if !urlQueryItems.isEmpty {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                urlComponents.queryItems = urlQueryItems
            }
        }
 
        logger.debug(message: "🌎 Network request [\(request.httpMethod!)] \(request.url!)")
        logger.debug(message: "📃 Request Headers: ")
        request.allHTTPHeaderFields?.forEach { key, value in
            logger.debug(message: " - \(key) = \(value)")
        }
#endif
        
        let dataTask = session.dataTask(with: request) { [logger] data, response, error in
            let httpResponse = response as? HTTPURLResponse
            
            var resEventProperties: NetworkCallEventProperties?
            var resEvent: Analytics.Event?
            if !endpoint.path.isEmpty {
                resEventProperties = NetworkCallEventProperties(
                    callType: .requestEnd,
                    id: id,
                    url: urlStr,
                    method: endpoint.method,
                    errorBody: nil,
                    responseCode: (response as? HTTPURLResponse)?.statusCode
                )
                
                resEvent = Analytics.Event(
                    eventType: .networkCall,
                    properties: resEventProperties)
                
                resEvent!.properties = resEventProperties
            }
            
#if DEBUG

#endif
                        
            if let error = error {
                if resEvent != nil {
                    resEventProperties!.errorBody = "\(error)"
                    resEvent!.properties = resEventProperties
                    Analytics.Service.record(event: resEvent!)
                }
                
#if DEBUG
                logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)", userInfo: ["ErrorMessage" : error.localizedDescription])
#endif
                
                let err = InternalError.underlyingErrors(errors: [error], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            
            guard let data = data else {
                if resEvent != nil {
                    resEventProperties?.errorBody = "No data received"
                    resEvent!.properties = resEventProperties
                    Analytics.Service.record(event: resEvent!)
                }
                
#if DEBUG
                self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                self.logger.error(message: "No data received.")
#endif
                
                let err = InternalError.noData(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            
            do {
                if resEvent != nil {
                    resEvent?.properties = resEventProperties
                    Analytics.Service.record(event: resEvent!)
                }
                
#if DEBUG
                if endpoint.shouldParseResponseBody {
                    if let primerAPI = endpoint as? PrimerAPI, case .sendAnalyticsEvents = primerAPI {
                        logger.debug(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.debug(message: "Analytics event sent")
                    } else {
                        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject as Any, options: .prettyPrinted)
                        var jsonStr: String?
                        if jsonData != nil {
                            jsonStr = String(data: jsonData!, encoding: .utf8 )
                        }
                        logger.debug(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        if let httpResponse = response as? HTTPURLResponse {
                            logger.debug(message: "✋ Status: \(httpResponse.statusCode)")
                            logger.debug(message: "📃 Headers: ")
                            httpResponse.allHeaderFields.forEach { key, value in
                                logger.debug(message: " - \(key) = \(value)")
                            }
                        }
                        logger.debug(message: "Body: ")
                        logger.debug(message: jsonStr ?? "No body found")
                    }
                }
#endif
                
                if endpoint.shouldParseResponseBody == false, httpResponse?.statusCode == 200 {
                    let dummyRes: T = DummySuccess(success: true) as! T
                    DispatchQueue.main.async { completion(.success(dummyRes)) }
                } else {
                    let result = try self.parser.parse(T.self, from: data)
                    DispatchQueue.main.async { completion(.success(result)) }
                }
            } catch {
                if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments), let jsonDic = json as? [String: Any?],
                   let primerErrorJSON = jsonDic["error"] as? [String: Any],
                   let primerErrorObject = try? JSONSerialization.data(withJSONObject: primerErrorJSON, options: .fragmentsAllowed),
                   let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    
                    let primerErrorResponse = try? self.parser.parse(PrimerServerErrorResponse.self, from: primerErrorObject)
                    
                    if resEvent != nil {
                        resEventProperties?.errorBody = "\(primerErrorJSON)"
                        resEvent!.properties = resEventProperties
                        Analytics.Service.record(event: resEvent!)
                    }
                    
                    if statusCode == 401 {
                        let err = InternalError.unauthorized(url: urlStr, method: endpoint.method, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        
#if DEBUG
                        logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.error(message: "Error: \n - Status code \(statusCode)\n - \(err)")
#endif
                        
                        DispatchQueue.main.async { completion(.failure(err)) }
                        
                    } else if (400...499).contains(statusCode) {
                        let err = InternalError.serverError(status: statusCode, response: primerErrorResponse, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        
#if DEBUG
                        self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.error(message: "Error: \n - Status code \(statusCode)\n - \(err)")
#endif
                        
                        DispatchQueue.main.async { completion(.failure(err)) }
                        
                    } else if (500...599).contains(statusCode) {
                        let err = InternalError.serverError(status: statusCode, response: primerErrorResponse, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        
#if DEBUG
                        self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.error(message: "Error: \n - Status code \(statusCode)\n - \(err)")
#endif
                        
                        DispatchQueue.main.async { completion(.failure(err)) }
                        
                    } else {
                        let err = InternalError.serverError(status: statusCode, response: primerErrorResponse, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        
                        if resEvent != nil {
                            resEventProperties?.errorBody = err.localizedDescription
                            resEvent!.properties = resEventProperties
                            Analytics.Service.record(event: resEvent!)
                        }

#if DEBUG
                        self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                        logger.error(message: "Error: \n - Status code \(statusCode)\n - \(err)")
#endif
                        
                        DispatchQueue.main.async { completion(.failure(err)) }
                    }
                    
                } else {
                    let err = InternalError.failedToDecode(message: "Failed to decode response from URL: \(urlStr)", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    
                    if resEvent != nil {
                        resEventProperties?.errorBody = err.localizedDescription
                        resEvent!.properties = resEventProperties
                        Analytics.Service.record(event: resEvent!)
                    }
                    
#if DEBUG
                    self.logger.error(message: "🌎 Network Response [\(request.httpMethod!)] \(request.url!)")
                    self.logger.error(message: "Error: Failed to parse")
#endif
                    
                    DispatchQueue.main.async { completion(.failure(InternalError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString))) }
                }
                
            }
        }
        dataTask.resume()
    }
}

internal extension URLSessionStack {
    
    func url(for endpoint: Endpoint) -> URL? {
        guard let urlStr = endpoint.baseURL else { return nil }
        guard let baseUrl = URL(string: urlStr) else { return nil }
        var url = baseUrl
        
        if endpoint.path != "" {
            url = baseUrl.appendingPathComponent(endpoint.path)
        }
        
        if let queryParameters = endpoint.queryParameters, !queryParameters.keys.isEmpty {
            var urlComponents = URLComponents(string: url.absoluteString)!
            var urlQueryItems: [URLQueryItem] = []
            
            for (key, val) in queryParameters {
                let urlQueryItem = URLQueryItem(name: key, value: val)
                urlQueryItems.append(urlQueryItem)
            }
            
            if !urlQueryItems.isEmpty {
                urlComponents.queryItems = urlQueryItems
            }
            
            let tmpUrl = urlComponents.url ?? url
            return tmpUrl
        }
        
        return url
    }
    
    func shouldReportNetworkEvents(for primerAPI: PrimerAPI) -> Bool {
        // Don't report events for polling requests
        guard primerAPI != PrimerAPI.poll(clientToken: nil, url: "") else {
            return false
        }
        guard let baseURL = primerAPI.baseURL, let url = URL(string: baseURL), url.path != "/sdk-logs" else {
            return false
        }
        return true
    }
}




let mockedConfigResponse = """
{
  "pciUrl" : "https://sdk.api.sandbox.primer.io",
  "paymentMethods2" : [
{
            
    ],
  "paymentMethods" : [
    {
      "id" : "527ee4ff-2c66-4234-829f-d20480f3aa09",
      "type" : "GOOGLE_PAY",
      "options" : {
        "merchantId" : "06134396481468734566",
        "merchantName" : "Primer",
        "type" : "GOOGLE_PAY"
      }
    },
    {
      "id" : "a1ed81d7-5ee8-4039-a1a2-317cda6606d2",
      "options" : {
        "merchantId" : "PrimerJbTestECOM",
        "merchantAccountId" : "4ad980f3-ccc7-5e8e-9a9c-81cd6f5214d4"
      },
      "type" : "ADYEN_IDEAL",
      "processorConfigId" : "9319ad4e-cd51-4517-9d46-bc7be244752a"
    },
    {
      "id" : "c657ae04-c230-4be4-9615-9b822743e5e4",
      "type" : "APPLE_PAY",
      "options" : {
        "certificates" : [
          {
            "certificateId" : "e09fc38c-f06e-4477-818c-e9e7dc81c31d",
            "status" : "ACTIVE",
            "validFromTimestamp" : "2021-12-06T10:14:14",
            "expirationTimestamp" : "2024-01-05T10:14:13",
            "merchantId" : "merchant.dx.team",
            "createdAt" : "2021-12-06T10:24:34.659452"
          }
        ]
      }
    },
    {
      "id" : "ba022c70-8f18-447d-a214-a55f71bc35be",
      "options" : {
        "merchantId" : "dx@primer.io",
        "clientId" : "dx@primer.io",
        "merchantAccountId" : "6a126321-5306-53f5-8574-8506a095c90d"
      },
      "type" : "GOCARDLESS",
      "processorConfigId" : "8df71a6c-4946-47e3-8057-7bcafb5221a4"
    },
    {
      "id" : "36e2eb9b-2d67-4f66-a358-b98f739667c6",
      "options" : {
        "merchantId" : "SL-1893-2911",
        "merchantAccountId" : "9e72a6de-70b8-580d-b63d-1ee6f32f7761"
      },
      "type" : "PAY_NL_PAYCONIQ",
      "processorConfigId" : "c16003a6-40ac-49b4-a0dd-e68e837f9bf9"
    },
    {
      "type" : "PAYMENT_CARD",
      "options" : {
        "threeDSecureEnabled" : true,
        "threeDSecureProvider" : "3DSECUREIO"
      }
    }
  ],
  "clientSession" : {
    "order" : {
      "countryCode" : "NL",
      "orderId" : "ios_order_id_gvbVjRyR",
      "currencyCode" : "EUR",
      "totalOrderAmount" : 10100,
      "lineItems" : [
        {
          "amount" : 10100,
          "quantity" : 1,
          "itemId" : "shoes-382190",
          "description" : "Fancy Shoes"
        }
      ]
    },
    "clientSessionId" : "fbd53677-abcd-4178-b4c1-ba17bfb277ad",
    "customer" : {
      "firstName" : "John",
      "shippingAddress" : {
        "firstName" : "John",
        "lastName" : "Smith",
        "addressLine1" : "9446 Richmond Road",
        "countryCode" : "NL",
        "city" : "London",
        "postalCode" : "EC53 8BT"
      },
      "emailAddress" : "john@primer.io",
      "customerId" : "ios-customer-vOPsjZLZ",
      "mobileNumber" : "+4478888888888",
      "billingAddress" : {
        "firstName" : "John",
        "lastName" : "Smith",
        "addressLine1" : "65 York Road",
        "countryCode" : "NL",
        "city" : "London",
        "postalCode" : "NW06 4OM"
      },
      "lastName" : "Smith"
    },
    "paymentMethod" : {
      "options" : [
        {
          "type" : "PAYMENT_CARD",
          "networks" : [
            {
              "type" : "VISA",
              "surcharge" : 109
            },
            {
              "type" : "MASTERCARD",
              "surcharge" : 129
            }
          ]
        },
        {
          "type" : "PAYPAL",
          "surcharge" : 49
        },
        {
          "type" : "ADYEN_IDEAL",
          "surcharge" : 69
        },
        {
          "type" : "PAY_NL_IDEAL",
          "surcharge" : 39
        },
        {
          "type" : "ADYEN_TWINT",
          "surcharge" : 59
        },
        {
          "type" : "BUCKAROO_BANCONTACT",
          "surcharge" : 89
        },
        {
          "type" : "ADYEN_GIROPAY",
          "surcharge" : 79
        },
        {
          "type" : "APPLE_PAY",
          "surcharge" : 19
        }
      ],
      "vaultOnSuccess" : false
    }
  },
  "primerAccountId" : "84100a01-523f-4347-ac44-e8a3e7083d9a",
  "keys" : {
    "threeDSecureIoCertificates" : [
      {
        "encryptionKey" : "MIIBxTCCAWugAwIBAgIIOHin61BZd20wCgYIKoZIzj0EAwIwSTELMAkGA1UEBhMCREsxFDASBgNVBAoTCzNkc2VjdXJlLmlvMSQwIgYDVQQDExszZHNlY3VyZS5pbyBzdGFuZGluIGlzc3VpbmcwHhcNMjEwNDI2MTIwNDE5WhcNMjYwNTI2MTIwNDE5WjBFMQswCQYDVQQGEwJESzEUMBIGA1UEChMLM2RzZWN1cmUuaW8xIDAeBgNVBAMTFzNkc2VjdXJlLmlvIHN0YW5kaW4gQUNTMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEczsq/UTsSeRYLFByvgbcrRiJvwZnQmostNJgl6i4/0rr9xGMD+gcqrYcbvFTEJIVHs1i557PGw2ozHQmZr/R1qNBMD8wDgYDVR0PAQH/BAQDAgOoMAwGA1UdEwEB/wQCMAAwHwYDVR0jBBgwFoAUoejawWDkUr1FVwxacK10626mkYswCgYIKoZIzj0EAwIDSAAwRQIgGvK44bXL6QD1cP322avHRjmD4T1a1el3vf2ttssXoecCIQCtlnwv5tXddJJphIgcxjG7DA8Hpp0zwqROeF3DezMvrA==",
        "cardNetwork" : "VISA",
        "rootCertificate" : "MIIByjCCAXCgAwIBAgIIWm3lYnRpg/kwCgYIKoZIzj0EAwIwSTELMAkGA1UEBhMCREsxFDASBgNVBAoTCzNkc2VjdXJlLmlvMSQwIgYDVQQDExszZHNlY3VyZS5pbyBzdGFuZGluIHJvb3QgQ0EwHhcNMjEwNDI2MTIwNDE5WhcNMjYwNTI2MTIwNDE5WjBJMQswCQYDVQQGEwJESzEUMBIGA1UEChMLM2RzZWN1cmUuaW8xJDAiBgNVBAMTGzNkc2VjdXJlLmlvIHN0YW5kaW4gcm9vdCBDQTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABDiki3Z74HsR4G5ejqwk31STA0JZyWdBbzfkpLhxlNepJmzW/lKvgpJ5w1abWymNv+kQ1evdoCZ3xPrWDH3Ov+ajQjBAMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBS1xdoF1e7Ej4pQiLB/n1TSw00iITAKBggqhkjOPQQDAgNIADBFAiAxeIZD+gfFVsQnbbOH7l04v8euq0N82gG8umBaFl+AVwIhAIVDiG4nLkL187clHn5Mw2AALHh1xSSfSBGbdUmuCd7b"
      }
    ],
    "netceteraLicenseKey" : "eyJhbGciOiJSUzI1NiJ9.eyJ2ZXJzaW9uIjoyLCJ2YWxpZC11bnRpbCI6IjIwMjItMTItMDkiLCJuYW1lIjoiUHJpbWVyYXBpIiwibW9kdWxlIjoiM0RTIn0.T_EP89dFkXvLhOiW0kfX--_GoDwtxTuSxl7dku6-if0hjQb8zIupOMY56TDnsFO96T3-YB34RRLQJ4daxwAuLYaprKN39lDgLpGPvFAYcSk8PPNAOxaIM_xNFuzHYAiRmEEPONuxWq6kse1AgjTJaBbZN80qmOTlKHFZ1BmVVT3M-cyvhdh-5gvlEsNYFD3ufRF6Y79MpySwqr2p94BcXRk2GMgkKYwA6jnw6B6iYOnFj4SuQqjzFneJHlvmF7zwvm-mDvJ82ZoPWzM0uS5YouovzZIdJMqZrZThiSdQYvFh4nIQBBFxE02FvGWJ7Ae9Oq0YrQoLGZrV1l17TW3AZw"
  },
  "env" : "SANDBOX",
  "checkoutModules" : [
    {
      "type" : "TAX_CALCULATION",
      "requestUrl" : "/sales-tax/calculate"
    }
  ],
  "coreUrl" : "https://api.sandbox.primer.io"
}
"""
