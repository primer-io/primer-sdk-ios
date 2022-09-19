//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK
import XCTest

var mockClientToken = DecodedClientToken(accessToken: "bla", expDate: Date(timeIntervalSince1970: 2000000000), configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil, accountNumber: nil)

//(
//    accessToken: "bla",
//    configurationUrl: "bla",
//    paymentFlow: "bla",
//    threeDSecureInitUrl: "bla",
//    threeDSecureToken: "bla",
//    coreUrl: "https://primer.io",
//    pciUrl: "https://primer.io",
//    env: "bla"
//)

var mockSettings = PrimerSettings(
    paymentMethodOptions: PrimerPaymentMethodOptions(
        urlScheme: "urlScheme",
        applePayOptions: PrimerApplePayOptions(merchantIdentifier: "mid", merchantName: "name")
    )
)

class MockPrimerDelegate: PrimerDelegate {
    
    var token: String?
    var authorizePaymentFails: Bool
    var clientTokenCallbackCalled = false
    var authorizePaymentCalled = false
    var primerDidDismissCalled = false

    init(token: String? = nil, authorizePaymentFails: Bool = false) {
        self.token = token
        self.authorizePaymentFails = authorizePaymentFails
    }

    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        clientTokenCallbackCalled = true
        guard let token = token else {
            completion(nil, PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
            return
        }
        completion(token, nil)
    }
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {

    }

    
    func tokenAddedToVault(_ token: PrimerPaymentMethodTokenData) {
        
    }

    

    func authorizePayment(_ result: PrimerPaymentMethodTokenData, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)) }
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PrimerPaymentMethodTokenData, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)) }
    }

    func primerDidDismiss() {
        primerDidDismissCalled = true
    }
    
    func primerDidFailWithError(_ error: Error) {
        
    }
}

struct MockPrimerSettings: PrimerSettingsProtocol {
    var paymentHandling = PrimerPaymentHandling.auto
    var localeData = PrimerLocaleData()
    var paymentMethodOptions = PrimerPaymentMethodOptions()
    var uiOptions = PrimerUIOptions()
    var debugOptions = PrimerDebugOptions()
}

