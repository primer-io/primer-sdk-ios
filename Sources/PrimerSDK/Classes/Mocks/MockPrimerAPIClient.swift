//
//  MockPrimerAPIClient.swift
//  PrimerSDK
//
//  Created by Evangelos on 23/12/21.
//

#if canImport(UIKit)

import Foundation

internal class MockPrimerAPIClient: PrimerAPIClientProtocol {

    var response: Data?
    var throwsError: Bool
    var isCalled: Bool = false
    
    var validateClientTokenResponse: Data?
    var tokenizePaymentMethodResponse: Data?
    var createPaymentResponse: Data?

    init(with response: Data? = nil, throwsError: Bool = false) {
        self.response = response
        self.throwsError = throwsError
    }

    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (Result<GetVaultedPaymentMethodsResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(GetVaultedPaymentMethodsResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        
    }
    
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse> {
        return Promise { seal in
            do {
                let value = try JSONDecoder().decode(GetVaultedPaymentMethodsResponse.self, from: response!)
                seal.fulfill(value)
            } catch {
                seal.reject(error)
            }
        }
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isCalled = true
        guard response != nil else { return }
        
        do {
            completion(.success(()))
        }
//        catch {
//            completion(.failure(error))
//        }
    }
    
    func buildConfigurationResponseData(
        withPaymentMethods paymentMethodTypes: [PrimerPaymentMethodType]
    ) -> Data {
        var responseJson: [String: Any] = [
            "coreUrl" : "https://api.sandbox.primer.io",
            "pciUrl" : "https://sdk.api.sandbox.primer.io",
            "primerAccountId" : "primer-account-id-\(String.randomString(length: 8))",
            
            
            
            "clientSession" : [
              "order" : [
                "countryCode" : "GB",
                "orderId" : "ios_order_id_LklKo2zK",
                "currencyCode" : "GBP",
                "totalOrderAmount" : 1010,
                "lineItems" : [
                  [
                    "amount" : 1010,
                    "quantity" : 1,
                    "itemId" : "shoes-382190",
                    "description" : "Fancy Shoes"
                  ]
                ]
              ],
              "clientSessionId" : "09841e8a-b1fa-4528-aed1-173808a4f44d",
              "customer" : [
                "firstName" : "John",
                "shippingAddress" : [
                  "firstName" : "John",
                  "lastName" : "Smith",
                  "addressLine1" : "9446 Richmond Road",
                  "countryCode" : "GB",
                  "city" : "London",
                  "postalCode" : "EC53 8BT"
                ],
                "emailAddress" : "john@primer.io",
                "customerId" : "ios-customer-G90G37kH",
                "mobileNumber" : "+4478888888888",
                "billingAddress" : [
                  "firstName" : "John",
                  "lastName" : "Smith",
                  "addressLine1" : "65 York Road",
                  "countryCode" : "GB",
                  "city" : "London",
                  "postalCode" : "NW06 4OM"
                ],
                "lastName" : "Smith"
              ],
              "paymentMethod" : [
                "options" : [
                  [
                    "type" : "PAYMENT_CARD",
                    "networks" : [
                      [
                        "type" : "VISA",
                        "surcharge" : 109
                      ],
                      [
                        "type" : "MASTERCARD",
                        "surcharge" : 129
                      ]
                    ]
                  ],
                  [
                    "type" : "PAYPAL",
                    "surcharge" : 49
                  ],
                ],
                "vaultOnSuccess" : false
              ]
            ],
            "env" : "SANDBOX",
            "checkoutModules" : [
              [
                "type" : "TAX_CALCULATION",
                "requestUrl" : "/sales-tax/calculate"
              ],
              [
                "type" : "BILLING_ADDRESS",
                "options" : [
                  "lastName" : true,
                  "city" : true,
                  "firstName" : true,
                  "postalCode" : true,
                  "addressLine1" : true,
                  "countryCode" : true,
                  "addressLine2" : true,
                  "state" : true,
                  "phoneNumber" : false
                ]
              ]
            ],
        ]
                
        var paymentMethodConfigsJson: [[String: Any]] = []
        for paymentMethodType in paymentMethodTypes {
            switch paymentMethodType {
            case .adyenAlipay,
                    .adyenBlik,
                    .adyenDotPay,
                    .adyenGiropay,
                    .adyenIDeal,
                    .adyenInterac,
                    .adyenMobilePay,
                    .adyenPayTrail,
                    .adyenSofort,
                    .adyenPayshop,
                    .adyenTrustly,
                    .adyenTwint,
                    .adyenVipps,
                    .apaya,
                    .buckarooBancontact,
                    .buckarooEps,
                    .buckarooGiropay,
                    .buckarooIdeal,
                    .buckarooSofort,
                    .rapydFast,
                    .rapydGCash,
                    .rapydGrabPay,
                    .rapydPoli,
                    .rapydPromptPay:
                let paymentMethodConfigJson: [String: Any] = [
                    "id" : "id-\(paymentMethodType.rawValue)",
                    "options" : [
                      "merchantId" : "MerchantTest",
                      "merchantAccountId" : "merchant-account-id-\(paymentMethodType.rawValue)"
                    ],
                    "type" : paymentMethodType.rawValue,
                    "processorConfigId" : "processor-config-id-\(paymentMethodType.rawValue)",
                ]
                paymentMethodConfigsJson.append(paymentMethodConfigJson)
                
            case .applePay:
                let paymentMethodConfigJson: [String: Any] = [
                    "id" : "id-\(paymentMethodType.rawValue)",
                    "options" : [
                        "certificates" : [
                          [
                            "certificateId" : "certificate-id-\(String.randomString(length: 8))",
                            "status" : "ACTIVE",
                            "validFromTimestamp" : "2021-12-06T10:14:14",
                            "expirationTimestamp" : "2024-01-05T10:14:13",
                            "merchantId" : "merchant.checkout.team",
                            "createdAt" : "2021-12-06T10:24:34.659452"
                          ]
                        ]
                    ],
                    "type" : paymentMethodType.rawValue,
                    "processorConfigId" : "processor-config-id-\(paymentMethodType.rawValue)",
                ]
                paymentMethodConfigsJson.append(paymentMethodConfigJson)
                
            case .atome:
                break
            case .coinbase:
                break
            case .goCardless:
                break
            case .googlePay:
                break
            case .hoolah:
                break
            case .klarna,
                    .payPal:
                let paymentMethodConfigJson: [String: Any] = [
                    "id" : "id-\(paymentMethodType.rawValue)",
                    "options" : [
                      "merchantId" : "Merchant",
                      "clientId" : "Merchant",
                      "merchantAccountId" : "merchant-account-id-\(paymentMethodType.rawValue)"
                    ],
                    "type" : "KLARNA",
                    "processorConfigId" : "processor-config-id-\(paymentMethodType.rawValue)",
                ]
                paymentMethodConfigsJson.append(paymentMethodConfigJson)
                
            case .mollieBankcontact:
                break
            case .mollieIdeal:
                break
            case .payNLBancontact:
                break
            case .payNLGiropay:
                break
            case .payNLIdeal:
                break
            case .payNLPayconiq:
                break
            case .paymentCard:
                let paymentMethodConfigJson: [String: Any] = [
                    "options" : [
                        "threeDSecureEnabled" : true,
                        "threeDSecureProvider" : "3DS-PROVIDER"
                    ],
                    "type" : paymentMethodType.rawValue,
                ]
                paymentMethodConfigsJson.append(paymentMethodConfigJson)
                
            case .primerTestPayPal:
                break
            case .primerTestKlarna:
                break
            case .primerTestSofort:
                break
            case .twoCtwoP:
                break
            case .xfersPayNow:
                break
            case .opennode:
                break
            }
        }
        
        responseJson["paymentMethods"] = paymentMethodConfigsJson

        return try! JSONSerialization.data(withJSONObject: responseJson)
    }

    func fetchConfiguration(clientToken: DecodedClientToken, requestParameters: PrimerAPIConfiguration.API.RequestParameters?, completion: @escaping (Result<PrimerAPIConfiguration, Error>) -> Void) {
        isCalled = true
        
        let responseData = self.buildConfigurationResponseData(withPaymentMethods: [.paymentCard, .applePay, .adyenGiropay])

        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            do {
                let value = try JSONDecoder().decode(PrimerAPIConfiguration.self, from: responseData)
                completion(.success(value))
            } catch {
                completion(.failure(error))
            }
        }
    }

//    func createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (Result<DirectDebitCreateMandateResponse, Error>) -> Void) {
//        isCalled = true
//        guard let response = response else { return }
//
//        do {
//            let value = try JSONDecoder().decode(DirectDebitCreateMandateResponse.self, from: response)
//            completion(.success(value))
//        } catch {
//            completion(.failure(error))
//        }
//    }