let mockPaymentMethodConfig = PrimerAPIConfiguration(
    coreUrl: "url",
    pciUrl: "url",
    clientSession: nil,
    paymentMethods: [
        PrimerPaymentMethod(id: "klarna-test", implementationType: .nativeSdk, type: "KLARNA", name: "Klarna", processorConfigId: "klarna-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
        PrimerPaymentMethod(id: "paypal-test", implementationType: .nativeSdk, type: "PAYPAL", name: "PayPal", processorConfigId: "paypal-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
        PrimerPaymentMethod(id: "apaya-test", implementationType: .nativeSdk, type: "APAYA", name: "Apaya", processorConfigId: "apaya-processor-config-id", surcharge: nil, options: ApayaOptions(merchantAccountId: "merchant_account_id"), displayMetadata: nil)
    ],
    keys: nil,
    checkoutModules: nil
)

class MockAppState: AppStateProtocol {
    
    static var current: AppStateProtocol {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        return appState
    }
    
    var amount: Int? {
        return MockAppState.current.apiConfiguration?.clientSession?.order?.merchantAmount ?? AppState.current.apiConfiguration?.clientSession?.order?.totalOrderAmount
    }
    
    var currency: Currency? {
        return MockAppState.current.apiConfiguration?.clientSession?.order?.currencyCode
    }

    var clientToken: String?
    var apiConfiguration: PrimerAPIConfiguration?
    var paymentMethods: [PrimerPaymentMethodTokenData] = []
    var selectedPaymentMethodId: String?
    var selectedPaymentMethod: PrimerPaymentMethodTokenData?

    init(
        clientToken: String? = MockAppState.mockClientToken,
        apiConfiguration: PrimerAPIConfiguration? = PrimerAPIConfiguration(
            coreUrl: "url",
            pciUrl: "url",
            clientSession: nil,
            paymentMethods: [
                PrimerPaymentMethod(id: "klarna-test", implementationType: .nativeSdk, type: "KLARNA", name: "Klarna", processorConfigId: "klarna-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
                PrimerPaymentMethod(id: "paypal-test", implementationType: .nativeSdk, type: "PAYPAL", name: "PayPal", processorConfigId: "paypal-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
                PrimerPaymentMethod(id: "apaya-test", implementationType: .nativeSdk, type: "APAYA", name: "Apaya", processorConfigId: "apaya-processor-config-id", surcharge: nil, options: ApayaOptions(merchantAccountId: "merchant_account_id"), displayMetadata: nil)
            ],
            keys: nil,
            checkoutModules: nil
        )
    ) {
        self.clientToken = clientToken
        self.apiConfiguration = apiConfiguration
    }
}

extension MockAppState {
    
    static var mockClientToken: String {
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjIwMDAwMDAwMDAsImFjY2Vzc1Rva2VuIjoiYzJlOTM3YmMtYmUzOS00ZjVmLTkxYmYtNTIyNWExNDg0OTc1IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJhbmFseXRpY3NVcmxWMiI6Imh0dHBzOi8vYW5hbHl0aWNzLnNhbmRib3guZGF0YS5wcmltZXIuaW8vY2hlY2tvdXQvdHJhY2siLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwicGF5bWVudEZsb3ciOiJERUZBVUxUIn0.1Epm-502bLNhjhIQrmp4ZtrMQa0vQ2FjckPAlgJtuao"
    }
    
    static var mockDecodedClientToken: DecodedClientToken {
        return DecodedClientToken(accessToken: "bla", expDate: Date(timeIntervalSinceNow: 1000000), configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil, accountNumber: "account-number")
    }
    
    static var mockPrimerAPIConfigurationJsonString: String {
        return """
            {
              "pciUrl" : "https://sdk.api.sandbox.primer.io",
              "paymentMethods" : [
                {
                  "id" : "id-1",
                  "options" : {
                    "merchantId" : "merchant-id-1"
                    "clientId" : "client-id-1",
                    "merchantAccountId" : "merchant-account-id-1"
                  },
                  "type" : "KLARNA",
                  "processorConfigId" : "processor-config-id-1"
                },
                {
                  "id" : "id-2",
                  "options" : {
                    "merchantId" : "merchant-id-2"
                    "merchantAccountId" : "merchant-account-id-2"
                  },
                  "type" : "APAYA",
                  "processorConfigId" : "processor-config-id-2"
                },
                {
                  "id" : "id-3",
                  "options" : {
                    "merchantId" : "merchant-id-3"
                    "clientId" : "client-id-3",
                    "merchantAccountId" : "merchant-account-id-3"
                  },
                  "type" : "PAYPAL",
                  "processorConfigId" : "processor-config-id-3"
                },
                {
                  "id" : "id-4",
                  "type" : "APPLE_PAY",
                  "options" : {
                    "certificates" : [
                      {
                        "certificateId" : "certificate-id-4",
                        "status" : "ACTIVE",
                        "validFromTimestamp" : "2021-12-06T10:14:14",
                        "expirationTimestamp" : "2024-01-05T10:14:13",
                        "merchantId" : "merchant.checkout.team",
                        "createdAt" : "2021-12-06T10:24:34.659452"
                      }
                    ]
                  }
                },
                {
                  "id" : "id-5",
                  "options" : {
                    "merchantId" : "merchant-id-5"
                    "clientId" : "client-id-5",
                    "merchantAccountId" : "merchant-account-id-5"
                  },
                  "type" : "GOCARDLESS",
                  "processorConfigId" : "processor-config-id-5"
                },
                {
                  "type" : "PAYMENT_CARD",
                  "options" : {
                    "threeDSecureEnabled" : true,
                    "threeDSecureProvider" : "3DS-PROVIDER"
                  }
                }
              ],
              "clientSession" : {
                "order" : {
                  "countryCode" : "GB",
                  "orderId" : "ios_order_id_LklKo2zK",
                  "currencyCode" : "GBP",
                  "totalOrderAmount" : 1010,
                  "lineItems" : [
                    {
                      "amount" : 1010,
                      "quantity" : 1,
                      "itemId" : "shoes-382190",
                      "description" : "Fancy Shoes"
                    }
                  ]
                },
                "clientSessionId" : "09841e8a-b1fa-4528-aed1-173808a4f44d",
                "customer" : {
                  "firstName" : "John",
                  "shippingAddress" : {
                    "firstName" : "John",
                    "lastName" : "Smith",
                    "addressLine1" : "9446 Richmond Road",
                    "countryCode" : "GB",
                    "city" : "London",
                    "postalCode" : "EC53 8BT"
                  },
                  "emailAddress" : "john@primer.io",
                  "customerId" : "ios-customer-G90G37kH",
                  "mobileNumber" : "+4478888888888",
                  "billingAddress" : {
                    "firstName" : "John",
                    "lastName" : "Smith",
                    "addressLine1" : "65 York Road",
                    "countryCode" : "GB",
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
                      "type" : "PAY_NL_IDEAL",
                      "surcharge" : 39
                    },
                    {
                      "type" : "ADYEN_IDEAL",
                      "surcharge" : 69
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
              "primerAccountId" : "PRIMER-ACCOUNT-ID",
              "env" : "SANDBOX",
              "checkoutModules" : [
                {
                  "type" : "TAX_CALCULATION",
                  "requestUrl" : "/sales-tax/calculate"
                },
                {
                  "type" : "BILLING_ADDRESS",
                  "options" : {
                    "lastName" : true,
                    "city" : true,
                    "firstName" : true,
                    "postalCode" : true,
                    "addressLine1" : true,
                    "countryCode" : true,
                    "addressLine2" : true,
                    "state" : true,
                    "phoneNumber" : false
                  }
                }
              ],
              "coreUrl" : "https://api.sandbox.primer.io"
            }
        """
    }
}

let mockPayPalBillingAgreement = Response.Body.PayPal.ConfirmBillingAgreement(billingAgreementId: "agreementId", externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo(externalPayerId: "", email: "", firstName: "", lastName: ""), shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress(firstName: "", lastName: "", addressLine1: "", addressLine2: "", city: "", state: "", countryCode: "", postalCode: ""))

class MockLocator {
    static func registerDependencies() {
        let state: AppStateProtocol = MockAppState()
        state.apiConfiguration = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        // register dependencies
        DependencyContainer.register(mockSettings as PrimerSettingsProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(MockVaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(PrimerTheme() as PrimerThemeProtocol)
    }
}

#endif