    func createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (Result<PayPalCreateOrderResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalCreateOrderResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (Result<PayPalCreateBillingAgreementResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalCreateBillingAgreementResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalConfirmBillingAgreementResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)))
            return
        }
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(KlarnaCreatePaymentSessionAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)))
            return
        }

        guard let response = response else { return }
        do {
            let value = try JSONDecoder().decode(KlarnaCustomerTokenAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)))
            return
        }

        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(KlarnaCustomerTokenAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest, completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        isCalled = true
        
        guard let response = tokenizePaymentMethodResponse else { return }

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            do {
                let value = try JSONDecoder().decode(PaymentMethodToken.self, from: response)
                completion(.success(value))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func createApayaSession(
        clientToken: DecodedClientToken,
        request: Apaya.CreateSessionAPIRequest,
        completion: @escaping (Result<Apaya.CreateSessionAPIResponse, Error>) -> Void
    ) {
        isCalled = true
        guard let response = response else { return }
        
        do {
            let value = try JSONDecoder().decode(Apaya.CreateSessionAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func listAdyenBanks(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (Result<[Bank], Error>) -> Void) {
        
    }
    
    func poll(clientToken: DecodedClientToken?, url: String, completion: @escaping (Result<PollingResponse, Error>) -> Void) {
        
    }
    
    func sendAnalyticsEvents(url: URL, body: Analytics.Service.Request?, completion: @escaping (_ result: Result<Analytics.Service.Response, Error>) -> Void) {
        
    }
    
    func threeDSBeginAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(ThreeDS.BeginAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func threeDSContinueAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        isCalled = true
        
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(ThreeDS.PostAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchPayPalExternalPayerInfo(clientToken: DecodedClientToken, payPalExternalPayerInfoRequestBody: PayPal.PayerInfo.Request, completion: @escaping (Result<PayPal.PayerInfo.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(PayPal.PayerInfo.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }

    }

    func createPayment(clientToken: DecodedClientToken, paymentRequestBody: Payment.CreateRequest, completion: @escaping (Result<Payment.Response, Error>) -> Void) {
        isCalled = true
        
        guard let response = createPaymentResponse else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            do {
                let value = try JSONDecoder().decode(Payment.Response.self, from: response)
                completion(.success(value))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func resumePayment(clientToken: DecodedClientToken, paymentId: String, paymentResumeRequest: Payment.ResumeRequest, completion: @escaping (_ result: Result<Payment.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(Payment.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
}

extension MockPrimerAPIClient {
    
    func requestPrimerConfigurationWithActions(clientToken: DecodedClientToken, request: ClientSessionUpdateRequest, completion: @escaping (Result<PrimerAPIConfiguration, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(PrimerAPIConfiguration.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
}

extension MockPrimerAPIClient {
    
    func begin3DSAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(ThreeDS.BeginAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func continue3DSAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        isCalled = true
        
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(ThreeDS.PostAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func validateClientToken(request: ClientTokenValidationRequest, completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
        guard let response = validateClientTokenResponse else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
                
        do {
            let value = try JSONDecoder().decode(SuccessResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
}

#endif
